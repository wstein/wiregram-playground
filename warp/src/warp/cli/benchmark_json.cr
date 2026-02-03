require "json"
require "time"

module Warp::CLI
  class BenchmarkJson
    # Structured JSON benchmark result format
    class BenchmarkResult
      include JSON::Serializable

      property timestamp : String
      property system : System
      property warp_version : String
      property benchmarks : Array(BenchResult)

      def initialize(
        @timestamp : String,
        @system : System,
        @warp_version : String,
        @benchmarks : Array(BenchResult),
      )
      end
    end

    class System
      include JSON::Serializable

      property os : String
      property arch : String
      property cpu_cores : Int32

      def initialize(@os : String, @arch : String, @cpu_cores : Int32)
      end
    end

    class BenchResult
      include JSON::Serializable

      property name : String
      property language : String
      property description : String
      property sample_file : String
      property sample_bytes : Int32
      property iterations : Int32
      property results : Array(BackendResult)

      def initialize(
        @name : String,
        @language : String,
        @description : String,
        @sample_file : String,
        @sample_bytes : Int32,
        @iterations : Int32,
        @results : Array(BackendResult),
      )
      end
    end

    class BackendResult
      include JSON::Serializable

      property backend : String
      property available : Bool
      property throughput_mbps : Float64
      property speedup_vs_scalar : Float64?

      def initialize(
        @backend : String,
        @available : Bool,
        @throughput_mbps : Float64,
        @speedup_vs_scalar : Float64?,
      )
      end
    end

    def self.run(args : Array(String)) : Int32
      output_file = "benchmark_results.json"
      language = "all"

      parser = OptionParser.new do |opts|
        opts.on("-o", "--output=FILE", "Output JSON file (default: benchmark_results.json)") { |f| output_file = f }
        opts.on("-l", "--lang=LANG", "Benchmark language: ruby|crystal|all (default: all)") { |l| language = l }
        opts.on("-h", "--help", "Show this help message") do
          puts usage
          exit 0
        end
      end

      parser.parse(args)

      puts "Generating structured JSON benchmarks..."
      puts "Output: #{output_file}"

      system_info = detect_system
      timestamp = Time.utc.to_rfc3339
      benchmarks = [] of BenchResult

      if language == "ruby" || language == "all"
        benchmarks << benchmark_simd_vs_scalar("ruby")
      end

      if language == "crystal" || language == "all"
        benchmarks << benchmark_simd_vs_scalar("crystal")
      end

      result = BenchmarkResult.new(
        timestamp: timestamp,
        system: system_info,
        warp_version: Warp.version_string,
        benchmarks: benchmarks
      )

      # Write JSON to file
      File.write(output_file, result.to_json)
      puts "✓ Benchmark results written to #{output_file}"

      # Also print summary to console
      print_summary(result)

      0
    end

    private def self.benchmark_simd_vs_scalar(language : String) : BenchResult
      sample_file = case language
                    when "ruby"
                      "corpus/ruby/02_strings.rb"
                    when "crystal"
                      "corpus/ruby/02_strings.rb" # Use Ruby corpus for Crystal (similar syntax)
                    else
                      raise "Unknown language: #{language}"
                    end

      unless File.exists?(sample_file)
        STDERR.puts "Warning: Sample file not found: #{sample_file}"
        return BenchResult.new(
          name: "simd_vs_scalar_#{language}",
          language: language,
          description: "Compare SIMD backends vs scalar for #{language} lexing",
          sample_file: sample_file,
          sample_bytes: 0,
          iterations: 0,
          results: [] of BackendResult
        )
      end

      bytes = File.read(sample_file).to_slice
      iterations = 200

      scalar_name = "scalar"
      simd_candidates = ["avx512", "avx2", "avx", "sse2", "neon", "armv6"]

      scalar_result = time_scan(bytes, scalar_name, language, iterations)
      results = [scalar_result]

      simd_candidates.each do |backend_name|
        result = time_scan(bytes, backend_name, language, iterations)
        results << result
      end

      BenchResult.new(
        name: "simd_vs_scalar_#{language}",
        language: language,
        description: "Compare SIMD backends vs scalar for #{language} lexing",
        sample_file: sample_file,
        sample_bytes: bytes.size,
        iterations: iterations,
        results: results
      )
    end

    private def self.time_scan(bytes : Bytes, backend_name : String, language : String, iterations : Int32) : BackendResult
      backend = Warp::Backend.select_by_name(backend_name)

      if !backend
        return BackendResult.new(backend_name, false, 0.0, nil)
      end

      Warp::Backend.reset(backend)

      # Warm up
      5.times do
        case language
        when "ruby"
          Warp::Lang::Ruby::Lexer.scan(bytes)
        when "crystal"
          Warp::Lang::Crystal::Lexer.scan(bytes)
        end
      end

      start_time = Time.instant
      iterations.times do
        case language
        when "ruby"
          Warp::Lang::Ruby::Lexer.scan(bytes)
        when "crystal"
          Warp::Lang::Crystal::Lexer.scan(bytes)
        end
      end
      elapsed = Time.instant - start_time

      throughput_mbps = (bytes.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)

      BackendResult.new(backend_name, true, throughput_mbps, nil)
    end

    private def self.detect_system : System
      os = `uname -s`.chomp
      arch = `uname -m`.chomp
      cpu_cores = `sysctl -n hw.ncpu 2>/dev/null || echo 1`.chomp.to_i

      System.new(os, arch, cpu_cores)
    end

    private def self.print_summary(result : BenchmarkResult) : Void
      puts "\n" + "=" * 60
      puts "BENCHMARK SUMMARY"
      puts "=" * 60
      puts "Timestamp: #{result.timestamp}"
      puts "Warp Version: #{result.warp_version}"
      puts "System: #{result.system.os} #{result.system.arch} (#{result.system.cpu_cores} cores)"
      puts

      result.benchmarks.each do |bench|
        puts "Benchmark: #{bench.name}"
        puts "  Language: #{bench.language}"
        puts "  Sample: #{bench.sample_file} (#{bench.sample_bytes} bytes)"
        puts "  Iterations: #{bench.iterations}"
        puts "  Results:"

        scalar_result = bench.results.find { |r| r.backend == "scalar" }

        bench.results.each do |backend_result|
          throughput_str = backend_result.available ? "#{backend_result.throughput_mbps.round(2)} MB/s" : "N/A"
          if backend_result.backend != "scalar" && scalar_result && backend_result.available && scalar_result.available
            speedup = backend_result.throughput_mbps / scalar_result.throughput_mbps
            speedup_str = " (#{speedup.round(2)}x vs scalar)"
          else
            speedup_str = ""
          end
          status = backend_result.available ? "" : " [unavailable on this platform]"
          puts "    #{backend_result.backend.rjust(12)}: #{throughput_str.rjust(15)}#{speedup_str}#{status}"
        end
        puts
      end

      puts "=" * 60
    end

    def self.usage : String
      <<-TXT
Usage:
  warp bench-json [options]

Options:
  -o, --output=FILE     Output JSON file (default: benchmark_results.json)
  -l, --lang=LANG       Benchmark language: ruby|crystal|all (default: all)
  -h, --help            Show this help message

Examples:
  warp bench-json
  warp bench-json -o results.json -l ruby
  warp bench-json --lang=crystal --output=crystal_bench.json

Output Format:
  JSON file containing:
  - timestamp: ISO 8601 timestamp
  - system: OS, architecture, CPU cores
  - warp_version: Warp version string
  - benchmarks: Array of benchmark results with:
    - name: Benchmark identifier
    - language: Language (ruby/crystal)
    - sample_file: File used for benchmarking
    - sample_bytes: File size in bytes
    - iterations: Number of iterations run
    - results: Array of backend results with throughput and speedup
TXT
    end
  end
end
