require "../src/warp"

module Bench
  struct Result
    getter label : String
    getter iterations : Int32
    getter total_ms : Float64

    def initialize(@label : String, @iterations : Int32, @total_ms : Float64)
    end

    def avg_ms : Float64
      total_ms / iterations
    end
  end

  def self.time(label : String, iterations : Int32, &block : ->) : Result
    start = Time.instant
    iterations.times { yield }
    duration = Time.instant - start
    Result.new(label, iterations, duration.total_milliseconds)
  end

  def self.print_result(result : Result) : Nil
    puts "%-28s avg=%7.2f ms" % {result.label, result.avg_ms}
  end
end

def scan_types(view : Warp::IR::SoAView) : Int32
  count = 0
  view.types.each do |t|
    count += 1 if t == Warp::IR::TapeType::Number
  end
  count
end

def random_lookup(doc : Warp::IR::Document, view : Warp::IR::SoAView, samples : Int32) : Int64
  rng = Random.new(42)
  size = view.types.size
  sum = 0_i64
  samples.times do
    idx = rng.rand(size)
    t = view.types[idx]
    if t == Warp::IR::TapeType::Key || t == Warp::IR::TapeType::String || t == Warp::IR::TapeType::Number
      a = view.a[idx]
      b = view.b[idx]
      sum += b
      _slice = doc.bytes[a, b]
    end
  end
  sum
end

def run_for_file(path : String, iterations : Int32, samples : Int32) : Nil
  bytes = File.read(path).to_slice
  puts "File: #{path} (#{bytes.size} bytes)"

  parser = Warp::Parser.new
  result = parser.parse_document(bytes, validate_literals: true, validate_numbers: true, jsonc: path.downcase.ends_with?(".jsonc"))
  unless result.error.success?
    puts "parse failed: #{result.error}"
    puts
    return
  end
  doc = result.doc.not_nil!

  GC.collect
  before = GC.stats.total_bytes
  view = doc.soa_view
  after = GC.stats.total_bytes
  puts "SoA view bytes (delta): #{after - before}"

  results = [] of Bench::Result
  results << Bench.time("scan types (numbers)", iterations) { scan_types(view) }
  results << Bench.time("build DOM from tape", iterations) { Warp::DOM::Builder.build(doc) }
  results << Bench.time("random lookup/slice", iterations) { random_lookup(doc, view, samples) }

  results.each { |r| Bench.print_result(r) }
  puts
end

iterations = 5
samples = 10_000
args = [] of String
argv = ARGV.dup
while argv.size > 0
  arg = argv.shift
  if arg == "--help" || arg == "-h"
    puts "Usage: crystal run scripts/benchmark_soa.cr --release -O3 -- [--iters N] [--samples N] <json file> [json file...]"
    exit 0
  elsif arg == "--iters"
    value = argv.shift
    iterations = value ? value.to_i : iterations
  elsif arg.starts_with?("--iters=")
    value = arg.split("=", 2)[1]?
    iterations = value ? value.to_i : iterations
  elsif arg == "--samples"
    value = argv.shift
    samples = value ? value.to_i : samples
  elsif arg.starts_with?("--samples=")
    value = arg.split("=", 2)[1]?
    samples = value ? value.to_i : samples
  else
    args << arg
  end
end

if args.empty?
  puts "Usage: crystal run scripts/benchmark_soa.cr --release -O3 -- [--iters N] [--samples N] <json file> [json file...]"
  exit 1
end

args.each { |path| run_for_file(path, iterations, samples) }
