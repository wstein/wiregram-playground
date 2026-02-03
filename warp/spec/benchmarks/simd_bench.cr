require "../spec_helper"
require "benchmark"

# SIMD Performance Benchmarks
#
# Measures SIMD structural scanning throughput for JSON, Ruby, and Crystal.

module SimdBenchmark
  extend self

  JSON_FIXTURE    = "spec/fixtures/cli/sample.json"
  RUBY_FIXTURE    = "spec/fixtures/cli/rb_simple.rb"
  CRYSTAL_FIXTURE = "src/warp.cr"

  def run
    puts "=" * 80
    puts "SIMD Performance Benchmarks"
    puts "Crystal #{Crystal::VERSION}"
    puts "Backend #{Warp::Backend.current.name}"
    puts "=" * 80
    puts

    benches = [] of Tuple(String, Bytes, Proc(Nil))

    if File.exists?(JSON_FIXTURE)
      bytes = File.read(JSON_FIXTURE).to_slice
      benches << {"json/base", bytes, -> { Warp::Lexer.index(bytes) }}
      benches << {"json/enhanced", bytes, -> { Warp::Lexer::EnhancedSimdScan.index(bytes) }}
    end

    if File.exists?(RUBY_FIXTURE)
      bytes = File.read(RUBY_FIXTURE).to_slice
      benches << {"ruby/simd", bytes, -> { Warp::Lang::Ruby.simd_scan(bytes) }}
    end

    if File.exists?(CRYSTAL_FIXTURE)
      bytes = File.read(CRYSTAL_FIXTURE).to_slice
      benches << {"crystal/simd", bytes, -> { Warp::Lang::Crystal.simd_scan(bytes) }}
    end

    benches.each do |name, bytes, job|
      # Warm-up
      5.times { job.call }

      iterations = 200
      elapsed = Benchmark.measure do
        iterations.times { job.call }
      end

      mb = bytes.size / (1024.0 * 1024.0)
      mb_per_s = mb * iterations / elapsed.total
      avg_ms = (elapsed.total * 1000 / iterations).round(3)

      puts sprintf("  %-14s %7d bytes  %7.3f ms/op  %8.2f MB/s", name, bytes.size, avg_ms, mb_per_s)
    end

    puts
    puts "=" * 80
    puts "Benchmark complete"
    puts "=" * 80
  end
end

if PROGRAM_NAME.includes?("simd_bench")
  SimdBenchmark.run
end
