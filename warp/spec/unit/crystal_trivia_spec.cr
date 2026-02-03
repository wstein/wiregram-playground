require "../spec_helper"

describe "Crystal lexer trivia" do
  it "attaches whitespace as leading trivia" do
    bytes = %(def  foo; end).to_slice
    tokens, err, _pos = Warp::Lang::Crystal::Lexer.scan(bytes)
    err.success?.should be_true

    tokens.none? { |t| t.kind == Warp::Lang::Crystal::TokenKind::Whitespace || t.kind == Warp::Lang::Crystal::TokenKind::CommentLine }.should be_true

    id_tok = tokens.find { |t| t.kind == Warp::Lang::Crystal::TokenKind::Identifier }
    id_tok.should_not be_nil
    id_tok.not_nil!.leading_trivia.any? { |tr| tr.kind == Warp::Lang::Crystal::TriviaKind::Whitespace }.should be_true
  end

  it "attaches comments as trailing trivia" do
    bytes = %(def foo #comment
end).to_slice
    tokens, err, _pos = Warp::Lang::Crystal::Lexer.scan(bytes)
    err.success?.should be_true

    id_tok = tokens.find { |t| t.kind == Warp::Lang::Crystal::TokenKind::Identifier }
    id_tok.should_not be_nil
    id_tok.not_nil!.trailing_trivia.any? { |tr| tr.kind == Warp::Lang::Crystal::TriviaKind::CommentLine }.should be_true
  end
end
