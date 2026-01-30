require "../spec_helper"

describe "Formatter" do
  it "writes simple object from tape" do
    json = %({"a": 1, "b": [true, false]})
    result = Warp::Parser.new.parse_document(json.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    doc = result.doc.not_nil!

    out = Warp::Format.pretty(doc, indent: 2, newline: "\n")
    out.should contain("\"a\"")
    out.should contain("\"b\"")
    out.should contain("true")
  end

  it "handles empty object and array" do
    json = %({"x": {}, "y": []})
    result = Warp::Parser.new.parse_document(json.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    doc = result.doc.not_nil!
    out = Warp::Format.pretty(doc, indent: 2, newline: "\n")
    out.should contain("{}")
    out.should contain("[]")
  end
end
