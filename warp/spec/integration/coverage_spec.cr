require "../spec_helper"

describe "Warp integration coverage" do
  it "parses CST literals and empty containers" do
    bytes = %({"n":null,"t":true,"f":false,"num":1,"arr":[],"obj":{}}).to_slice
    result = Warp::Parser.new.parse_cst(bytes)
    result.error.success?.should be_true
  end

  it "parses CST arrays with literals" do
    bytes = %([1,true,false,null]).to_slice
    result = Warp::Parser.new.parse_cst(bytes)
    result.error.success?.should be_true
  end

  it "parses CST nested arrays and empty containers" do
    bytes = %([[],[1]]).to_slice
    result = Warp::Parser.new.parse_cst(bytes)
    result.error.success?.should be_true
  end

  it "formats empty CST containers" do
    parser = Warp::Parser.new
    obj = parser.parse_cst(%({}).to_slice)
    obj.error.success?.should be_true
    Warp::Format.pretty(obj.doc.not_nil!).includes?("{}").should be_true

    arr = parser.parse_cst(%([]).to_slice)
    arr.error.success?.should be_true
    Warp::Format.pretty(arr.doc.not_nil!).includes?("[]").should be_true
  end

  it "parses JSONC null literals into tape" do
    bytes = %({"n":null}).to_slice
    result = Warp::Parser.new.parse_document(bytes, validate_literals: true, validate_numbers: true, jsonc: true)
    result.error.success?.should be_true
  end

  it "unescapes DOM strings with all JSON escapes" do
    bytes = %({"s":"\\\"\\\\\\/\\b\\f\\n\\r\\t"}).to_slice
    result = Warp::Parser.new.parse_dom(bytes)
    result.error.success?.should be_true
  end

  it "returns TapeError when DOM builder gets an empty tape" do
    doc = Warp::IR::Document.new(Bytes.empty, [] of Warp::IR::Entry)
    result = Warp::DOM::Builder.build(doc)
    result.error.should eq(Warp::ErrorCode::TapeError)
  end

  it "formats empty containers and escaped strings across representations" do
    bytes = %({"a":"","b":false,"c":{},"d":[]}).to_slice
    parser = Warp::Parser.new

    doc_result = parser.parse_document(bytes, validate_literals: true, validate_numbers: true)
    doc_result.error.success?.should be_true
    tape_formatted = Warp::Format.pretty(doc_result.doc.not_nil!)
    tape_formatted.includes?("{}").should be_true
    tape_formatted.includes?("[]").should be_true

    dom_result = parser.parse_dom(bytes)
    dom_result.error.success?.should be_true
    Warp::Format.pretty(dom_result.value.not_nil!).includes?("{}").should be_true

    ast_result = parser.parse_ast(bytes)
    ast_result.error.success?.should be_true
    Warp::Format.pretty(ast_result.node.not_nil!).includes?("{}").should be_true

    empty_obj = Warp::Format.pretty({} of String => Warp::DOM::Value)
    empty_obj.includes?("{}").should be_true
    empty_arr = Warp::Format.pretty([] of Warp::DOM::Value)
    empty_arr.includes?("[]").should be_true
  end

  it "formats AST null nodes" do
    bytes = %(null).to_slice
    ast_result = Warp::Parser.new.parse_ast(bytes)
    ast_result.error.success?.should be_true
    Warp::Format.pretty(ast_result.node.not_nil!).includes?("null").should be_true
  end

  it "escapes long strings via the SIMD escape scan path" do
    long = "a" * 40 + "\\\""
    formatted = Warp::Format.pretty(long)
    formatted.includes?("\\\\").should be_true
    formatted.includes?("\\\"").should be_true
  end

  it "escapes control characters in formatted strings" do
    value = "a\b\f\r\t"
    formatted = Warp::Format.pretty(value)
    formatted.includes?("\\b").should be_true
    formatted.includes?("\\f").should be_true
    formatted.includes?("\\r").should be_true
    formatted.includes?("\\t").should be_true
  end

  it "formats long strings without escapes via the SIMD scan loop" do
    long = "a" * 130
    formatted = Warp::Format.pretty(long)
    formatted.includes?(long).should be_true
  end

  it "formats tape arrays and objects with non-empty payloads" do
    bytes = %({"a":1,"b":[true,false]}).to_slice
    doc_result = Warp::Parser.new.parse_document(bytes, validate_literals: true, validate_numbers: true)
    doc_result.error.success?.should be_true
    formatted = Warp::Format.pretty(doc_result.doc.not_nil!)
    formatted.includes?("\"a\"").should be_true
    formatted.includes?("[\n").should be_true
  end

  it "formats tape empty object and array from root" do
    obj_doc = Warp::Parser.new.parse_document(%({}).to_slice, validate_literals: true, validate_numbers: true)
    obj_doc.error.success?.should be_true
    Warp::Format.pretty(obj_doc.doc.not_nil!).should eq("{}")

    arr_doc = Warp::Parser.new.parse_document(%([]).to_slice, validate_literals: true, validate_numbers: true)
    arr_doc.error.success?.should be_true
    Warp::Format.pretty(arr_doc.doc.not_nil!).should eq("[]")
  end

  it "formats tape with leading root entry" do
    doc_result = Warp::Parser.new.parse_document(%({"a":"b","c":"d"}).to_slice, validate_literals: true, validate_numbers: true)
    doc_result.error.success?.should be_true
    formatted = Warp::Format.pretty(doc_result.doc.not_nil!)
    formatted.includes?("\"a\"").should be_true
    formatted.includes?("\"c\"").should be_true
  end

  it "token scanner reports unknown when JSONC is disabled" do
    bytes = "/".to_slice
    tokens, error = Warp::Lexer::TokenScanner.scan(bytes, false)
    error.success?.should be_true
    tokens.any? { |tok| tok.kind == Warp::CST::TokenKind::Unknown }.should be_true
  end

  it "token scanner handles trailing slash in JSONC" do
    bytes = "/".to_slice
    tokens, error = Warp::Lexer::TokenScanner.scan(bytes, true)
    error.success?.should be_true
    tokens.any? { |tok| tok.kind == Warp::CST::TokenKind::Unknown }.should be_true
  end

  it "token scanner marks invalid JSONC slash as unknown" do
    bytes = "/a".to_slice
    tokens, error = Warp::Lexer::TokenScanner.scan(bytes, true)
    error.success?.should be_true
    tokens.any? { |tok| tok.kind == Warp::CST::TokenKind::Unknown }.should be_true
  end

  it "token scanner handles short line comments with scalar fallback" do
    bytes = %({"a":1 // x\n "b":2}).to_slice
    tokens, error = Warp::Lexer::TokenScanner.scan(bytes, true)
    error.success?.should be_true
    tokens.count { |tok| tok.kind == Warp::CST::TokenKind::CommentLine }.should eq(1)
  end

  it "covers scalar backend helpers" do
    backend = Warp::Backend::ScalarBackend.new
    backend.all_digits16?(Bytes.new(16, '9'.ord.to_u8).to_unsafe).should be_true
    backend.all_digits16?(Bytes.new(16, 'a'.ord.to_u8).to_unsafe).should be_false

    bytes = Bytes['a'.ord.to_u8, '\n'.ord.to_u8, '\r'.ord.to_u8, 'b'.ord.to_u8]
    mask = backend.newline_mask(bytes.to_unsafe, bytes.size)
    (mask & (1_u64 << 1)).should_not eq(0_u64)
    (mask & (1_u64 << 2)).should_not eq(0_u64)
  end

  it "logs backend selection when enabled" do
    previous = ENV["WARP_BACKEND_LOG"]?
    begin
      ENV["WARP_BACKEND_LOG"] = "1"
      Warp::Backend.reset
      Warp::Backend.current.name.should_not be_empty
    ensure
      if previous
        ENV["WARP_BACKEND_LOG"] = previous
      else
        ENV.delete("WARP_BACKEND_LOG")
      end
      Warp::Backend.reset
    end
  end

  {% if flag?(:aarch64) %}
  it "covers neon backend digit scan and newline mask" do
    backend = Warp::Backend::NeonBackend.new
    backend.all_digits16?(Bytes.new(16, '0'.ord.to_u8).to_unsafe).should be_true
    bytes = Bytes['a'.ord.to_u8, '\n'.ord.to_u8, '\r'.ord.to_u8, 'b'.ord.to_u8]
    mask = backend.newline_mask(bytes.to_unsafe, bytes.size)
    (mask & (1_u64 << 1)).should_not eq(0_u64)
  end

  it "covers neon newline mask helpers" do
    bytes8 = Bytes['a'.ord.to_u8, '\n'.ord.to_u8, '\r'.ord.to_u8, 'b'.ord.to_u8, 'c'.ord.to_u8, 'd'.ord.to_u8, 'e'.ord.to_u8, 'f'.ord.to_u8]
    mask8 = Warp::Backend::NeonMasks.newline_mask8(bytes8.to_unsafe)
    (mask8 & (1_u8 << 1)).should_not eq(0_u8)

    bytes16 = Bytes.new(16, 'a'.ord.to_u8)
    bytes16[3] = '\n'.ord.to_u8
    mask16 = Warp::Backend::NeonMasks.newline_mask16(bytes16.to_unsafe)
    (mask16 & (1_u16 << 3)).should_not eq(0_u16)
  end
  {% end %}
end
