# Benchmark runner for simdjson parser
#
# Summary
#
# Simple concurrent driver that runs the parser against one or more JSON
# files and reports token counts, timing and throughput.

require "option_parser"
require "../src/simdjson"

struct BenchResult
  getter path : String
  getter count : Int64
  getter size : Int32
  getter seconds : Float64
  getter error : Simdjson::ErrorCode?
  getter message : String?

  def initialize(
    @path : String,
    @count : Int64,
    @size : Int32,
    @seconds : Float64,
    @error : Simdjson::ErrorCode? = nil,
    @message : String? = nil,
  )
  end
end

def bench_file(path : String) : BenchResult
  # Use the Crystal-managed padded Bytes to avoid manual malloc/free and
  # to allow NEON helpers to safely read 16-byte blocks.
  bytes = Simdjson::Stage1.read_file_padded_bytes(path)
  parser = Simdjson::Parser.new

  count = 0_i64
  err = Simdjson::ErrorCode::Success

  start = Time.monotonic
  elapsed = nil
  err = parser.each_token(bytes) do |tok|
    #pp tok
    count += 1
  end
  elapsed = (Time.monotonic - start)

  if err.success? && elapsed
    BenchResult.new(path, count, bytes.size, elapsed.total_seconds)
  else
    BenchResult.new(path, count, bytes.size, elapsed.total_seconds, err)
  end
rescue ex
  BenchResult.new(path, 0_i64, 0, 0.0, Simdjson::ErrorCode::IoError, ex.message)
end

paths = [] of String

original_argv = ARGV.dup
OptionParser.parse(ARGV) do |parser|
  parser.banner = "usage: bin/bench [options] <json file> [json file...]"
  parser.on("-h", "--help", "Show help") do
    puts parser
    exit
  end
  parser.unknown_args do |unknown|
    paths = unknown
  end
end

if paths.empty?
  STDERR.puts "usage: bin/bench [options] <json file> [json file...]"
  exit 1
end

channel = Channel(Tuple(Int32, BenchResult)).new
paths.each_with_index do |path, idx|
  spawn do
    channel.send({idx, bench_file(path)})
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
  puts "file=#{result.path} tokens=#{result.count} size=#{result.size}B time=#{result.seconds.round(4)}s throughput=#{mb_s.round(2)}MB/s"
end

exit 1 if had_error
