# Crystal Corpus Tests
#
# These tests validate that the Crystal lexer can:
# 1. Parse all files in the corpus without errors
# 2. Handle macros, annotations, and complex syntax
# 3. Preserve trivia (comments, whitespace) in CST
# 4. Round-trip through formatter: Crystal -> CST -> Formatter -> Crystal (byte-for-byte)
#
# The Crystal corpus focuses on language features unique to Crystal:
# - Macros with code generation and conditional expansion
# - Annotations for type checking and compiler directives
# - Regex literals with flags (/pattern/flags)
# - Type annotations and method signatures
#
# This spec demonstrates the test pattern for TDD approach to Crystal parsing.

require "../spec_helper"

describe "Crystal Corpus" do
  # List of corpus files to test
  CORPUS_FILES = [
    "corpus/crystal/00_simple.cr",
    "corpus/crystal/01_strings.cr",
    "corpus/crystal/02_regex.cr",
    "corpus/crystal/03_macros.cr",
    "corpus/crystal/04_annotations.cr",
    "corpus/crystal/05_classes.cr",
    "corpus/crystal/06_blocks_procs.cr",
    "corpus/crystal/07_control_flow.cr",
    "corpus/crystal/08_complex.cr",
  ]

  describe "Lexing" do
    it "documents corpus testing strategy" do
      # This test serves as documentation for the corpus-driven testing approach
      # Once Crystal lexer/parser is fully implemented, these tests validate correctness

      # Expected pattern:
      # 1. Read source file from corpus
      source = File.read("corpus/crystal/00_simple.cr")
      source.should_not be_empty

      # 2. Lex to tokens (Crystal lexer exists)
      tokens = Warp::Lang::Crystal::Lexer.scan(source.to_slice)
      tokens.should_not be_empty

      # 3. Parse to CST (once Crystal parser exists)
      # doc = Warp::Lang::Crystal::Parser.parse(source)
      # doc.error.success?.should be_true
      # doc.doc.should_not be_nil

      # 4. Format with preserve mode (once Crystal formatter exists)
      # output = Warp::Lang::Crystal::Formatter.format(doc.doc, mode: :preserve)

      # 5. Validate round-trip
      # output.should eq(source)  # Byte-for-byte equality
    end

    it "lexes all corpus files without error" do
      CORPUS_FILES.each do |file|
        source = File.read(file)
        tokens = Warp::Lang::Crystal::Lexer.scan(source.to_slice)

        # Basic validation: should produce tokens for non-empty files
        if source.size > 0
          tokens.should_not be_empty
        end
      end
    end

    it "handles Crystal-specific syntax in corpus" do
      # Test macro syntax
      macro_source = File.read("corpus/crystal/03_macros.cr")
      macro_tokens = Warp::Lang::Crystal::Lexer.scan(macro_source.to_slice)
      macro_tokens.should_not be_empty

      # Test annotation syntax
      annotation_source = File.read("corpus/crystal/04_annotations.cr")
      annotation_tokens = Warp::Lang::Crystal::Lexer.scan(annotation_source.to_slice)
      annotation_tokens.should_not be_empty

      # Test regex patterns
      regex_source = File.read("corpus/crystal/02_regex.cr")
      regex_tokens = Warp::Lang::Crystal::Lexer.scan(regex_source.to_slice)
      regex_tokens.should_not be_empty
    end
  end

  describe "Performance Characteristics" do
    it "measures lexing throughput on corpus files" do
      # Accumulate throughput metrics
      total_bytes = 0
      total_iterations = 100

      CORPUS_FILES.each do |file|
        source = File.read(file)
        bytes = source.to_slice
        total_bytes += bytes.size

        # Warm up
        5.times { Warp::Lang::Crystal::Lexer.scan(bytes) }

        # This is informational; actual benchmarking should use bench/ tools
        start = Time.instant
        total_iterations.times { Warp::Lang::Crystal::Lexer.scan(bytes) }
        elapsed = Time.instant - start

        throughput_mbps = (bytes.size.to_f * total_iterations) / elapsed.total_seconds / (1024 * 1024)
        puts "#{file}: #{throughput_mbps.round(2)} MB/s"
      end
    end
  end

  describe "Round-Trip Fidelity" do
    it "documents lossless trivia preservation goal" do
      # Round-trip test validates:
      # 1. All tokens are captured (lexer correctness)
      # 2. CST structure is complete (parser correctness)
      # 3. Trivia is preserved (comments, whitespace, macros)
      # 4. Formatting can be reconstructed perfectly

      # This is the ultimate validation of lossless parsing.
      # Crystal has complex trivia including:
      # - Macros with nested code generation
      # - Annotations with complex parameters
      # - String interpolation with arbitrary expressions
      # - Regex patterns with multiple flag variants

      # The parser must preserve ALL of it for round-trip to work.

      # Once implemented, this test template can be parameterized:
      #
      # CORPUS_FILES.each do |file|
      #   source = File.read(file)
      #   doc = Warp::Lang::Crystal::Parser.parse(source)
      #   output = Warp::Lang::Crystal::Formatter.format(doc.doc, mode: :preserve)
      #   output.should eq(source)
      # end
    end
  end
end
