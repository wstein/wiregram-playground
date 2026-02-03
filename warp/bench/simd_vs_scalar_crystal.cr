#!/usr/bin/env crystal

require "../src/warp"

# Compare SIMD backend vs scalar for Crystal lexing on a representative file.

module SimdVsScalarCrystal
  extend self

  SAMPLE_PATH = "src/warp.cr"

  def time_scan(bytes : Bytes, backend_name : String, iterations : Int32) : Tuple(String, Float64)
    backend = Warp::Backend.select_by_name(backend_name)
    unless backend
      puts "Skipping #{backend_name} (not available on this platform)"
      return {backend_name, 0.0}
    end

    Warp::Backend.reset(backend)
    # Warm up
    5.times { Warp::Lang::Crystal::Lexer.scan(bytes) }

    start_time = Time.instant
    iterations.times { Warp::Lang::Crystal::Lexer.scan(bytes) }
    elapsed = Time.instant - start_time

    throughput_mbps = (bytes.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)
    {backend_name, throughput_mbps}
  end

  def run
    unless File.exists?(SAMPLE_PATH)
      puts "Sample file not found: #{SAMPLE_PATH}"
      return
    end

    bytes = File.read(SAMPLE_PATH).to_slice
    iterations = 200

    puts "Crystal SIMD vs Scalar Benchmark"
    puts "File: #{SAMPLE_PATH} (#{bytes.size} bytes)"
    puts "Iterations: #{iterations}"
    puts

    scalar_name = "scalar"
    simd_candidates = ["avx512", "avx2", "avx", "sse2", "neon", "armv6"]

    scalar_result = time_scan(bytes, scalar_name, iterations)
    simd_results = simd_candidates.map { |name| time_scan(bytes, name, iterations) }

    puts "Results (MB/s):"
    puts "  #{scalar_result[0]}: #{scalar_result[1].round(2)}"
    simd_results.each do |name, mbps|
      next if mbps == 0.0
      speedup = scalar_result[1] > 0 ? (mbps / scalar_result[1]) : 0.0
      puts "  #{name}: #{mbps.round(2)} (#{speedup.round(2)}x)"
    end
  end
end

SimdVsScalarCrystal.run
