#!/usr/bin/env crystal

require "../src/warp"
require "time"

module RepeatProfileCSV
  extend self

  RUBY_FILES    = Dir.glob("corpus/ruby/*.rb").sort
  CRYSTAL_FILES = Dir.glob("corpus/crystal/*.cr").sort + ["src/warp.cr"]
  BACKENDS      = ["scalar", "neon", "sse2", "avx2", "avx", "avx512"]

  CSV_PATH = "bench/profile_repeat_results.csv"

  def time_lex_ruby(bytes : Bytes, backend_name : String, iterations : Int32) : Float64
    backend = Warp::Backend.select_by_name(backend_name)
    return 0.0 unless backend

    Warp::Backend.reset(backend)
    5.times { Warp::Lang::Ruby::Lexer.scan(bytes) }

    start_time = Time.instant
    iterations.times { Warp::Lang::Ruby::Lexer.scan(bytes) }
    elapsed = Time.instant - start_time
    (bytes.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)
  end

  def time_lex_crystal(bytes : Bytes, backend_name : String, iterations : Int32) : Float64
    backend = Warp::Backend.select_by_name(backend_name)
    return 0.0 unless backend

    Warp::Backend.reset(backend)
    5.times { Warp::Lang::Crystal::Lexer.scan(bytes) }

    start_time = Time.instant
    iterations.times { Warp::Lang::Crystal::Lexer.scan(bytes) }
    elapsed = Time.instant - start_time
    (bytes.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)
  end

  def time_simd_scan(bytes : Bytes, backend_name : String, iterations : Int32, lang : String) : Float64
    backend = Warp::Backend.select_by_name(backend_name)
    return 0.0 unless backend

    Warp::Backend.reset(backend)

    # warm up
    5.times do
      if lang == "ruby"
        Warp::Lang::Ruby.simd_scan(bytes)
      else
        Warp::Lang::Crystal.simd_scan(bytes)
      end
    end

    start_time = Time.instant
    iterations.times do
      if lang == "ruby"
        Warp::Lang::Ruby.simd_scan(bytes)
      else
        Warp::Lang::Crystal.simd_scan(bytes)
      end
    end
    elapsed = Time.instant - start_time
    (bytes.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)
  end

  def ensure_header
    unless File.exists?(CSV_PATH)
      File.open(CSV_PATH, "w") do |f|
        f.puts "timestamp,repeat,benchmark,language,backend,bytes,iterations,mbps"
      end
    end
  end

  def append_row(row)
    File.open(CSV_PATH, "a") do |f|
      f.puts row
    end
  end

  def run(repeats : Int32 = 5, iterations : Int32 = 200)
    ensure_header

    ruby_blob = Bytes.empty
    RUBY_FILES.each { |f| ruby_blob += File.read(f).to_slice; ruby_blob += "\n".to_slice }
    crystal_blob = Bytes.empty
    CRYSTAL_FILES.each { |f| next unless File.exists?(f); crystal_blob += File.read(f).to_slice; crystal_blob += "\n".to_slice }

    repeats.times do |r|
      ts = Time.local.to_s

      BACKENDS.each do |backend|
        # Ruby lexing
        mbps = time_lex_ruby(ruby_blob, backend, iterations)
        append_row("#{ts},#{r + 1},corpus_lex,ruby,#{backend},#{ruby_blob.size},#{iterations},#{mbps.round(4)}") if mbps > 0.0

        # Crystal lexing
        mbps = time_lex_crystal(crystal_blob, backend, iterations)
        append_row("#{ts},#{r + 1},corpus_lex,crystal,#{backend},#{crystal_blob.size},#{iterations},#{mbps.round(4)}") if mbps > 0.0

        # Ruby simd scanner (structural scan)
        mbps = time_simd_scan(ruby_blob, backend, iterations, "ruby")
        append_row("#{ts},#{r + 1},simd_scan,ruby,#{backend},#{ruby_blob.size},#{iterations},#{mbps.round(4)}") if mbps > 0.0

        # Crystal simd scanner
        mbps = time_simd_scan(crystal_blob, backend, iterations, "crystal")
        append_row("#{ts},#{r + 1},simd_scan,crystal,#{backend},#{crystal_blob.size},#{iterations},#{mbps.round(4)}") if mbps > 0.0
      end

      puts "Completed repeat #{r + 1}/#{repeats}"
    end

    puts "Results written to #{CSV_PATH}"
  end
end

repeats = (ENV["WARP_REPEAT"]? || "5").to_i
iterations = (ENV["WARP_ITERATIONS"]? || "200").to_i
RepeatProfileCSV.run(repeats, iterations)
