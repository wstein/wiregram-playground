require "../spec_helper"

describe "Warp JSONC token scanner" do
  it "tokenizes JSONC fixture with comments and literals" do
    bytes = File.read("spec/fixtures/jsonc_example.jsonc").to_slice
    tokens, error = Warp::Lexer::TokenScanner.scan(bytes, true)
    error.success?.should be_true

    kinds = tokens.map(&.kind)
    kinds.includes?(Warp::CST::TokenKind::CommentLine).should be_true
    kinds.includes?(Warp::CST::TokenKind::CommentBlock).should be_true
    kinds.includes?(Warp::CST::TokenKind::Newline).should be_true
    kinds.includes?(Warp::CST::TokenKind::Whitespace).should be_true
    kinds.includes?(Warp::CST::TokenKind::String).should be_true
    kinds.includes?(Warp::CST::TokenKind::Number).should be_true
    kinds.includes?(Warp::CST::TokenKind::LBrace).should be_true
    kinds.includes?(Warp::CST::TokenKind::RBrace).should be_true
    kinds.includes?(Warp::CST::TokenKind::LBracket).should be_true
    kinds.includes?(Warp::CST::TokenKind::RBracket).should be_true
    kinds.includes?(Warp::CST::TokenKind::Colon).should be_true
    kinds.includes?(Warp::CST::TokenKind::Comma).should be_true
  end

  it "tokenizes JSON literals when JSONC is enabled" do
    bytes = %({"t":true,"f":false,"n":null}).to_slice
    tokens, error = Warp::Lexer::TokenScanner.scan(bytes, true)
    error.success?.should be_true

    kinds = tokens.map(&.kind)
    kinds.includes?(Warp::CST::TokenKind::True).should be_true
    kinds.includes?(Warp::CST::TokenKind::False).should be_true
    kinds.includes?(Warp::CST::TokenKind::Null).should be_true
  end

  it "treats comments as unknown when jsonc is disabled" do
    bytes = %({"a":1 // x\r\n}).to_slice
    tokens, error = Warp::Lexer::TokenScanner.scan(bytes, false)
    error.success?.should be_true
    tokens.any? { |tok| tok.kind == Warp::CST::TokenKind::Unknown }.should be_true
  end

  it "handles CRLF newlines in line comments" do
    bytes = %({"a":1 // x\r\n "b":2}).to_slice
    tokens, error = Warp::Lexer::TokenScanner.scan(bytes, true)
    error.success?.should be_true
    tokens.count { |tok| tok.kind == Warp::CST::TokenKind::Newline }.should be >= 1
  end
end
