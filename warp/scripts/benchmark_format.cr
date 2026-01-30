require "../src/warp"

module Bench
  struct Result
    getter label : String
    getter iterations : Int32
    getter total_ms : Float64
    getter bytes : Int64
    getter output_bytes : Int64

    def initialize(@label : String, @iterations : Int32, @total_ms : Float64, @bytes : Int64, @output_bytes : Int64)
    end

    def avg_ms : Float64
      total_ms / iterations
    end

    def throughput_mb_s : Float64
      return 0.0 if total_ms <= 0
      (bytes.to_f / (1024.0 * 1024.0)) / (total_ms / 1000.0)
    end
  end

  def self.time(label : String, iterations : Int32, bytes : Bytes, &block : -> Int32) : Result
    # Reset heap pressure between benchmark variants for fairer comparisons.
    GC.collect
    start = Time.instant
    out_bytes = 0_i64
    iterations.times do
      out_bytes += yield
    end
    duration = Time.instant - start
    Result.new(label, iterations, duration.total_milliseconds, bytes.size.to_i64, out_bytes)
  end

  def self.stress_cpu(seconds : Float64, workers : Int32) : Nil
    return if seconds <= 0 || workers <= 0
    done = Channel(Nil).new
    workers.times do
      spawn do
        start = Time.instant
        while (Time.instant - start).total_seconds < seconds
          # Busy loop to keep cores active before benchmarking.
        end
        done.send(nil)
      end
    end
    workers.times { done.receive }
  end

  def self.print_result(result : Result) : Nil
    puts "%-24s avg=%7.2f ms  throughput=%8.2f MB/s  out=%d bytes" % {
      result.label,
      result.avg_ms,
      result.throughput_mb_s,
      result.output_bytes
    }
  end
end

def run_for_file(path : String, only : Array(String) = [] of String, soa : Bool = false) : Nil
  bytes = File.read(path).to_slice
  puts "File: #{path} (#{bytes.size} bytes)"

  parser = Warp::Parser.new
  jsonc = path.downcase.ends_with?(".jsonc")

  doc_result = (only.empty? || only.includes?("tape")) ? parser.parse_document(bytes, validate_literals: true, validate_numbers: true, jsonc: jsonc) : nil
  dom_result = (only.empty? || only.includes?("dom")) ? parser.parse_dom(bytes, jsonc: jsonc) : nil
  cst_result = (only.empty? || only.includes?("cst")) ? parser.parse_cst(bytes, jsonc: jsonc) : nil
  ast_result = (only.empty? || only.includes?("ast")) ? parser.parse_ast(bytes, jsonc: jsonc) : nil
  doc = doc_result ? doc_result.doc : nil
  dom = dom_result ? dom_result.value : nil
  cst = cst_result ? cst_result.doc : nil
  ast = ast_result ? ast_result.node : nil
  soa_view = nil

  if doc_result && !doc_result.error.success?
    puts "tape skipped: #{doc_result.error}"
  end

  if dom_result && !dom_result.error.success?
    puts "dom skipped: #{dom_result.error}"
  end

  if cst_result && !cst_result.error.success?
    puts "cst skipped: #{cst_result.error}"
  end

  if ast_result && !ast_result.error.success?
    puts "ast skipped: #{ast_result.error}"
  end

  results = [] of Bench::Result

  if only.empty? || only.includes?("tape")
    results << Bench.time("tape+pretty", 5, bytes) do
      result = parser.parse_document(bytes, validate_literals: true, validate_numbers: true, jsonc: jsonc)
      return 0 unless result.error.success?
      Warp::Format.pretty(result.doc.not_nil!).bytesize
    end
  end

  if only.empty? || only.includes?("dom")
    results << Bench.time("dom+pretty", 5, bytes) do
      result = parser.parse_dom(bytes, jsonc: jsonc)
      return 0 unless result.error.success?
      Warp::Format.pretty(result.value.not_nil!).bytesize
    end
  end

  if only.empty? || only.includes?("cst")
    results << Bench.time("cst+pretty", 5, bytes) do
      result = parser.parse_cst(bytes, jsonc: jsonc)
      return 0 unless result.error.success?
      Warp::Format.pretty(result.doc.not_nil!).bytesize
    end
  end

  if only.empty? || only.includes?("ast")
    results << Bench.time("ast+pretty", 5, bytes) do
      result = parser.parse_ast(bytes, jsonc: jsonc)
      return 0 unless result.error.success?
      Warp::Format.pretty(result.node.not_nil!).bytesize
    end
  end

  if soa && doc_result && doc_result.error.success?
    results << Bench.time("soa build", 5, bytes) do
      doc.not_nil!.soa_view
      0
    end
    soa_view = doc.not_nil!.soa_view
    results << Bench.time("soa scan types", 5, bytes) do
      count = 0
      soa_view.not_nil!.types.each do |t|
        count += 1 if t == Warp::IR::TapeType::Number
      end
      count
    end
  end

  if doc_result && doc_result.error.success?
    results << Bench.time("tape pretty only", 5, bytes) do
      Warp::Format.pretty(doc.not_nil!).bytesize
    end
  end

  if dom_result && dom_result.error.success?
    results << Bench.time("dom pretty only", 5, bytes) do
      Warp::Format.pretty(dom.not_nil!).bytesize
    end
  end

  if cst_result && cst_result.error.success?
    results << Bench.time("cst pretty only", 5, bytes) do
      Warp::Format.pretty(cst.not_nil!).bytesize
    end
  end

  if ast_result && ast_result.error.success?
    results << Bench.time("ast pretty only", 5, bytes) do
      Warp::Format.pretty(ast.not_nil!).bytesize
    end
  end

  results.each { |result| Bench.print_result(result) }
  puts
end

only = [] of String
soa = false
stress_seconds = 0.0
stress_workers = 0
args = [] of String
argv = ARGV.dup
while argv.size > 0
  arg = argv.shift
  if arg == "--help" || arg == "-h"
    puts "Usage: crystal run scripts/benchmark_format.cr --release -O3 -- [--only tape|dom|cst|ast] [--soa] [--stress-seconds N] [--stress-workers N] <json file> [json file...]"
    puts "  --only accepts comma-separated values (e.g. --only tape,dom)."
    puts "  --soa adds SoA view build and scan benchmarks (requires tape parse)."
    exit 0
  elsif arg == "--soa"
    soa = true
  elsif arg == "--only"
    list = argv.shift
    only = list ? list.split(',').map(&.strip).reject(&.empty?) : [] of String
  elsif arg.starts_with?("--only=")
    list = arg.split("=", 2)[1]? || ""
    only = list.split(',').map(&.strip).reject(&.empty?)
  elsif arg == "--stress-seconds"
    value = argv.shift
    stress_seconds = value ? value.to_f : 0.0
  elsif arg.starts_with?("--stress-seconds=")
    value = arg.split("=", 2)[1]? || "0"
    stress_seconds = value.to_f
  elsif arg == "--stress-workers"
    value = argv.shift
    stress_workers = value ? value.to_i : 0
  elsif arg.starts_with?("--stress-workers=")
    value = arg.split("=", 2)[1]? || "0"
    stress_workers = value.to_i
  else
    args << arg
  end
end

if args.empty?
  puts "Usage: crystal run scripts/benchmark_format.cr --release -O3 -- [--only tape|dom|cst|ast] [--soa] [--stress-seconds N] [--stress-workers N] <json file> [json file...]"
  exit 1
end

if stress_seconds > 0 && stress_workers > 0
  Bench.stress_cpu(stress_seconds, stress_workers)
end

args.each { |path| run_for_file(path, only, soa) }
