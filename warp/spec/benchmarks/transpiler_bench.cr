require "../spec_helper"
require "benchmark"

# Transpiler Performance Benchmarks
#
# Measures throughput and performance characteristics of the transpiler
# across different file sizes and complexities.

module TranspilerBenchmark
  extend self

  CORPUS_FILES = {
    "small"  => "corpus/ruby/00_simple.rb",
    "medium" => "corpus/ruby/01_methods.rb",
    "large"  => "corpus/ruby/10_complex.rb",
    "xlarge" => "corpus/ruby/11_sorbet_annotations.rb",
  }

  def run
    puts "=" * 80
    puts "Transpiler Performance Benchmarks"
    puts "Crystal #{Crystal::VERSION}"
    puts "=" * 80
    puts

    # Warm-up
    puts "Warming up..."
    CORPUS_FILES.each_value do |path|
      next unless File.exists?(path)
      source = File.read(path).to_slice
      Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(source)
    end
    puts

    # Benchmark Ruby -> Crystal transpilation
    puts "Ruby → Crystal Transpilation"
    puts "-" * 80

    CORPUS_FILES.each do |size, path|
      next unless File.exists?(path)

      source = File.read(path)
      bytes = source.to_slice
      file_size = bytes.size

      result = nil
      elapsed = Benchmark.measure do
        100.times do
          result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(bytes)
        end
      end

      throughput_kb = (file_size * 100 / elapsed.total / 1024).round(2)
      avg_ms = (elapsed.total * 1000 / 100).round(2)

      status = result.try(&.error) == Warp::Core::ErrorCode::Success ? "✓" : "✗"

      puts sprintf("  %-10s %6d bytes  %8.2f ms/op  %10.2f KB/s  %s",
        size, file_size, avg_ms, throughput_kb, status)
    end

    puts

    # Benchmark Crystal -> Ruby transpilation
    puts "Crystal → Ruby Transpilation"
    puts "-" * 80

    cr_fixture = "spec/fixtures/cli/cr_simple.cr"
    if File.exists?(cr_fixture)
      source = File.read(cr_fixture)
      bytes = source.to_slice
      file_size = bytes.size

      result = nil
      elapsed = Benchmark.measure do
        1000.times do
          result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(bytes)
        end
      end

      throughput_kb = (file_size * 1000 / elapsed.total / 1024).round(2)
      avg_ms = (elapsed.total * 1000 / 1000).round(2)

      status = result.try(&.error) == Warp::Core::ErrorCode::Success ? "✓" : "✗"

      puts sprintf("  %-10s %6d bytes  %8.2f ms/op  %10.2f KB/s  %s",
        "fixture", file_size, avg_ms, throughput_kb, status)
    end

    puts

    # Memory allocation benchmark
    puts "Memory Characteristics"
    puts "-" * 80

    large_file = CORPUS_FILES["xlarge"]
    if File.exists?(large_file)
      source = File.read(large_file).to_slice

      # Approximate memory usage (Crystal doesn't have built-in memory profiling)
      # This is a rough estimate based on object allocations
      before_gc = GC.stats.heap_size
      result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(source)
      after_gc = GC.stats.heap_size

      allocated = (after_gc - before_gc) / 1024.0
      ratio = (allocated / (source.size / 1024.0)).round(2)

      puts sprintf("  Large file:  %d KB source → ~%.2f KB allocated (%.2fx)",
        source.size / 1024, allocated, ratio)
    end

    puts
    puts "=" * 80
    puts "Benchmark complete"
    puts "=" * 80
  end
end

# Run if executed directly
if PROGRAM_NAME.includes?("transpiler_bench")
  TranspilerBenchmark.run
end
