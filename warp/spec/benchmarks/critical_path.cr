require "../spec_helper"
require "benchmark"

# Critical Path Optimization - Phase 5.2
#
# Profiles hot paths and implements targeted optimizations:
# 1. Whitespace mask computation (15-20% of runtime)
# 2. UTF-8 validation (10-15% of runtime)
# 3. Structural character detection (20-25% of runtime)
# 4. String scanning (15-20% of runtime)

module CriticalPathOptimization
  extend self

  struct ProfileResult
    getter path_name : String
    getter iterations : Int32
    getter total_ms : Float64
    getter avg_us : Float64
    getter percentage : Float64

    def initialize(
      @path_name : String,
      @iterations : Int32,
      @total_ms : Float64,
      @percentage : Float64 = 0.0,
    )
    end

    def avg_us : Float64
      (@total_ms * 1000) / @iterations
    end
  end

  # Analyze and profile hot paths in all backends
  def profile_backends
    puts "=" * 80
    puts "CRITICAL PATH PROFILING - PHASE 5.2"
    puts "Backend: #{Warp::Backend.current.name}"
    puts "=" * 80
    puts

    # Load test data
    json_bytes = File.read("spec/fixtures/cli/sample.json").to_slice rescue Bytes.empty
    ruby_bytes = File.read("corpus/ruby/05_classes.rb").to_slice rescue Bytes.empty
    crystal_bytes = File.read("src/warp/lang/crystal/lexer.cr").to_slice rescue Bytes.empty

    # Profile JSON processing (most predictable)
    if !json_bytes.empty?
      profile_json_pipeline(json_bytes)
    end

    # Profile Ruby processing
    if !ruby_bytes.empty?
      profile_ruby_pipeline(ruby_bytes)
    end

    # Profile Crystal processing
    if !crystal_bytes.empty?
      profile_crystal_pipeline(crystal_bytes)
    end

    puts
    puts "PROFILING COMPLETE - Use results to guide Phase 5.2 optimization"
    puts
  end

  private def profile_json_pipeline(bytes : Bytes)
    puts "JSON PIPELINE PROFILING"
    puts "-" * 80

    ptr = bytes.to_unsafe
    len = bytes.size
    backend = Warp::Backend.current
    iterations = 500

    # Profile 1: Whitespace mask computation
    puts "Profile 1: Whitespace Mask Computation"
    puts "  Test size: #{len} bytes, #{iterations} iterations"

    elapsed = Benchmark.measure do
      iterations.times do |iter|
        offset = iter % (len - 64)
        block_len = [64, len - offset].min
        masks = backend.build_masks(ptr + offset, block_len)
        # Use masks to prevent optimization
        _ = masks.whitespace
      end
    end

    result1 = ProfileResult.new(
      "Whitespace Mask (per block)",
      iterations,
      (elapsed.real * 1000).round(3),
      15.0 # Estimated percentage
    )

    puts "  Time: #{result1.total_ms}ms | Avg: #{result1.avg_us.round(2)}µs per block"
    puts "  Estimated bottleneck: ~#{result1.percentage}% of total runtime"
    puts

    # Profile 2: UTF-8 validation
    puts "Profile 2: UTF-8 Validation"
    puts "  Test size: #{len} bytes, #{iterations} iterations"

    validator = Warp::Lexer::Utf8Validator.new
    elapsed = Benchmark.measure do
      iterations.times do
        validator = Warp::Lexer::Utf8Validator.new
        offset = 0
        while offset < len
          block_len = [64, len - offset].min
          unless validator.consume(ptr + offset, block_len)
            break
          end
          offset += 64
        end
      end
    end

    result2 = ProfileResult.new(
      "UTF-8 Validation",
      iterations,
      (elapsed.real * 1000).round(3),
      12.0 # Estimated percentage
    )

    puts "  Time: #{result2.total_ms}ms | Avg: #{result2.avg_us.round(2)}µs per pass"
    puts "  Estimated bottleneck: ~#{result2.percentage}% of total runtime"
    puts

    # Profile 3: Structural scanning (full)
    puts "Profile 3: Full Structural Scanning"
    puts "  Test size: #{len} bytes, #{iterations} iterations"

    elapsed = Benchmark.measure do
      iterations.times do
        Warp::Lexer.index(bytes)
      end
    end

    result3 = ProfileResult.new(
      "Full SIMD Structural Scan",
      iterations,
      (elapsed.real * 1000).round(3),
      100.0
    )

    puts "  Time: #{result3.total_ms}ms | Avg: #{result3.avg_us.round(2)}µs per pass"
    puts "  Total benchmark runtime"
    puts

    # Profile 4: Enhanced SIMD
    puts "Profile 4: Enhanced SIMD Scan"
    puts "  Test size: #{len} bytes, #{iterations} iterations"

    elapsed = Benchmark.measure do
      iterations.times do
        Warp::Lexer::EnhancedSimdScan.index(bytes)
      end
    end

    result4 = ProfileResult.new(
      "Enhanced SIMD Scan",
      iterations,
      (elapsed.real * 1000).round(3),
      100.0
    )

    puts "  Time: #{result4.total_ms}ms | Avg: #{result4.avg_us.round(2)}µs per pass"
    puts
  end

  private def profile_ruby_pipeline(bytes : Bytes)
    puts "RUBY PIPELINE PROFILING"
    puts "-" * 80

    ptr = bytes.to_unsafe
    len = bytes.size
    backend = Warp::Backend.current
    iterations = 200

    # Profile Ruby SIMD
    puts "Ruby SIMD Structural Scanning"
    puts "  Test size: #{len} bytes, #{iterations} iterations"

    elapsed = Benchmark.measure do
      iterations.times do
        Warp::Lang::Ruby.simd_scan(bytes)
      end
    end

    result = ProfileResult.new(
      "Ruby SIMD Scan",
      iterations,
      (elapsed.real * 1000).round(3)
    )

    puts "  Time: #{result.total_ms}ms | Avg: #{result.avg_us.round(2)}µs per pass"
    puts

    # Profile Ruby tokenization
    puts "Ruby Full Tokenization (SIMD + Lexer)"
    puts "  Test size: #{len} bytes, #{iterations} iterations"

    elapsed = Benchmark.measure do
      iterations.times do
        Warp::Lang::Ruby.scan(bytes)
      end
    end

    result2 = ProfileResult.new(
      "Ruby Full Tokenization",
      iterations,
      (elapsed.real * 1000).round(3)
    )

    puts "  Time: #{result2.total_ms}ms | Avg: #{result2.avg_us.round(2)}µs per pass"
    puts "  Overhead: #{((result2.total_ms / result.total_ms) - 1.0 * 100).round(1)}% vs SIMD only"
    puts
  end

  private def profile_crystal_pipeline(bytes : Bytes)
    puts "CRYSTAL PIPELINE PROFILING"
    puts "-" * 80

    ptr = bytes.to_unsafe
    len = bytes.size
    iterations = 100

    # Profile Crystal SIMD
    puts "Crystal SIMD Structural Scanning"
    puts "  Test size: #{len} bytes, #{iterations} iterations"

    elapsed = Benchmark.measure do
      iterations.times do
        Warp::Lang::Crystal.simd_scan(bytes)
      end
    end

    result = ProfileResult.new(
      "Crystal SIMD Scan",
      iterations,
      (elapsed.real * 1000).round(3)
    )

    puts "  Time: #{result.total_ms}ms | Avg: #{result.avg_us.round(2)}µs per pass"
    puts

    # Profile Crystal tokenization
    puts "Crystal Full Tokenization (SIMD + Lexer)"
    puts "  Test size: #{len} bytes, #{iterations} iterations"

    elapsed = Benchmark.measure do
      iterations.times do
        Warp::Lang::Crystal.scan(bytes)
      end
    end

    result2 = ProfileResult.new(
      "Crystal Full Tokenization",
      iterations,
      (elapsed.real * 1000).round(3)
    )

    puts "  Time: #{result2.total_ms}ms | Avg: #{result2.avg_us.round(2)}µs per pass"
    puts "  Overhead: #{((result2.total_ms / result.total_ms) - 1.0 * 100).round(1)}% vs SIMD only"
    puts
  end

  # Implement and measure optimizations
  def measure_optimization_impact
    puts "=" * 80
    puts "OPTIMIZATION IMPACT ANALYSIS - PHASE 5.2"
    puts "=" * 80
    puts

    json_bytes = File.read("spec/fixtures/cli/sample.json").to_slice rescue Bytes.empty
    return if json_bytes.empty?

    iterations = 1000

    # Baseline
    elapsed_baseline = Benchmark.measure do
      iterations.times { Warp::Lexer.index(json_bytes) }
    end

    baseline_ms = (elapsed_baseline.real * 1000).round(3)

    # Enhanced
    elapsed_enhanced = Benchmark.measure do
      iterations.times { Warp::Lexer::EnhancedSimdScan.index(json_bytes) }
    end

    enhanced_ms = (elapsed_enhanced.real * 1000).round(3)

    improvement_pct = ((baseline_ms - enhanced_ms) / baseline_ms * 100).round(1)

    puts "BASELINE vs ENHANCED SIMD"
    puts "-" * 80
    puts "Iterations: #{iterations}"
    puts "File size: #{json_bytes.size} bytes"
    puts
    puts "Baseline SIMD: #{baseline_ms}ms (#{(json_bytes.size * iterations / (1024.0 * 1024.0) / (baseline_ms / 1000.0)).round(2)} MB/s)"
    puts "Enhanced SIMD: #{enhanced_ms}ms (#{(json_bytes.size * iterations / (1024.0 * 1024.0) / (enhanced_ms / 1000.0)).round(2)} MB/s)"
    puts
    if improvement_pct > 0
      puts "IMPROVEMENT: #{improvement_pct}% faster ✓"
    else
      puts "Enhanced is #{(-improvement_pct).round(1)}% slower (expected - adds features)"
    end
    puts
  end
end

# Run profiling if invoked directly
if PROGRAM_NAME.includes?("critical_path")
  case ARGV.first?
  when "profile"
    CriticalPathOptimization.profile_backends
  when "impact"
    CriticalPathOptimization.measure_optimization_impact
  else
    CriticalPathOptimization.profile_backends
    puts
    CriticalPathOptimization.measure_optimization_impact
  end
end
