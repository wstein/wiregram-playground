require "../spec_helper"

describe "Scalar-only and trailing scalar cases" do
  it "rejects trailing scalar after a root object" do
    parser = Warp::Parser.new
    result = parser.parse_document(%({} 1).to_slice)
    result.error.should eq(Warp::ErrorCode::TapeError)
  end

  it "rejects multiple root scalars" do
    parser = Warp::Parser.new
    result = parser.parse_document(%(true false).to_slice)
    result.error.should eq(Warp::ErrorCode::TapeError)
  end

  it "rejects malformed scalar sequences" do
    parser = Warp::Parser.new
    parser.parse_document(%(true true false).to_slice).error.should eq(Warp::ErrorCode::TapeError)
    parser.parse_document(%(1 2).to_slice).error.should eq(Warp::ErrorCode::TapeError)
  end

  it "accepts a single scalar root" do
    parser = Warp::Parser.new
    result = parser.parse_document(%(true).to_slice)
    result.error.success?.should be_true
  end

  it "accepts numeric scalar roots" do
    parser = Warp::Parser.new
    parser.parse_document(%(0).to_slice).error.success?.should be_true
    parser.parse_document(%(123).to_slice).error.success?.should be_true
    parser.parse_document(%(-1.5).to_slice).error.success?.should be_true
  end

  it "accepts string scalar roots" do
    parser = Warp::Parser.new
    parser.parse_document(%("hello").to_slice).error.success?.should be_true
    parser.parse_document(%(""quoted"").to_slice).error.success?.should be_true
  end

  it "lexer and TokenAssembler emit tokens for scalar-only inputs" do
    bytes = %(true).to_slice
    stage1 = Warp::Lexer.index(bytes)
    stage1.error.success?.should be_true

    tokens = [] of Warp::Core::Token
    err = Warp::Lexer::TokenAssembler.each_token(bytes, stage1.buffer) do |tok|
      tokens << tok
    end
    err.success?.should be_true

    true_tokens = tokens.select { |t| t.type == Warp::TokenType::True }
    true_tokens.size.should eq(1)
  end
end
