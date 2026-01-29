require "../spec_helper"

describe Warp::Parser do
  it "scans strings with escapes and terminators" do
    json = %({"a":"\\\"x\\\\"})
    bytes = json.to_slice
    parser = Warp::Parser.new
    err = parser.each_token(bytes) { }
    err.success?.should be_true
  end

  it "scans scalars terminated by whitespace" do
    json = %({"a":1 ,"b":2})
    bytes = json.to_slice
    parser = Warp::Parser.new
    err = parser.each_token(bytes) { }
    err.success?.should be_true
  end
end
