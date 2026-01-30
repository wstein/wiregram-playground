require "../spec_helper"

describe "Warp DOM and Formatter" do
  it "builds a DOM with unescaped strings and typed numbers" do
    json = %({"a":"line\\nbreak","b":[1,2.5,true,null],"c":{"d":"\\u0041"}})
    parser = Warp::Parser.new
    result = parser.parse_dom(json.to_slice)
    result.error.success?.should be_true

    dom = result.value.not_nil!.as(Hash(String, Warp::DOM::Value))
    dom["a"].should eq("line\nbreak")

    array = dom["b"].as(Array(Warp::DOM::Value))
    array[0].should eq(1_i64)
    array[1].should be_a(Float64)
    array[2].should eq(true)
    array[3].should be_nil

    nested = dom["c"].as(Hash(String, Warp::DOM::Value))
    nested["d"].should eq("A")
  end

  it "formats pretty and minified JSON from DOM" do
    json = %({"a":"line\\nbreak","b":[1,2.5,true,null]})
    parser = Warp::Parser.new
    dom_result = parser.parse_dom(json.to_slice)
    dom_result.error.success?.should be_true
    dom = dom_result.value.not_nil!

    minified = Warp::Format.minify(dom)
    minified.should eq("{\"a\":\"line\\nbreak\",\"b\":[1,2.5,true,null]}")

    pretty = Warp::Format.pretty(dom, indent: 2)
    pretty.includes?("\n").should be_true
    pretty.includes?("\"a\": \"line\\nbreak\"").should be_true
  end

  it "decodes Unicode surrogate pairs in strings" do
    json = %({"emoji":"\\uD83D\\uDE00"})
    parser = Warp::Parser.new
    result = parser.parse_dom(json.to_slice)
    result.error.success?.should be_true

    dom = result.value.not_nil!.as(Hash(String, Warp::DOM::Value))
    emoji = dom["emoji"].as(String)
    expected = String.new(Bytes[0xF0, 0x9F, 0x98, 0x80])
    emoji.should eq(expected)
  end

  it "rejects invalid Unicode escape sequences" do
    parser = Warp::Parser.new

    result = parser.parse_dom(%({"bad":"\\uD83D"}).to_slice)
    result.error.should eq(Warp::ErrorCode::StringError)

    result = parser.parse_dom(%({"bad":"\\uDE00"}).to_slice)
    result.error.should eq(Warp::ErrorCode::StringError)

    result = parser.parse_dom(%({"bad":"\\uD83D\\u0041"}).to_slice)
    result.error.should eq(Warp::ErrorCode::StringError)

    result = parser.parse_dom(%({"bad":"\\uZZZZ"}).to_slice)
    result.error.should eq(Warp::ErrorCode::StringError)
  end
end
