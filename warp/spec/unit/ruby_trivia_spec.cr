require "../spec_helper"

describe "Ruby lexer trivia" do
  it "attaches whitespace as leading trivia" do
    bytes = %(require  "x").to_slice
    tokens, err, _pos = Warp::Lang::Ruby::Lexer.scan(bytes)
    err.success?.should be_true

    tokens.none? { |t| t.kind == Warp::Lang::Ruby::TokenKind::Whitespace || t.kind == Warp::Lang::Ruby::TokenKind::CommentLine }.should be_true

    string_tok = tokens.find { |t| t.kind == Warp::Lang::Ruby::TokenKind::String }
    string_tok.should_not be_nil
    string_tok.not_nil!.trivia.size.should be > 0
  end

  it "attaches comments as leading trivia on EOF" do
    bytes = %(require "x" #comment).to_slice
    tokens, err, _pos = Warp::Lang::Ruby::Lexer.scan(bytes)
    err.success?.should be_true

    eof_tok = tokens.last
    eof_tok.kind.should eq(Warp::Lang::Ruby::TokenKind::Eof)
    eof_tok.trivia.any? { |tr| tr.kind == Warp::Lang::Ruby::TriviaKind::CommentLine }.should be_true
  end

  it "attaches whitespace before newline to the newline token" do
    bytes = %(a  \n b).to_slice
    tokens, err, _pos = Warp::Lang::Ruby::Lexer.scan(bytes)
    err.success?.should be_true

    newline_tok = tokens.find { |t| t.kind == Warp::Lang::Ruby::TokenKind::Newline }
    newline_tok.should_not be_nil
    newline_tok.not_nil!.trivia.any? { |tr| tr.kind == Warp::Lang::Ruby::TriviaKind::Whitespace }.should be_true
  end
end
