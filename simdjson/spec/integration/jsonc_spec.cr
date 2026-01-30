require "../spec_helper"

describe "Warp JSONC CST/AST" do
  it "parses JSONC and preserves comments in CST" do
    bytes = File.read("spec/fixtures/jsonc_example.jsonc").to_slice
    parser = Warp::Parser.new
    result = parser.parse_cst(bytes, jsonc: true)
    result.error.success?.should be_true

    formatted = Warp::Format.pretty(result.doc.not_nil!)
    formatted.includes?("// entry").should be_true
    formatted.includes?("/* block comment").should be_true
  end

  it "builds AST from JSONC and formats without comments" do
    bytes = File.read("spec/fixtures/jsonc_example.jsonc").to_slice
    parser = Warp::Parser.new
    ast_result = parser.parse_ast(bytes, jsonc: true)
    ast_result.error.success?.should be_true

    formatted = Warp::Format.pretty(ast_result.node.not_nil!)
    formatted.includes?("// entry").should be_false
    formatted.includes?("/* block comment").should be_false
  end

  it "parses JSONC into tape and DOM when jsonc is enabled" do
    bytes = File.read("spec/fixtures/jsonc_example.jsonc").to_slice
    parser = Warp::Parser.new

    doc_result = parser.parse_document(bytes, validate_literals: true, validate_numbers: true, jsonc: true)
    doc_result.error.success?.should be_true

    dom_result = parser.parse_dom(bytes, jsonc: true)
    dom_result.error.success?.should be_true
  end
end
