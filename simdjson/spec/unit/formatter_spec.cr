require "../spec_helper"

describe Warp::Format do
  it "pretty-prints from tape without DOM materialization" do
    json = %({"a":1,"b":["x",true]})
    parser = Warp::Parser.new
    doc_result = parser.parse_document(json.to_slice, validate_literals: true, validate_numbers: true)
    doc_result.error.success?.should be_true

    pretty = Warp::Format.pretty(doc_result.doc.not_nil!, indent: 2)
    pretty.should contain("\"a\": 1")
    pretty.should contain("\"b\": [")
  end
end
