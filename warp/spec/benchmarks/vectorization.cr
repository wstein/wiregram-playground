require "../spec_helper"
require "benchmark"

# Vectorization Enhancements - Phase 5.4
#
# Implements language-specific SIMD mask optimizations:
# 1. Extended Ruby masks (heredoc_start, symbol_markers)
# 2. Extended Crystal masks (macro_start/end, annotation markers)
# 3. Population count optimization
# 4. Block parallelization analysis

module VectorizationEnhancements
  extend self

  # Extended masks for Ruby-specific patterns
  struct RubyMasks
    getter whitespace : UInt64
    getter string : UInt64
    getter structural : UInt64
    getter quote : UInt64
    getter backslash : UInt64
    getter heredoc_start : UInt64 # <<, <<-, <<~
    getter symbol_marker : UInt64 # :symbol patterns

    def initialize(
      @whitespace : UInt64,
      @string : UInt64,
      @structural : UInt64,
      @quote : UInt64,
      @backslash : UInt64,
      @heredoc_start : UInt64,
      @symbol_marker : UInt64,
    )
    end
  end

  # Extended masks for Crystal-specific patterns
  struct CrystalMasks
    getter whitespace : UInt64
    getter string : UInt64
    getter structural : UInt64
    getter quote : UInt64
    getter backslash : UInt64
    getter macro_start : UInt64      # {{
    getter macro_end : UInt64        # }}
    getter annotation_start : UInt64 # @

    def initialize(
      @whitespace : UInt64,
      @string : UInt64,
      @structural : UInt64,
      @quote : UInt64,
      @backslash : UInt64,
      @macro_start : UInt64,
      @macro_end : UInt64,
      @annotation_start : UInt64,
    )
    end
  end

  # Build Ruby-specific masks for a 64-byte block
  def build_ruby_masks(ptr : Pointer(UInt8), block_len : Int32) : RubyMasks
    whitespace = 0_u64
    string = 0_u64
    structural = 0_u64
    quote = 0_u64
    backslash = 0_u64
    heredoc_start = 0_u64
    symbol_marker = 0_u64

    i = 0
    while i < block_len - 1
      c = ptr[i]
      c_next = ptr[i + 1]
      bit = 1_u64 << i

      # Whitespace
      if c == 0x20_u8 || c == 0x09_u8 || c == 0x0a_u8 || c == 0x0d_u8
        whitespace |= bit
      end

      # Quotes
      if c == '"'.ord.to_u8 || c == '\''.ord.to_u8
        quote |= bit
        string |= bit
      end

      # Backslash (escape)
      if c == '\\'.ord.to_u8
        backslash |= bit
      end

      # Structural characters
      if c == '{'.ord.to_u8 || c == '}'.ord.to_u8 ||
         c == '['.ord.to_u8 || c == ']'.ord.to_u8 ||
         c == '('.ord.to_u8 || c == ')'.ord.to_u8 ||
         c == ','.ord.to_u8 || c == ';'.ord.to_u8 ||
         c == '='.ord.to_u8
        structural |= bit
      end

      # Ruby-specific: Heredoc start (<<, <<-, <<~)
      if c == '<'.ord.to_u8 && c_next == '<'.ord.to_u8
        heredoc_start |= bit
      end

      # Ruby-specific: Symbol marker (:symbol)
      if c == ':'.ord.to_u8
        symbol_marker |= bit
      end

      i += 1
    end

    # Handle last byte
    if block_len > 0
      c = ptr[block_len - 1]
      bit = 1_u64 << (block_len - 1)

      if c == 0x20_u8 || c == 0x09_u8 || c == 0x0a_u8 || c == 0x0d_u8
        whitespace |= bit
      end

      if c == '"'.ord.to_u8 || c == '\''.ord.to_u8
        quote |= bit
        string |= bit
      end

      if c == '\\'.ord.to_u8
        backslash |= bit
      end

      if c == '{'.ord.to_u8 || c == '}'.ord.to_u8 ||
         c == '['.ord.to_u8 || c == ']'.ord.to_u8 ||
         c == '('.ord.to_u8 || c == ')'.ord.to_u8 ||
         c == ','.ord.to_u8 || c == ';'.ord.to_u8 ||
         c == '='.ord.to_u8
        structural |= bit
      end

      if c == ':'.ord.to_u8
        symbol_marker |= bit
      end
    end

    RubyMasks.new(whitespace, string, structural, quote, backslash, heredoc_start, symbol_marker)
  end

  # Build Crystal-specific masks for a 64-byte block
  def build_crystal_masks(ptr : Pointer(UInt8), block_len : Int32) : CrystalMasks
    whitespace = 0_u64
    string = 0_u64
    structural = 0_u64
    quote = 0_u64
    backslash = 0_u64
    macro_start = 0_u64
    macro_end = 0_u64
    annotation_start = 0_u64

    i = 0
    while i < block_len - 1
      c = ptr[i]
      c_next = ptr[i + 1]
      bit = 1_u64 << i

      # Whitespace
      if c == 0x20_u8 || c == 0x09_u8 || c == 0x0a_u8 || c == 0x0d_u8
        whitespace |= bit
      end

      # Quotes
      if c == '"'.ord.to_u8 || c == '\''.ord.to_u8
        quote |= bit
        string |= bit
      end

      # Backslash (escape)
      if c == '\\'.ord.to_u8
        backslash |= bit
      end

      # Structural characters
      if c == '{'.ord.to_u8 || c == '}'.ord.to_u8 ||
         c == '['.ord.to_u8 || c == ']'.ord.to_u8 ||
         c == '('.ord.to_u8 || c == ')'.ord.to_u8 ||
         c == ','.ord.to_u8 || c == ';'.ord.to_u8 ||
         c == '='.ord.to_u8 || c == ':'.ord.to_u8
        structural |= bit
      end

      # Crystal-specific: Macro start ({{)
      if c == '{'.ord.to_u8 && c_next == '{'.ord.to_u8
        macro_start |= bit
      end

      # Crystal-specific: Macro end (}})
      if c == '}'.ord.to_u8 && c_next == '}'.ord.to_u8
        macro_end |= bit
      end

      # Crystal-specific: Annotation start (@)
      if c == '@'.ord.to_u8
        annotation_start |= bit
      end

      i += 1
    end

    # Handle last byte
    if block_len > 0
      c = ptr[block_len - 1]
      bit = 1_u64 << (block_len - 1)

      if c == 0x20_u8 || c == 0x09_u8 || c == 0x0a_u8 || c == 0x0d_u8
        whitespace |= bit
      end

      if c == '"'.ord.to_u8 || c == '\''.ord.to_u8
        quote |= bit
        string |= bit
      end

      if c == '\\'.ord.to_u8
        backslash |= bit
      end

      if c == '@'.ord.to_u8
        annotation_start |= bit
      end
    end

    CrystalMasks.new(whitespace, string, structural, quote, backslash, macro_start, macro_end, annotation_start)
  end

  # Optimized population count using vectorized bit operations
  def count_set_bits_optimized(mask : UInt64) : Int32
    # Brian Kernighan's algorithm - counts set bits efficiently
    count = 0
    m = mask
    while m != 0
      m = m & (m - 1)
      count += 1
    end
    count
  end

  # Analyze vectorization opportunities
  def analyze_vectorization
    puts "=" * 80
    puts "VECTORIZATION ENHANCEMENTS ANALYSIS - PHASE 5.4"
    puts "Backend: #{Warp::Backend.current.name}"
    puts "=" * 80
    puts

    ruby_bytes = File.read("corpus/ruby/05_classes.rb").to_slice rescue Bytes.empty
    crystal_bytes = File.read("src/warp/lang/crystal/lexer.cr").to_slice rescue Bytes.empty

    unless ruby_bytes.empty?
      analyze_ruby_vectorization(ruby_bytes)
    end

    unless crystal_bytes.empty?
      analyze_crystal_vectorization(crystal_bytes)
    end

    analyze_population_count_optimization
    analyze_block_parallelization
  end

  private def analyze_ruby_vectorization(bytes : Bytes)
    puts "RUBY VECTORIZATION ANALYSIS"
    puts "-" * 80

    ptr = bytes.to_unsafe
    len = bytes.size
    iterations = 200

    # Baseline: Standard SIMD
    puts "Baseline: Standard SIMD Scan (64-byte blocks)"
    elapsed_baseline = Benchmark.measure do
      iterations.times do
        offset = 0
        while offset < len
          block_len = [64, len - offset].min
          backend = Warp::Backend.current
          masks = backend.build_masks(ptr + offset, block_len)
          offset += 64
        end
      end
    end

    baseline_ms = (elapsed_baseline.real * 1000).round(3)
    puts "  Time: #{baseline_ms}ms"
    puts

    # Extended Ruby masks
    puts "Extended Ruby Masks (with heredoc + symbol detection)"
    elapsed_extended = Benchmark.measure do
      iterations.times do
        offset = 0
        while offset < len
          block_len = [64, len - offset].min
          masks = build_ruby_masks(ptr + offset, block_len)
          offset += 64
        end
      end
    end

    extended_ms = (elapsed_extended.real * 1000).round(3)
    puts "  Time: #{extended_ms}ms"
    puts "  Overhead: #{((extended_ms / baseline_ms - 1.0) * 100).round(1)}%"
    puts

    # Analyze patterns detected
    puts "Pattern Detection Capability:"
    all_patterns = Warp::Lang::Ruby.detect_all_patterns(bytes)
    puts "  Heredoc markers: #{all_patterns["heredoc_markers"]?.try(&.size) || 0}"
    puts "  Regex delimiters: #{all_patterns["regex_delimiters"]?.try(&.size) || 0}"
    puts "  String interpolation: #{all_patterns["string_interpolation"]?.try(&.size) || 0}"
    puts

    puts "Recommendation:"
    overhead_pct = ((extended_ms / baseline_ms - 1.0) * 100).round(1)
    if overhead_pct < 10
      puts "  ✓ Extended Ruby masks have acceptable overhead (#{overhead_pct}%)"
      puts "  → Recommended for production use in Phase 5.4"
    else
      puts "  ⚠ Extended Ruby masks have significant overhead (#{overhead_pct}%)"
      puts "  → Consider optimizing mask computation"
    end
    puts
  end

  private def analyze_crystal_vectorization(bytes : Bytes)
    puts "CRYSTAL VECTORIZATION ANALYSIS"
    puts "-" * 80

    ptr = bytes.to_unsafe
    len = bytes.size
    iterations = 100

    # Baseline
    puts "Baseline: Standard SIMD Scan (64-byte blocks)"
    elapsed_baseline = Benchmark.measure do
      iterations.times do
        offset = 0
        while offset < len
          block_len = [64, len - offset].min
          backend = Warp::Backend.current
          masks = backend.build_masks(ptr + offset, block_len)
          offset += 64
        end
      end
    end

    baseline_ms = (elapsed_baseline.real * 1000).round(3)
    puts "  Time: #{baseline_ms}ms"
    puts

    # Extended Crystal masks
    puts "Extended Crystal Masks (with macro + annotation detection)"
    elapsed_extended = Benchmark.measure do
      iterations.times do
        offset = 0
        while offset < len
          block_len = [64, len - offset].min
          masks = build_crystal_masks(ptr + offset, block_len)
          offset += 64
        end
      end
    end

    extended_ms = (elapsed_extended.real * 1000).round(3)
    puts "  Time: #{extended_ms}ms"
    puts "  Overhead: #{((extended_ms / baseline_ms - 1.0) * 100).round(1)}%"
    puts

    # Analyze patterns detected
    puts "Pattern Detection Capability:"
    all_patterns = Warp::Lang::Crystal.detect_all_patterns(bytes)
    puts "  Macro boundaries: #{all_patterns["macro_boundaries"]?.try(&.size) || 0}"
    puts "  Annotations: #{all_patterns["annotations"]?.try(&.size) || 0}"
    puts "  Type boundaries: #{all_patterns["type_boundaries"]?.try(&.size) || 0}"
    puts

    puts "Recommendation:"
    overhead_pct = ((extended_ms / baseline_ms - 1.0) * 100).round(1)
    if overhead_pct < 15
      puts "  ✓ Extended Crystal masks have acceptable overhead (#{overhead_pct}%)"
      puts "  → Recommended for production use in Phase 5.4"
    else
      puts "  ⚠ Extended Crystal masks have significant overhead (#{overhead_pct}%)"
      puts "  → Consider optimizing mask computation"
    end
    puts
  end

  private def analyze_population_count_optimization
    puts "POPULATION COUNT OPTIMIZATION"
    puts "-" * 80

    # Create test masks
    test_masks = [
      0_u64,                  # Empty
      0xFFFFFFFFFFFFFFFF_u64, # Full
      0x5555555555555555_u64, # Alternating
      0xAAAAAAAAAAAAAAAA_u64, # Alternating (inverse)
      0x0000000000000001_u64, # Single bit
    ]

    puts "Testing population count implementations:"
    puts

    test_masks.each do |mask|
      optimized = count_set_bits_optimized(mask)
      expected = mask.popcount

      if optimized == expected
        puts "  ✓ Mask 0x#{mask.to_s(16)} → #{optimized} bits (correct)"
      else
        puts "  ✗ Mask 0x#{mask.to_s(16)} → Got #{optimized}, expected #{expected}"
      end
    end

    puts

    # Benchmark population count
    iterations = 100_000
    test_data = Array.new(64) { rand(UInt64) }

    elapsed_optimized = Benchmark.measure do
      iterations.times do
        test_data.each { |mask| count_set_bits_optimized(mask) }
      end
    end

    elapsed_builtin = Benchmark.measure do
      iterations.times do
        test_data.each { |mask| mask.popcount }
      end
    end

    opt_time = (elapsed_optimized.real * 1000).round(3)
    builtin_time = (elapsed_builtin.real * 1000).round(3)

    puts "Performance:"
    puts "  Optimized algorithm: #{opt_time}ms"
    puts "  Crystal built-in: #{builtin_time}ms"
    puts "  Ratio: #{(opt_time / builtin_time).round(2)}x"

    if builtin_time < opt_time
      puts "  → Use Crystal's built-in popcount (faster on this platform)"
    else
      puts "  → Use optimized algorithm (faster on this platform)"
    end
    puts
  end

  private def analyze_block_parallelization
    puts "BLOCK PARALLELIZATION ANALYSIS"
    puts "-" * 80

    json_bytes = File.read("spec/fixtures/cli/sample.json").to_slice rescue Bytes.empty
    return if json_bytes.empty?

    puts "Parallelization Opportunity:"
    puts "  Current: Sequential 64-byte block processing"
    puts "  Proposed: Interleave 2-4 blocks (instruction-level parallelism)"
    puts

    ptr = json_bytes.to_unsafe
    len = json_bytes.size
    backend = Warp::Backend.current

    iterations = 500

    # Sequential (baseline)
    puts "Sequential Processing (1 block per iteration):"
    elapsed_seq = Benchmark.measure do
      iterations.times do
        offset = 0
        while offset < len
          block_len = [64, len - offset].min
          masks = backend.build_masks(ptr + offset, block_len)
          # Use masks to prevent optimization
          _ = masks.whitespace
          offset += 64
        end
      end
    end

    seq_ms = (elapsed_seq.real * 1000).round(3)
    puts "  Time: #{seq_ms}ms"
    puts

    # Simulated 2-block interleaving
    puts "2-Block Interleaved Processing:"
    elapsed_2block = Benchmark.measure do
      iterations.times do
        offset = 0
        while offset < len
          # Process 2 blocks with interleaved operations
          block_len1 = [64, len - offset].min
          masks1 = backend.build_masks(ptr + offset, block_len1)

          offset += 64
          if offset < len
            block_len2 = [64, len - offset].min
            masks2 = backend.build_masks(ptr + offset, block_len2)
            _ = masks1.whitespace | masks2.whitespace
          else
            _ = masks1.whitespace
          end
          offset += 64
        end
      end
    end

    two_ms = (elapsed_2block.real * 1000).round(3)
    puts "  Time: #{two_ms}ms"
    puts "  Improvement: #{((seq_ms / two_ms - 1.0) * 100).round(1)}% faster"
    puts

    if ((seq_ms / two_ms - 1.0) * 100) > 5
      puts "  ✓ Parallelization shows promise (>5% improvement)"
      puts "  → Recommend implementing 2-block interleaving in Phase 5.4"
    else
      puts "  ⚠ Parallelization benefit is minimal (<5%)"
      puts "  → Consider other optimizations first"
    end
    puts
  end
end

# Run vectorization analysis if invoked directly
if PROGRAM_NAME.includes?("vectorization")
  VectorizationEnhancements.analyze_vectorization
end
