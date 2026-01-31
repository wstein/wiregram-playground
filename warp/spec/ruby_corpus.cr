# Ruby Corpus Tests
#
# These tests validate that the Ruby parser can:
# 1. Parse all files in the corpus without errors
# 2. Preserve trivia (comments, whitespace) in CST
# 3. Round-trip through formatter: Ruby -> CST -> Formatter -> Ruby (byte-for-byte)
#
# Rating: Suggestion #5 (Spec-Driven Corpus Setup) 3/5 (Medium)
#
# This spec demonstrates the test pattern for TDD approach to Ruby parsing.
# Once the Ruby lexer and parser are implemented, these tests will validate
# correctness and completeness.

require "../spec_helper"

describe "Ruby Corpus" do
  # List of corpus files to test
  CORPUS_FILES = [
    "corpus/ruby/00_simple.rb",
    "corpus/ruby/01_methods.rb",
    "corpus/ruby/02_strings.rb",
    "corpus/ruby/03_heredocs.rb",
    "corpus/ruby/04_regex.rb",
    "corpus/ruby/05_classes.rb",
    "corpus/ruby/06_blocks_lambdas.rb",
    "corpus/ruby/07_control_flow.rb",
    "corpus/ruby/08_operators.rb",
    "corpus/ruby/09_comments.rb",
    "corpus/ruby/10_complex.rb",
    "corpus/ruby/11_sorbet_annotations.rb",
  ]

  describe "Parsing" do
    # PENDING: Uncomment once Ruby parser is implemented
    # {% for file in CORPUS_FILES %}
    # it "parses {{ file }}" do
    #   source = File.read({{ file }})
    #   doc = Warp::Lang::Ruby::Parser.parse(source)
    #   doc.error.should eq(Warp::Core::ErrorCode::Success)
    #   doc.doc.should_not be_nil
    # end
    # {% end %}

    it "documents corpus testing strategy" do
      # This test serves as documentation for the corpus-driven testing approach
      # Once Ruby parser is implemented, remove the skip and uncomment above tests

      # Expected pattern:
      # 1. Read source file from corpus
      source = File.read("corpus/ruby/00_simple.rb")
      source.should_not be_empty

      # 2. Parse to CST (once Ruby parser exists)
      # doc = Warp::Lang::Ruby::Parser.parse(source)
      # doc.error.success?.should be_true
      # doc.doc.should_not be_nil

      # 3. Format with preserve mode (once Ruby formatter exists)
      # output = Warp::Lang::Ruby::Formatter.format(doc.doc, mode: :preserve)

      # 4. Validate round-trip
      # output.should eq(source)  # Byte-for-byte equality
    end
  end

  describe "Round-Trip Fidelity" do
    it "documents lossless trivia preservation goal" do
      # Round-trip test validates:
      # 1. All tokens are captured (lexer correctness)
      # 2. CST structure is complete (parser correctness)
      # 3. Trivia is preserved (comments, whitespace)
      # 4. Formatting can be reconstructed perfectly

      # This is the ultimate validation of lossless parsing.
      # Ruby has complex trivia (heredocs, string interpolation, etc.)
      # The parser must preserve ALL of it for round-trip to work.

      # Once implemented, this test template can be parameterized:
      #
      # CORPUS_FILES.each do |file|
      #   it "round-trips #{file}" do
      #     source = File.read(file)
      #     doc = Warp::Lang::Ruby::Parser.parse(source)
      #     output = Warp::Lang::Ruby::Formatter.format(doc.doc, mode: :preserve)
      #     output.should eq(source), "Round-trip failed for #{file}"
      #   end
      # end

      true.should be_true
    end
  end

  describe "Edge Cases" do
    it "documents heredoc challenge" do
      # Heredocs are one of the hardest parts of Ruby parsing:
      #
      # def process
      #   text = <<-HEREDOC
      #     Multi-line
      #     indented content
      #   HEREDOC
      # end
      #
      # Challenges:
      # 1. "HEREDOC" is the terminator, not a string delimiter
      # 2. Content can contain any characters (including interpolation)
      # 3. Indentation of the terminator matters
      # 4. Multiple heredocs can appear on same line
      #
      # The lexer must track heredoc state across multiple tokens.
      # This requires lookahead and context, unlike JSON's simple delimiters.

      source = File.read("corpus/ruby/03_heredocs.rb")
      source.should contain("<<-HEREDOC")
    end

    it "documents string interpolation challenge" do
      # String interpolation requires parsing expressions inside #{ }:
      #
      # text = "Value: #{1 + 2}"
      #
      # Challenges:
      # 1. Nested brace matching inside interpolation
      # 2. Nested strings inside interpolation
      # 3. Both single/double quoted strings can interpolate
      # 4. Multiple interpolations in single string
      #
      # The lexer must enter "interpolation mode" when seeing #{ and
      # exit when closing } is matched.

      source = File.read("corpus/ruby/02_strings.rb")
      source.should contain("#{")
    end

    it "documents regex literal challenge" do
      # Regex literals have their own escaping rules:
      #
      # pattern = /\d+/
      # path = %r{/path/to/file}
      #
      # Challenges:
      # 1. Forward slashes as delimiters (can be escaped as \/)
      # 2. Percent-regex with custom delimiters
      # 3. Regex modifiers (i, m, x, etc.) after closing delimiter
      #
      # The lexer must recognize regex vs division operator context.

      source = File.read("corpus/ruby/04_regex.rb")
      source.should contain("%r{")
    end
  end
end
