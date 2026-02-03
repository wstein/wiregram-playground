#!/usr/bin/env crystal

require "../src/warp"

# Micro-benchmarks for SIMD mask generation and per-block scanning.
# Focuses on backend.build_masks throughput and allocation tracking.

module SimdMicrobench
  extend self

  SAMPLE_PATHS = [
    "corpus/ruby/02_strings.rb",
    "src/warp.cr",
  ]

  def time_masks(bytes : Bytes, backend_name : String, iterations : Int32) : Tuple(String, Float64, Int64)
    backend = Warp::Backend.select_by_name(backend_name)
    unless backend
      puts "Skipping #{backend_name} (not available on this platform)"
      return {backend_name, 0.0, 0_i64}
    end

    Warp::Backend.reset(backend)
    ptr = bytes.to_unsafe
    len = bytes.size

    # Warm up
    5.times do
      i = 0
      while i < len
        block_len = len - i
        block_len = 64 if block_len > 64
        backend.build_masks(ptr + i, block_len)
        i += 64
      end
    end

    GC.collect
    before_bytes = GC.stats.total_bytes

    start_time = Time.instant
    iterations.times do
      i = 0
      while i < len
        block_len = len - i
        block_len = 64 if block_len > 64
        backend.build_masks(ptr + i, block_len)
        i += 64
      end
    end
    elapsed = Time.instant - start_time

    after_bytes = GC.stats.total_bytes
    alloc_bytes = (after_bytes - before_bytes).to_i64

    throughput_mbps = (bytes.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)
    {backend_name, throughput_mbps, alloc_bytes}
  end

  def run
    iterations = 5_000
    simd_candidates = ["avx512", "avx2", "avx", "sse2", "neon", "armv6"]

    SAMPLE_PATHS.each do |path|
      unless File.exists?(path)
        puts "Sample file not found: #{path}"
        next
      end

      bytes = File.read(path).to_slice

      puts "SIMD Microbench: build_masks throughput"
      puts "File: #{path} (#{bytes.size} bytes)"
      puts "Iterations: #{iterations}"
      puts

      simd_candidates.each do |name|
        backend_name, mbps, alloc_bytes = time_masks(bytes, name, iterations)
        next if mbps == 0.0
        puts "  #{backend_name}: #{mbps.round(2)} MB/s | Allocated: #{alloc_bytes} bytes"
      end

      puts
    end
  end
end

SimdMicrobench.run
