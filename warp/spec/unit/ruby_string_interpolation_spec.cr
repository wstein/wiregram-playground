require "../spec_helper"

describe "Ruby String Interpolation" do
  describe "String interpolation with interpolation syntax" do
    it "handles basic double-quoted string with interpolation" do
      # This is the failing case from sorbet_parser.cr:292
      source = %q{return "Range(#{inner_type}, #{inner_type})"}
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.size.should be > 0
      tokens.last.kind.should eq(Warp::Lang::Ruby::TokenKind::Eof)

      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Return)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::String)
    end

    it "handles percent-quoted string with escaped interpolation" do
      # This is the failing case from ruby_simd_scanner_spec.cr:90
      source = %q{puts "\#{name}"}
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.size.should be > 0
      tokens.last.kind.should eq(Warp::Lang::Ruby::TokenKind::Eof)

      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Identifier)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::String)
    end

    it "handles regex with bracket class containing escaped characters" do
      # This is the failing case from sorbet_parser.cr:293
      source = %q{when /^T::Enumerator\[/}
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.size.should be > 0
      tokens.last.kind.should eq(Warp::Lang::Ruby::TokenKind::Eof)

      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::When)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Regex)
    end

    it "handles multiple interpolations in same string" do
      source = %q{msg = "Hello #{name}, you are #{age} years old"}
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.last.kind.should eq(Warp::Lang::Ruby::TokenKind::Eof)

      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Identifier)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Equal)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::String)
    end

    it "handles nested braces in string interpolation" do
      source = %q{msg = "Value: #{hash[:key]}"}
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.last.kind.should eq(Warp::Lang::Ruby::TokenKind::Eof)

      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::String)
    end

    it "handles single-quoted string (no interpolation)" do
      source = %q{msg = 'Price: #{price}'}
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.last.kind.should eq(Warp::Lang::Ruby::TokenKind::Eof)

      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::String)
    end
  end

  describe "Percent literals with interpolation" do
    it "handles %Q literal with escaped interpolation" do
      source = %q{puts "\#{name}"}
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.last.kind.should eq(Warp::Lang::Ruby::TokenKind::Eof)

      kinds = tokens.map(&.kind)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::Identifier)
      kinds.should contain(Warp::Lang::Ruby::TokenKind::String)
    end

    it "handles %w word array" do
      source = %q{arr = %w{hello world test}}
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.last.kind.should eq(Warp::Lang::Ruby::TokenKind::Eof)
    end

    it "handles %r regex with escaped brackets" do
      source = %q{pattern = %r{\[test\]}}
      tokens, error = Warp::Lang::Ruby::Lexer.scan(source.to_slice)

      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.last.kind.should eq(Warp::Lang::Ruby::TokenKind::Eof)
    end
  end
end
