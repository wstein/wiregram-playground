require "../spec_helper"

describe Simdjson::Parser do
  it "iterates tokens and slices without copying" do
    json = %({"a":1,"b":[true,false,null,"x"],"c":{"d":"e","f":"\\\"q\\\""},"g":1 })
    bytes = json.to_slice
    parser = Simdjson::Parser.new
    types = [] of Simdjson::TokenType
    slices = [] of String

    err = parser.each_token(bytes) do |tok|
      types << tok.type
      slices << String.new(tok.slice(bytes)) if tok.type == Simdjson::TokenType::String
    end

    err.success?.should be_true
    types.includes?(Simdjson::TokenType::StartObject).should be_true
    types.includes?(Simdjson::TokenType::EndObject).should be_true
    types.includes?(Simdjson::TokenType::StartArray).should be_true
    types.includes?(Simdjson::TokenType::EndArray).should be_true
    types.includes?(Simdjson::TokenType::True).should be_true
    types.includes?(Simdjson::TokenType::False).should be_true
    types.includes?(Simdjson::TokenType::Null).should be_true
    slices.includes?("x").should be_true
    slices.any? { |s| s.includes?("q") }.should be_true
  end

  it "handles escaped strings and scalars" do
    json = %({"a":"line\\\\break","b":123 ,"c":-4.5})
    bytes = json.to_slice
    parser = Simdjson::Parser.new
    err = parser.each_token(bytes) { }
    err.success?.should be_true
  end

  it "parses document and yields tape entries" do
    json = %({"a":{},"b":[],"c":{"d":2,"s":"str"},"e":[3,"y",false]})
    bytes = json.to_slice
    parser = Simdjson::Parser.new
    result = parser.parse_document(bytes, validate_literals: true, validate_numbers: true)
    result.error.success?.should be_true

    doc = result.doc.not_nil!
    entries = [] of Simdjson::Stage2::Entry
    doc.each_entry { |entry| entries << entry }
    entries.size.should be > 0

    iter = doc.iterator
    while (entry = iter.next_entry)
      case entry.type
      when Simdjson::Stage2::TapeType::String, Simdjson::Stage2::TapeType::Key, Simdjson::Stage2::TapeType::Number,
           Simdjson::Stage2::TapeType::True, Simdjson::Stage2::TapeType::False, Simdjson::Stage2::TapeType::Null
        iter.slice(entry).should_not be_nil
      else
        iter.slice(entry).should be_nil
      end
    end
  end

  it "parses arrays with commas and ends" do
    json = %({"a":[1,2,3],"b":[],"c":[true,false]})
    parser = Simdjson::Parser.new
    result = parser.parse_document(json.to_slice)
    result.error.success?.should be_true
  end

  it "parses escaped strings in stage2" do
    json = %({"a":"\\\\","b":"\\\"quoted\\\"","c":"end"})
    parser = Simdjson::Parser.new
    result = parser.parse_document(json.to_slice)
    result.error.success?.should be_true
  end

  it "parses root strings with escapes" do
    json = Bytes[0x22, 0x5c, 0x5c, 0x5c, 0x22, 0x22]
    parser = Simdjson::Parser.new
    parser.parse_document(json).error.success?.should be_true
  end

  it "parses arrays with comma and end transitions" do
    parser = Simdjson::Parser.new
    parser.parse_document(%({"a":[1,2]}).to_slice).error.success?.should be_true
    parser.parse_document(%({"a":[1]}).to_slice).error.success?.should be_true
  end

  it "consumes all structurals and reports zero remaining" do
    bytes = %({"a":[1,2]}).to_slice
    stage1 = Simdjson::Stage1.index(bytes)
    stage1.error.success?.should be_true
    buffer = Simdjson::Stage1Buffer.new(stage1.indices.to_unsafe, stage1.indices.size, stage1.indices)
    iter = Simdjson::Stage2::Iterator.new(bytes, buffer)
    while iter.advance_index >= 0
    end
    iter.remaining_structurals.should eq(0)
  end

  it "tracks remaining structurals during iteration" do
    bytes = %({"a":[{"b":1},2]}).to_slice
    stage1 = Simdjson::Stage1.index(bytes)
    stage1.error.success?.should be_true
    buffer = Simdjson::Stage1Buffer.new(stage1.indices.to_unsafe, stage1.indices.size, stage1.indices)
    iter = Simdjson::Stage2::Iterator.new(bytes, buffer)
    iter.remaining_structurals.should be > 0
    iter.advance_index
    iter.remaining_structurals.should be >= 0
  end

  it "accepts UTF-8 max codepoint in strings" do
    bytes = Bytes[0x7b, 0x22, 0x61, 0x22, 0x3a, 0x22, 0xf4, 0x8f, 0xbf, 0xbf, 0x22, 0x7d]
    parser = Simdjson::Parser.new
    parser.parse_document(bytes).error.success?.should be_true
  end

  it "tracks remaining structurals via stage2 iterator" do
    json = %({"a":[1,2]})
    bytes = json.to_slice
    stage1 = Simdjson::Stage1.index(bytes)
    stage1.error.success?.should be_true
    buffer = Simdjson::Stage1Buffer.new(stage1.indices.to_unsafe, stage1.indices.size, stage1.indices)
    iter = Simdjson::Stage2::Iterator.new(bytes, buffer)
    iter.remaining_structurals.should be > 0
    iter.advance_index
    iter.remaining_structurals.should be >= 0
  end

  it "parses arrays with nested objects and trailing comma handling" do
    parser = Simdjson::Parser.new
    parser.parse_document(%([{"a":1}]).to_slice).error.success?.should be_true
    parser.parse_document(%([{"a":1},2]).to_slice).error.success?.should be_true
  end

  {% if flag?(:aarch64) %}
  it "validates multibyte UTF-8 sequences in neon validator" do
    bytes = Bytes[
      0xc2, 0xa2,       # 2-byte
      0xe0, 0xa0, 0x80, # 3-byte (E0)
      0xe1, 0x88, 0xb4, # 3-byte
      0xed, 0x9f, 0xbf, # 3-byte (ED)
      0xf0, 0x90, 0x80, 0x80, # 4-byte (F0)
      0xf1, 0x80, 0x80, 0x80, # 4-byte
      0xf4, 0x8f, 0xbf, 0xbf  # 4-byte (F4)
    ]
    state = 0_u32
    Simdjson::Stage1::Utf8::Neon.validate_block(bytes.to_unsafe, pointerof(state)).should be_true
    Simdjson::Stage1::Utf8::Neon.validate_block(bytes.to_unsafe + 16, pointerof(state)).should be_true
    state.should eq(0_u32)
  end
  {% end %}

  it "rejects invalid literals when validation is enabled" do
    json = %({"a":tru})
    bytes = json.to_slice
    parser = Simdjson::Parser.new
    result = parser.parse_document(bytes, validate_literals: true, validate_numbers: false)
    result.error.should eq(Simdjson::ErrorCode::TAtomError)
  end

  it "rejects invalid numbers when validation is enabled" do
    json = %({"a":01})
    bytes = json.to_slice
    parser = Simdjson::Parser.new
    result = parser.parse_document(bytes, validate_literals: false, validate_numbers: true)
    result.error.should eq(Simdjson::ErrorCode::NumberError)
  end

  it "returns TapeError for malformed structures" do
    parser = Simdjson::Parser.new
    parser.parse_document(%({a:1}).to_slice).error.should eq(Simdjson::ErrorCode::TapeError)
    parser.parse_document(%({"a" 1}).to_slice).error.should eq(Simdjson::ErrorCode::TapeError)
    parser.parse_document(%({"a":1,}).to_slice).error.should eq(Simdjson::ErrorCode::TapeError)
    parser.parse_document(%([1,]).to_slice).error.should eq(Simdjson::ErrorCode::TapeError)
  end
end
