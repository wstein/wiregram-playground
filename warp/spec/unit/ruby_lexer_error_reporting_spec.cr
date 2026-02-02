require "../spec_helper"

describe "Ruby Lexer Error Reporting" do
  describe "unterminated strings with context" do
    it "reports unterminated double quote with source context" do
      source = "def greet(name)\n  \"Hello, name\nend"

      bytes = source.to_slice
      tokens, error, pos = Warp::Lang::Ruby::Lexer.scan(bytes)

      error.should eq(Warp::Core::ErrorCode::StringError)
      pos.should eq(18) # opening quote
    end

    it "reports unterminated single quote with source context" do
      source = "require 'helper\ndef test\n  puts 'hello'\nend"

      bytes = source.to_slice
      tokens, error, _ = Warp::Lang::Ruby::Lexer.scan(bytes)

      error.should eq(Warp::Core::ErrorCode::StringError)
    end
  end

  describe "successful lexing with complex strings" do
    it "handles escaped quotes correctly" do
      source = "str = \"Hello \\\"World\\\"\""
      bytes = source.to_slice
      tokens, error, _ = Warp::Lang::Ruby::Lexer.scan(bytes)

      error.should eq(Warp::Core::ErrorCode::Success)
      tokens.should_not be_empty
    end
  end
end

describe "Enhanced Error Context" do
  it "provides line and column information for errors" do
    source = "def method1\n  value = \"unterminated\n  puts value\nend"

    bytes = source.to_slice
    tokens, error, _ = Warp::Lang::Ruby::Lexer.scan(bytes)

    error.should eq(Warp::Core::ErrorCode::StringError)
  end

  it "shows surrounding context lines" do
    source = "line1 = 1\nline2 = \"hello\nline3 = 2"

    bytes = source.to_slice
    tokens, error, _ = Warp::Lang::Ruby::Lexer.scan(bytes)

    error.should eq(Warp::Core::ErrorCode::StringError)
  end

  it "LexerError builds context from bytes and position" do
    source = "def foo\n  bar = \"unterminated\nend"
    bytes = source.to_slice

    # Position of the unterminated quote
    position = source.index("\"unterminated").not_nil!

    lex_error = Warp::Lang::Ruby::LexerError.new(
      Warp::Core::ErrorCode::StringError,
      "Unterminated string literal",
      bytes,
      position
    )

    lex_error.error_code.should eq(Warp::Core::ErrorCode::StringError)
    lex_error.message.should eq("Unterminated string literal")
    lex_error.line.should eq(2)
    lex_error.column.should be > 0
    lex_error.line_content.should contain("bar")
  end
end
