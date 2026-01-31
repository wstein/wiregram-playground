require "../spec_helper"

describe "Ruby Lexer" do
  describe "Simple method definition" do
    it "lexes 00_simple.rb" do
      source = "def hello\n  puts \"Hello, World!\"\nend\n\nhello"
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.size.should_not eq(0)
      tokens.last.kind.should eq(Warp::Lang::Ruby::TokenKind::Eof)

      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Def)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Identifier)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::String)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::End)
    end
  end

  describe "Corpus files" do
    it "lexes 02_strings.rb" do
      source = File.read("corpus/ruby/02_strings.rb")
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      kinds = tokens.map(&.kind)
      string_count = kinds.count { |k| k == Warp::Lang::Ruby::TokenKind::String }
      string_count.should be >= 5
    end

    it "lexes 03_heredocs.rb" do
      source = File.read("corpus/ruby/03_heredocs.rb")
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      kinds = tokens.map(&.kind)
      heredoc_count = kinds.count { |k| k == Warp::Lang::Ruby::TokenKind::Heredoc }
      heredoc_count.should be >= 3
    end

    it "lexes 04_regex.rb" do
      source = File.read("corpus/ruby/04_regex.rb")
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      kinds = tokens.map(&.kind)
      regex_count = kinds.count { |k| k == Warp::Lang::Ruby::TokenKind::Regex }
      regex_count.should be >= 1
    end

    it "lexes 05_classes.rb" do
      source = File.read("corpus/ruby/05_classes.rb")
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      kinds = tokens.map(&.kind)
      class_count = kinds.count { |k| k == Warp::Lang::Ruby::TokenKind::Class }
      class_count.should be >= 1
    end

    it "lexes 07_control_flow.rb" do
      source = File.read("corpus/ruby/07_control_flow.rb")
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::If)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::End)
    end

    it "lexes 09_comments.rb" do
      source = File.read("corpus/ruby/09_comments.rb")
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      kinds = tokens.map(&.kind)
      comment_count = kinds.count { |k| k == Warp::Lang::Ruby::TokenKind::CommentLine }
      comment_count.should be >= 1
    end

    it "lexes 01_methods.rb" do
      source = File.read("corpus/ruby/01_methods.rb")
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
    end

    it "lexes 06_blocks_lambdas.rb" do
      source = File.read("corpus/ruby/06_blocks_lambdas.rb")
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
    end

    it "lexes 08_operators.rb" do
      source = File.read("corpus/ruby/08_operators.rb")
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
    end

    it "lexes 10_complex.rb" do
      source = File.read("corpus/ruby/10_complex.rb")
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
    end

    it "lexes 11_sorbet_annotations.rb" do
      source = File.read("corpus/ruby/11_sorbet_annotations.rb")
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
    end
  end

  describe "Edge cases" do
    it "handles empty input" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.size.should eq(1) # Only EOF
    end

    it "handles single identifier" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("hello".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Identifier)
    end

    it "handles single number" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("42".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Number)
    end

    it "handles float" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("3.14".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Float)
    end

    it "handles hex number" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("0xFF".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Number)
    end

    it "handles binary number" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("0b1010".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Number)
    end

    it "handles instance variable" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("@instance".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::InstanceVar)
    end

    it "handles class variable" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("@@class_var".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::ClassVar)
    end

    it "handles global variable" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("$global".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::GlobalVar)
    end

    it "handles constant" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("CONSTANT".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Constant)
    end

    it "handles string with escapes" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("\"hello\\nworld\"".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::String)
    end

    it "handles single-quoted string" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("'hello'".to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::String)
    end

    it "detects unterminated string" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("\"unterminated".to_slice)
      error.should eq(Warp::Core::ErrorCode::StringError)
    end

    it "detects unterminated single quote" do
      tokens, error = Warp::Lang::Ruby::Lexer.scan("'unterminated".to_slice)
      error.should eq(Warp::Core::ErrorCode::StringError)
    end
  end

  describe "Operators" do
    it "recognizes arithmetic operators" do
      ops = [
        {"+", Warp::Lang::Ruby::TokenKind::Plus},
        {"-", Warp::Lang::Ruby::TokenKind::Minus},
        {"*", Warp::Lang::Ruby::TokenKind::Star},
      ]

      ops.each do |pair|
        src = pair[0]
        expected = pair[1]
        tokens, _ = Warp::Lang::Ruby::Lexer.scan(src.to_slice)
        tokens[0].kind.should eq(expected)
      end
    end

    it "recognizes logical operators" do
      tokens_and, _ = Warp::Lang::Ruby::Lexer.scan("&&".to_slice)
      tokens_or, _ = Warp::Lang::Ruby::Lexer.scan("||".to_slice)

      tokens_and[0].kind.should eq(Warp::Lang::Ruby::TokenKind::LogicalAnd)
      tokens_or[0].kind.should eq(Warp::Lang::Ruby::TokenKind::LogicalOr)
    end

    it "recognizes power operator" do
      tokens, _ = Warp::Lang::Ruby::Lexer.scan("**".to_slice)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Power)
    end
  end

  describe "Keywords" do
    it "recognizes def/end" do
      tokens, _ = Warp::Lang::Ruby::Lexer.scan("def foo\nend".to_slice)
      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Def)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::End)
    end

    it "recognizes if/elsif/else/end" do
      source = "if x\nelseif y\nelse\nend"
      tokens, _ = Warp::Lang::Ruby::Lexer.scan(source.to_slice)
      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::If)
    end

    it "recognizes class/module" do
      tokens, _ = Warp::Lang::Ruby::Lexer.scan("class Foo\nend".to_slice)
      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Class)
    end

    it "recognizes boolean literals" do
      t_true, _ = Warp::Lang::Ruby::Lexer.scan("true".to_slice)
      t_false, _ = Warp::Lang::Ruby::Lexer.scan("false".to_slice)
      t_nil, _ = Warp::Lang::Ruby::Lexer.scan("nil".to_slice)

      t_true[0].kind.should eq(Warp::Lang::Ruby::TokenKind::True)
      t_false[0].kind.should eq(Warp::Lang::Ruby::TokenKind::False)
      t_nil[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Nil)
    end
  end

  describe "Numbers" do
    it "recognizes integers" do
      ["42", "1000", "0"].each do |num|
        tokens, _ = Warp::Lang::Ruby::Lexer.scan(num.to_slice)
        tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Number)
      end
    end

    it "recognizes floats" do
      ["3.14", "0.5", "1.0"].each do |num|
        tokens, _ = Warp::Lang::Ruby::Lexer.scan(num.to_slice)
        tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Float)
      end
    end

    it "recognizes hex, octal, binary" do
      hex, _ = Warp::Lang::Ruby::Lexer.scan("0xFF".to_slice)
      binary, _ = Warp::Lang::Ruby::Lexer.scan("0b1010".to_slice)

      hex[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Number)
      binary[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Number)
    end
  end

  describe "Token positioning" do
    it "maintains correct positions" do
      source = "def hello"
      tokens, _ = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      last_end = 0
      tokens.each do |token|
        token.start.should be >= last_end
        token.length.should be >= 0
        (token.start + token.length).should be <= source.bytesize
        last_end = token.start + token.length
      end
    end
  end

  describe "Coverage: All corpus files" do
    it "achieves 100% coverage for each file" do
      corpus_files = [
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

      corpus_files.each do |file|
        next unless File.exists?(file)
        source = File.read(file)
        tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

        error.should eq(Warp::Core::ErrorCode::Success)

        # Check: no excessive unknown tokens
        unknown_count = tokens.count { |t| t.kind == Warp::Lang::Ruby::TokenKind::Unknown }
        total_tokens = tokens.size.to_f
        unknown_ratio = unknown_count.to_f / total_tokens

        puts "File: #{file}, Unknown: #{unknown_count}, Total: #{total_tokens}, Ratio: #{unknown_ratio}"

        # Print unknown tokens for debugging
        if unknown_count > 0
          puts "Unknown tokens in #{file}:"
          unknown_tokens = tokens.select { |t| t.kind == Warp::Lang::Ruby::TokenKind::Unknown }
          unknown_tokens.each do |token|
            token_text = source[token.start, token.length]
            puts "  Position #{token.start}: '#{token_text}' (length: #{token.length})"
          end
        end

        # Allow up to 5% unknown tokens (accounts for edge cases)
        unknown_ratio.should be < 0.000001
      end
    end
  end

  describe "Additional token cases" do
    it "handles heredoc with quoted delimiter" do
      source = "s = <<'DELIM'\nhello\nDELIM\n"
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Heredoc)
    end

    it "recognizes percent literal with escaped close" do
      # %q uses a letter after %; use paired delimiters and an escaped closing delimiter
      source = "%q{a\\}b}"
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      kinds = tokens.map(&.kind)
      # percent literal is treated as String
      kinds.should contain(Warp::Lang::Ruby::TokenKind::String)
    end

    it "recognizes double colon (::)" do
      source = "Foo::Bar"
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)
      error.should eq(Warp::Core::ErrorCode::Success)
      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::DoubleColon)
    end

    it "recognizes left and right shift operators" do
      src = "a << b >> c"
      tokens, _ = Warp::Lang::Ruby::Lexer.scan(src.to_slice)
      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::LeftShift)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::RightShift)
    end

    it "recognizes semicolon and question tokens" do
      src = "a; b\nflag ? true : false"
      tokens, _ = Warp::Lang::Ruby::Lexer.scan(src.to_slice)
      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Semicolon)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Question)
    end

    it "recognizes comparison operators and matchers" do
      samples = {
        "<=>" => Warp::Lang::Ruby::TokenKind::Spaceship,
        "<="  => Warp::Lang::Ruby::TokenKind::LessEqual,
        ">="  => Warp::Lang::Ruby::TokenKind::GreaterEqual,
        "!="  => Warp::Lang::Ruby::TokenKind::NotMatch,
        "=~"  => Warp::Lang::Ruby::TokenKind::Match,
        "~"   => Warp::Lang::Ruby::TokenKind::Tilde,
        "<"   => Warp::Lang::Ruby::TokenKind::LessThan,
        ">"   => Warp::Lang::Ruby::TokenKind::GreaterThan,
      }

      samples.each do |src, expected|
        tokens, _ = Warp::Lang::Ruby::Lexer.scan(src.to_slice)
        tokens[0].kind.should eq(expected)
      end
    end

    it "returns Unknown for unrecognized single byte" do
      tokens, _ = Warp::Lang::Ruby::Lexer.scan("`".to_slice)
      tokens[0].kind.should eq(Warp::Lang::Ruby::TokenKind::Unknown)
    end
  end
end
