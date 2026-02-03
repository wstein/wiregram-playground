require "../spec_helper"

describe "Ruby lexer trivia" do
  it "attaches whitespace as leading trivia" do
    bytes = %(require  "x").to_slice
    tokens, err, _pos = Warp::Lang::Ruby::Lexer.scan(bytes)
    err.success?.should be_true

    tokens.none? { |t| t.kind == Warp::Lang::Ruby::TokenKind::Whitespace || t.kind == Warp::Lang::Ruby::TokenKind::CommentLine }.should be_true

    string_tok = tokens.find { |t| t.kind == Warp::Lang::Ruby::TokenKind::String }
    string_tok.should_not be_nil
    string_tok.not_nil!.leading_trivia.size.should be > 0
  end

  it "attaches comments as trailing trivia" do
    bytes = %(require "x" #comment).to_slice
    tokens, err, _pos = Warp::Lang::Ruby::Lexer.scan(bytes)
    err.success?.should be_true

    string_tok = tokens.find { |t| t.kind == Warp::Lang::Ruby::TokenKind::String }
    string_tok.should_not be_nil
    string_tok.not_nil!.trailing_trivia.any? { |tr| tr.kind == Warp::Lang::Ruby::TriviaKind::CommentLine }.should be_true
  end

  it "attaches whitespace before newline as trailing trivia" do
    bytes = %(a  \n b).to_slice
    tokens, err, _pos = Warp::Lang::Ruby::Lexer.scan(bytes)
    err.success?.should be_true

    first_id = tokens.find { |t| t.kind == Warp::Lang::Ruby::TokenKind::Identifier }
    first_id.should_not be_nil
    first_id.not_nil!.trailing_trivia.any? { |tr| tr.kind == Warp::Lang::Ruby::TriviaKind::Whitespace }.should be_true
  end
end
