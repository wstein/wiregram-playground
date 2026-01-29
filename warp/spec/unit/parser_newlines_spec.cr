require "../spec_helper"

describe Warp::Parser do
  it "emits newline tokens for LF and CR characters" do
    json = "{\n\"a\":1\r}"
    bytes = json.to_slice
    parser = Warp::Parser.new
    newlines = [] of Warp::Token

    err = parser.each_token(bytes) do |tok|
      newlines << tok if tok.type == Warp::TokenType::Newline
    end

    err.success?.should be_true
    newlines.size.should eq(2)
    newlines[0].length.should eq(1)
    newlines[1].length.should eq(1)
  end

  it "coalesces CRLF into a single newline token" do
    bytes = "{\r\n\"a\":1\r\n}".to_slice
    parser = Warp::Parser.new
    newlines = [] of Warp::Token

    err = parser.each_token(bytes) do |tok|
      newlines << tok if tok.type == Warp::TokenType::Newline
    end

    err.success?.should be_true
    newlines.size.should eq(2)
    newlines[0].length.should eq(2)
    newlines[1].length.should eq(2)
  end
end
