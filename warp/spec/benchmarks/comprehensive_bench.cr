require "../spec_helper"
require "benchmark"
require "json"

# Comprehensive SIMD Performance Benchmarks - Phase 5.1
#
# Measures performance across multiple languages and file sizes.
# Supports JSON, CSV, and table output formats.
# Establishes baseline metrics for optimization tracking.

module ComprehensiveBench
  extend self

  # Test fixtures with multiple sizes
  FIXTURES = {
    json: {
      small:  "spec/fixtures/cli/sample.json",
      medium: "corpus/ruby/05_classes.rb", # JSON-like structure for fallback
      large:  "src/warp.cr",               # Use actual source as large test
    },
    ruby: {
      small:  "corpus/ruby/00_simple.rb",
      medium: "corpus/ruby/05_classes.rb",
      large:  "corpus/ruby/10_complex.rb",
    },
    crystal: {
      small:  "src/warp/lang/crystal/lexer.cr",
      medium: "src/warp.cr",
      large:  "bin/warp.cr",
    },
  }

  struct BenchmarkResult
    getter name : String
    getter language : String
    getter file_size : Int64
    getter iterations : Int32
    getter total_ms : Float64
    getter avg_ms : Float64
    getter throughput_mb_s : Float64
    getter ops_per_sec : Float64

    def initialize(
      @name : String,
      @language : String,
      @file_size : Int64,
      @iterations : Int32,
      @total_ms : Float64,
    )
    end

    def avg_ms : Float64
      @total_ms / @iterations
    end

    def throughput_mb_s : Float64
      mb = @file_size / (1024.0 * 1024.0)
      mb * @iterations / (@total_ms / 1000.0)
    end

    def ops_per_sec : Float64
      @iterations / (@total_ms / 1000.0)
    end
  end

  # Run comprehensive benchmarks
  def run(format : String = "table")
    puts "=" * 80
    puts "COMPREHENSIVE SIMD PERFORMANCE BENCHMARKS - PHASE 5.1"
    puts "Crystal #{Crystal::VERSION} | Backend: #{Warp::Backend.current.name}"
    puts "=" * 80
    puts

    results = [] of BenchmarkResult

    # Benchmark JSON
    results.concat(benchmark_json)

    # Benchmark Ruby
    results.concat(benchmark_ruby)

    # Benchmark Crystal
    results.concat(benchmark_crystal)

    # Output results
    case format.downcase
    when "json"
      output_json(results)
    when "csv"
      output_csv(results)
    else
      output_table(results)
    end

    results
  end

  private def benchmark_json : Array(BenchmarkResult)
    results = [] of BenchmarkResult

    FIXTURES[:json].each do |size_name, file_path|
      next unless File.exists?(file_path)

      bytes = File.read(file_path).to_slice
      name = "JSON #{size_name.to_s.capitalize}"

      # Warm up
      5.times { Warp::Lexer.index(bytes) }

      # Standard SIMD
      elapsed = Benchmark.measure do
        100.times { Warp::Lexer.index(bytes) }
      end

      results << BenchmarkResult.new(
        name,
        "json",
        bytes.size.to_i64,
        100,
        (elapsed.real * 1000).round(3)
      )

      # Enhanced SIMD
      elapsed = Benchmark.measure do
        100.times { Warp::Lexer::EnhancedSimdScan.index(bytes) }
      end

      results << BenchmarkResult.new(
        "#{name} (Enhanced)",
        "json",
        bytes.size.to_i64,
        100,
        (elapsed.real * 1000).round(3)
      )
    end

    results
  end

  private def benchmark_ruby : Array(BenchmarkResult)
    results = [] of BenchmarkResult

    FIXTURES[:ruby].each do |size_name, file_path|
      next unless File.exists?(file_path)

      bytes = File.read(file_path).to_slice
      name = "Ruby #{size_name.to_s.capitalize}"

      # Warm up
      5.times { Warp::Lang::Ruby.simd_scan(bytes) }

      # SIMD Scan
      elapsed = Benchmark.measure do
        100.times { Warp::Lang::Ruby.simd_scan(bytes) }
      end

      results << BenchmarkResult.new(
        name,
        "ruby",
        bytes.size.to_i64,
        100,
        (elapsed.real * 1000).round(3)
      )

      # Tokenization (full lexer)
      elapsed = Benchmark.measure do
        50.times { Warp::Lang::Ruby.scan(bytes) }
      end

      results << BenchmarkResult.new(
        "#{name} (Tokens)",
        "ruby",
        bytes.size.to_i64,
        50,
        (elapsed.real * 1000).round(3)
      )
    end

    results
  end

  private def benchmark_crystal : Array(BenchmarkResult)
    results = [] of BenchmarkResult

    FIXTURES[:crystal].each do |size_name, file_path|
      next unless File.exists?(file_path)

      bytes = File.read(file_path).to_slice
      name = "Crystal #{size_name.to_s.capitalize}"

      # Warm up
      5.times { Warp::Lang::Crystal.simd_scan(bytes) }

      # SIMD Scan
      elapsed = Benchmark.measure do
        100.times { Warp::Lang::Crystal.simd_scan(bytes) }
      end

      results << BenchmarkResult.new(
        name,
        "crystal",
        bytes.size.to_i64,
        100,
        (elapsed.real * 1000).round(3)
      )

      # Tokenization (full lexer)
      elapsed = Benchmark.measure do
        50.times { Warp::Lang::Crystal.scan(bytes) }
      end

      results << BenchmarkResult.new(
        "#{name} (Tokens)",
        "crystal",
        bytes.size.to_i64,
        50,
        (elapsed.real * 1000).round(3)
      )
    end

    results
  end

  private def output_table(results : Array(BenchmarkResult))
    puts "RESULTS: Table Format"
    puts "-" * 100
    puts sprintf("%-25s | %-8s | %10s | %8s | %10s | %12s",
      "Test Name", "Language", "File Size", "Iter", "Avg (ms)", "Throughput")
    puts "-" * 100

    results.each do |result|
      size_str = if result.file_size < 1024
                   "#{result.file_size}B"
                 elsif result.file_size < 1024 * 1024
                   sprintf("%.1f KB", result.file_size / 1024.0)
                 else
                   sprintf("%.1f MB", result.file_size / (1024.0 * 1024.0))
                 end

      puts sprintf("%-25s | %-8s | %10s | %8d | %10.3f | %10.2f MB/s",
        result.name[0...24],
        result.language,
        size_str,
        result.iterations,
        result.avg_ms,
        result.throughput_mb_s
      )
    end

    puts "-" * 100
    puts

    # Summary statistics
    puts "SUMMARY STATISTICS"
    puts "-" * 100

    summary_by_language = results.group_by(&.language)
    summary_by_language.each do |lang, lang_results|
      avg_throughput = lang_results.map(&.throughput_mb_s).sum / lang_results.size
      avg_latency = lang_results.map(&.avg_ms).sum / lang_results.size
      min_latency = lang_results.map(&.avg_ms).min
      max_latency = lang_results.map(&.avg_ms).max

      puts sprintf("%-10s | Avg Throughput: %8.2f MB/s | Avg Latency: %7.3f ms | Min: %7.3f ms | Max: %7.3f ms",
        lang.upcase,
        avg_throughput,
        avg_latency,
        min_latency,
        max_latency
      )
    end

    puts "-" * 100
    puts
  end

  private def output_json(results : Array(BenchmarkResult))
    json_results = results.map do |r|
      {
        test:            r.name,
        language:        r.language,
        file_size_bytes: r.file_size,
        iterations:      r.iterations,
        total_ms:        r.total_ms,
        avg_ms:          r.avg_ms.round(3),
        throughput_mb_s: r.throughput_mb_s.round(2),
        ops_per_sec:     r.ops_per_sec.round(0),
      }
    end

    json_output = {
      timestamp:       Time.utc.to_s,
      backend:         Warp::Backend.current.name,
      crystal_version: Crystal::VERSION,
      results:         json_results,
    }

    puts JSON.pretty_generate(json_output)
  end

  private def output_csv(results : Array(BenchmarkResult))
    puts "test_name,language,file_size_bytes,iterations,total_ms,avg_ms,throughput_mb_s,ops_per_sec"

    results.each do |r|
      puts "#{r.name},#{r.language},#{r.file_size},#{r.iterations},#{r.total_ms},#{r.avg_ms.round(3)},#{r.throughput_mb_s.round(2)},#{r.ops_per_sec.round(0)}"
    end
  end
end

# Run benchmarks if invoked directly
if PROGRAM_NAME.includes?("comprehensive_bench")
  format = ARGV.first? || "table"
  ComprehensiveBench.run(format)
end
