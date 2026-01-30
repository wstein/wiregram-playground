require "../spec_helper"

describe Warp::CST do
  it "tokenizes and parses JSONC comments" do
    json = %({ // comment\n "a": 1 /* block */ })
    bytes = json.to_slice

    result = Warp::CST::Parser.parse(bytes, jsonc: true)
    result.error.success?.should be_true
  end

  it "rejects unterminated block comments" do
    json = %({ /* oops })
    bytes = json.to_slice
    tokens, error = Warp::Lexer::TokenScanner.scan(bytes, jsonc: true)
    error.should eq(Warp::ErrorCode::StringError)
    tokens.should_not be_nil
  end
end
