#!/usr/bin/env crystal

require "../src/warp"

module ScannerMicrobench
  extend self

  RUBY_FILES    = Dir.glob("corpus/ruby/*.rb").sort
  CRYSTAL_FILES = Dir.glob("corpus/crystal/*.cr").sort + ["src/warp.cr"]
  BACKENDS      = ["scalar", "neon", "sse2", "avx2", "avx", "avx512"]

  def build_blob(files : Array(String)) : Bytes
    blob = Bytes.empty
    files.each do |f|
      next unless File.exists?(f)
      blob += File.read(f).to_slice
      blob += "\n".to_slice
    end
    blob
  end

  def time_simd_scan(bytes : Bytes, backend_name : String, iterations : Int32, lang : String) : Float64
    backend = Warp::Backend.select_by_name(backend_name)
    return 0.0 unless backend

    Warp::Backend.reset(backend)
    5.times do
      lang == "ruby" ? Warp::Lang::Ruby.simd_scan(bytes) : Warp::Lang::Crystal.simd_scan(bytes)
    end

    start_time = Time.instant
    iterations.times do
      lang == "ruby" ? Warp::Lang::Ruby.simd_scan(bytes) : Warp::Lang::Crystal.simd_scan(bytes)
    end
    elapsed = Time.instant - start_time
    (bytes.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)
  end

  def run
    ruby_blob = build_blob(RUBY_FILES)
    crystal_blob = build_blob(CRYSTAL_FILES)
    iterations = 500

    puts "Scanner microbench: Ruby simd_scan (#{ruby_blob.size} bytes)"
    BACKENDS.each do |backend|
      mbps = time_simd_scan(ruby_blob, backend, iterations, "ruby")
      next if mbps == 0.0
      puts "  #{backend}: #{mbps.round(2)} MB/s"
    end

    puts

    puts "Scanner microbench: Crystal simd_scan (#{crystal_blob.size} bytes)"
    BACKENDS.each do |backend|
      mbps = time_simd_scan(crystal_blob, backend, iterations, "crystal")
      next if mbps == 0.0
      puts "  #{backend}: #{mbps.round(2)} MB/s"
    end
  end
end

ScannerMicrobench.run
