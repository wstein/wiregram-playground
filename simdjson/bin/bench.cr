# Benchmark runner for simdjson parser
#
# Summary
#
# Simple concurrent driver that runs the parser against one or more JSON
# files and reports token counts, timing and throughput. Supports a
# `--profile` mode that reports Stage1/Stage2 times.

require "option_parser"
require "../src/simdjson"

struct BenchResult
  getter path : String
  getter count : Int64
  getter size : Int32
  getter seconds : Float64
  getter stage1_ms : Float64
  getter stage2_ms : Float64
  getter error : Simdjson::ErrorCode?
  getter message : String?

  def initialize(
    @path : String,
    @count : Int64,
    @size : Int32,
    @seconds : Float64,
    @stage1_ms : Float64,
    @stage2_ms : Float64,
    @error : Simdjson::ErrorCode? = nil,
    @message : String? = nil
  )
  end
end

def bench_file(path : String, profile : Bool) : BenchResult
  bytes = File.read(path).to_slice
  parser = Simdjson::Parser.new

  start = Time.instant
  count = 0_i64
  stage1_start = start
  stage1_end = start
  stage2_start = start
  stage2_end = start
  err = Simdjson::ErrorCode::Success

  if profile
    stage1_start = Time.instant
    err = parser.each_token(bytes) do |_tok|
      count += 1
    end
    stage1_end = Time.instant
    if err.success?
      stage2_start = Time.instant
      doc_result = parser.parse_document(bytes, false, false, false)
      stage2_end = Time.instant
      err = doc_result.error
    end
  else
    err = parser.each_token(bytes) do |_tok|
      count += 1
    end
    stage1_end = Time.instant
    stage2_end = stage1_end
    stage2_start = stage1_end
  end
  elapsed = Time.instant - start

  if err.success?
    s1 = (stage1_end - stage1_start).total_milliseconds
    s2 = (stage2_end - stage2_start).total_milliseconds
    s2_only = profile ? (s2 - s1) : 0.0
    s2_only = 0.0 if s2_only < 0
    BenchResult.new(path, count, bytes.size, elapsed.total_seconds, s1, s2_only)
  else
    BenchResult.new(path, count, bytes.size, elapsed.total_seconds, (stage1_end - stage1_start).total_milliseconds, (stage2_end - stage2_start).total_milliseconds, err)
  end
rescue ex
  BenchResult.new(path, 0_i64, 0, 0.0, 0.0, 0.0, Simdjson::ErrorCode::IoError, ex.message)
end

release_flag = false
profile = false
paths = [] of String

original_argv = ARGV.dup
OptionParser.parse(ARGV) do |parser|
  parser.banner = "usage: bin/bench [options] <json file> [json file...]"
  parser.on("--release", "Re-run with crystal --release") { release_flag = true }
  parser.on("--profile", "Report stage1/stage2 timing") { profile = true }
  parser.on("-h", "--help", "Show help") do
    puts parser
    exit
  end
  parser.unknown_args do |unknown|
    paths = unknown
  end
end

if release_flag && ENV["SIMDJSON_BENCH_RELEASE"]?.nil?
  args = ["run", "--release", __FILE__, "--"] + original_argv.reject { |arg| arg == "--release" }
  Process.exec("crystal", args, env: {"SIMDJSON_BENCH_RELEASE" => "1"})
end

if paths.empty?
  STDERR.puts "usage: bin/bench [options] <json file> [json file...]"
  exit 1
end

channel = Channel(Tuple(Int32, BenchResult)).new
paths.each_with_index do |path, idx|
  spawn do
    channel.send({idx, bench_file(path, profile)})
  end
end

ordered = Array(BenchResult?).new(paths.size, nil)
paths.size.times do
  idx, result = channel.receive
  ordered[idx] = result
end
results = ordered.compact

had_error = false
results.each do |result|
  if error = result.error
    msg = result.message || error.to_s
    STDERR.puts "error: #{result.path} #{msg}"
    had_error = true
    next
  end

  mb = result.size.to_f / 1_000_000.0
  mb_s = result.seconds > 0 ? (mb / result.seconds) : 0.0
  if profile
    puts "file=#{result.path} tokens=#{result.count} size=#{result.size}B time=#{result.seconds.round(4)}s stage1=#{result.stage1_ms.round(3)}ms stage2=#{result.stage2_ms.round(3)}ms throughput=#{mb_s.round(2)}MB/s"
  else
    puts "file=#{result.path} tokens=#{result.count} size=#{result.size}B time=#{result.seconds.round(4)}s throughput=#{mb_s.round(2)}MB/s"
  end
end

exit 1 if had_error
