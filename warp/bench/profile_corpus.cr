#!/usr/bin/env crystal

require "../src/warp"

module ProfileCorpus
  extend self

  RUBY_FILES    = Dir.glob("corpus/ruby/*.rb").sort
  CRYSTAL_FILES = Dir.glob("corpus/crystal/*.cr").sort + ["src/warp.cr"]

  def time_scan_ruby(bytes : Bytes, backend_name : String, iterations : Int32) : Tuple(String, Float64)
    backend = Warp::Backend.select_by_name(backend_name)
    unless backend
      puts "Skipping #{backend_name} (not available on this platform)"
      return {backend_name, 0.0}
    end

    Warp::Backend.reset(backend)
    # warm up
    10.times { Warp::Lang::Ruby::Lexer.scan(bytes) }

    start_time = Time.instant
    iterations.times { Warp::Lang::Ruby::Lexer.scan(bytes) }
    elapsed = Time.instant - start_time

    throughput_mbps = (bytes.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)
    {backend_name, throughput_mbps}
  end

  def time_scan_crystal(bytes : Bytes, backend_name : String, iterations : Int32) : Tuple(String, Float64)
    backend = Warp::Backend.select_by_name(backend_name)
    unless backend
      puts "Skipping #{backend_name} (not available on this platform)"
      return {backend_name, 0.0}
    end

    Warp::Backend.reset(backend)
    10.times { Warp::Lang::Crystal::Lexer.scan(bytes) }

    start_time = Time.instant
    iterations.times { Warp::Lang::Crystal::Lexer.scan(bytes) }
    elapsed = Time.instant - start_time

    throughput_mbps = (bytes.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)
    {backend_name, throughput_mbps}
  end

  def run
    # Build large Ruby corpus blob
    ruby_blob = Bytes.empty
    RUBY_FILES.each do |f|
      ruby_blob += File.read(f).to_slice
      ruby_blob += "\n".to_slice
    end

    # Build large Crystal corpus blob
    crystal_blob = Bytes.empty
    CRYSTAL_FILES.each do |f|
      next unless File.exists?(f)
      crystal_blob += File.read(f).to_slice
      crystal_blob += "\n".to_slice
    end

    iterations = 500
    simd_candidates = ["neon", "sse2", "avx2", "avx", "avx512"]

    puts "Profile: Ruby corpus (#{RUBY_FILES.size} files, #{ruby_blob.size} bytes)"
    puts "Iterations: #{iterations}"
    scalar = time_scan_ruby(ruby_blob, "scalar", iterations)
    puts "  scalar: #{scalar[1].round(2)} MB/s"
    simd_candidates.each do |name|
      backend_name, mbps = time_scan_ruby(ruby_blob, name, iterations)
      next if mbps == 0.0
      speedup = scalar[1] > 0 ? (mbps / scalar[1]) : 0.0
      puts "  #{backend_name}: #{mbps.round(2)} MB/s (#{speedup.round(2)}x)"
    end

    puts

    puts "Profile: Crystal corpus (#{CRYSTAL_FILES.size} files, #{crystal_blob.size} bytes)"
    puts "Iterations: #{iterations}"
    scalar = time_scan_crystal(crystal_blob, "scalar", iterations)
    puts "  scalar: #{scalar[1].round(2)} MB/s"
    simd_candidates.each do |name|
      backend_name, mbps = time_scan_crystal(crystal_blob, name, iterations)
      next if mbps == 0.0
      speedup = scalar[1] > 0 ? (mbps / scalar[1]) : 0.0
      puts "  #{backend_name}: #{mbps.round(2)} MB/s (#{speedup.round(2)}x)"
    end
  end
end

ProfileCorpus.run
