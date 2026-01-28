require "../spec_helper"

describe Simdjson::Stage2 do
  it "builds and closes containers" do
    bytes = "{}".to_slice
    builder = Simdjson::Stage2::Builder.new(bytes, false, false, 4)
    builder.start_object
    builder.increment_count
    builder.end_object
    builder.start_array
    builder.increment_count
    builder.end_array
    builder.empty_object
    builder.empty_array
    builder.tape.size.should be > 0
  end

  it "validates literals correctly" do
    bytes = "true false null".to_slice
    Simdjson::Stage2.valid_true?(bytes, 0, 4).should be_true
    Simdjson::Stage2.valid_false?(bytes, 5, 5).should be_true
    Simdjson::Stage2.valid_null?(bytes, 11, 4).should be_true
  end

  it "validates numbers correctly" do
    bytes = "0 -1 3.14 1e2 1E+2 1E-2".to_slice
    Simdjson::Stage2.valid_number?(bytes, 0, 1).should be_true
    Simdjson::Stage2.valid_number?(bytes, 2, 2).should be_true
    Simdjson::Stage2.valid_number?(bytes, 5, 4).should be_true
    Simdjson::Stage2.valid_number?(bytes, 10, 3).should be_true
    Simdjson::Stage2.valid_number?(bytes, 14, 4).should be_true
    Simdjson::Stage2.valid_number?(bytes, 19, 4).should be_true
    Simdjson::Stage2.valid_number?(bytes, 0, 0).should be_false
  end

  it "writes primitive entries for each type" do
    bytes = "true false null 123".to_slice
    builder = Simdjson::Stage2::Builder.new(bytes, true, true, 10)
    builder.primitive(0, 4).should eq(Simdjson::ErrorCode::Success)
    builder.primitive(5, 10).should eq(Simdjson::ErrorCode::Success)
    builder.primitive(11, 15).should eq(Simdjson::ErrorCode::Success)
    builder.primitive(16, bytes.size).should eq(Simdjson::ErrorCode::Success)
  end

  it "reports literal and number errors from primitives" do
    bytes = "tru fals nul 01".to_slice
    builder = Simdjson::Stage2::Builder.new(bytes, true, true, 10)
    builder.primitive(0, 3).should eq(Simdjson::ErrorCode::TAtomError)
    builder.primitive(4, 8).should eq(Simdjson::ErrorCode::FAtomError)
    builder.primitive(9, 12).should eq(Simdjson::ErrorCode::NAtomError)
    builder.primitive(13, bytes.size).should eq(Simdjson::ErrorCode::NumberError)
  end

  it "finds string and scalar ends" do
    bytes = %({"a":"b","c":123}).to_slice
    string_start = bytes.index('"'.ord, 0).not_nil!
    next_struct = bytes.index(','.ord, string_start).not_nil!
    end_idx = Simdjson::Stage2.scan_string_end(bytes, string_start + 1, next_struct)
    bytes[end_idx].should eq('"'.ord)

    number_start = bytes.index('1'.ord).not_nil!
    next_struct = bytes.index('}'.ord, number_start).not_nil!
    Simdjson::Stage2.scan_scalar_end(bytes, number_start, next_struct).should eq(next_struct)

    closing_quote = bytes.index('"'.ord, string_start + 1).not_nil!
    Simdjson::Stage2.scan_string_end(bytes, string_start + 1, closing_quote + 1).should eq(closing_quote)

    whitespace_json = %({"a":42   }).to_slice
    number_start = whitespace_json.index('4'.ord).not_nil!
    next_struct = whitespace_json.index('}'.ord, number_start).not_nil!
    Simdjson::Stage2.scan_scalar_end(whitespace_json, number_start, next_struct).should eq(whitespace_json.index(' '.ord, number_start).not_nil!)
  end

  it "scans escaped strings without a following structural" do
    bytes = Bytes[0x22, 0x5c, 0x5c, 0x5c, 0x22, 0x22] # "\"\\\""
    start = 1
    end_idx = Simdjson::Stage2.scan_string_end(bytes, start, -1)
    end_idx.should eq(bytes.size - 1)
  end

  it "iterates structurals in order" do
    bytes = %({"a":[1,2]}).to_slice
    stage1 = Simdjson::Stage1.index(bytes)
    stage1.error.success?.should be_true
    buffer = Simdjson::Stage1Buffer.new(stage1.indices.to_unsafe, stage1.indices.size, stage1.indices)
    iter = Simdjson::Stage2::Iterator.new(bytes, buffer)
    iter.at_eof?.should be_false
    first = iter.advance_index
    first.should be >= 0
    iter.remaining_structurals.should be > 0
    iter.last_structural_byte.should_not eq(0_u8)
    iter.peek_byte.should_not eq(0_u8)
    iter.peek_index.should be >= -1
  end

  it "iterates tape entries and resets" do
    bytes = %({"a":1}).to_slice
    result = Simdjson::Parser.new.parse_document(bytes)
    result.error.success?.should be_true
    doc = result.doc.not_nil!
    it = doc.iterator
    entry = it.next_entry
    entry.should_not be_nil
    it.reset
    it.next_entry.should_not be_nil
    while it.next_entry
    end
    it.next_entry.should be_nil
  end

  it "returns depth errors for nested documents with low max_depth" do
    bytes = %({"a":{"b":{"c":1}}}).to_slice
    stage1 = Simdjson::Stage1.index(bytes)
    buffer = Simdjson::Stage1Buffer.new(stage1.indices.to_unsafe, stage1.indices.size, stage1.indices)
    result = Simdjson::Stage2.parse(bytes, buffer, 1, false, false)
    result.error.should eq(Simdjson::ErrorCode::DepthError)
  end

  it "returns Empty when stage1 has no structurals" do
    bytes = "".to_slice
    buffer = Simdjson::Stage1Buffer.new(Pointer(UInt32).null, 0)
    result = Simdjson::Stage2.parse(bytes, buffer, 4, false, false)
    result.error.should eq(Simdjson::ErrorCode::Empty)
  end

  it "returns TapeError for malformed structures" do
    parser = Simdjson::Parser.new
    parser.parse_document(%({a:1}).to_slice).error.should eq(Simdjson::ErrorCode::TapeError)
    parser.parse_document(%({"a" 1}).to_slice).error.should eq(Simdjson::ErrorCode::TapeError)
    parser.parse_document(%({"a":1,}).to_slice).error.should eq(Simdjson::ErrorCode::TapeError)
    parser.parse_document(%({"a":1 "b":2}).to_slice).error.should eq(Simdjson::ErrorCode::TapeError)
    parser.parse_document(%([1,]).to_slice).error.should eq(Simdjson::ErrorCode::TapeError)
    parser.parse_document(%([,1]).to_slice).error.should eq(Simdjson::ErrorCode::TapeError)
    parser.parse_document(%([1 2]).to_slice).error.should eq(Simdjson::ErrorCode::TapeError)
  end

  it "returns TapeError for truncated structural buffers" do
    bytes = %({"a":1}).to_slice
    indices = [0] of UInt32
    buffer = Simdjson::Stage1Buffer.new(indices.to_unsafe, indices.size, indices)
    Simdjson::Stage2.parse(bytes, buffer, 4, false, false).error.should eq(Simdjson::ErrorCode::TapeError)

    indices = [0_u32, 4_u32] # '{' and ':' as a bad key
    buffer = Simdjson::Stage1Buffer.new(indices.to_unsafe, indices.size, indices)
    Simdjson::Stage2.parse(bytes, buffer, 4, false, false).error.should eq(Simdjson::ErrorCode::TapeError)

    bytes = %([1:]).to_slice
    indices = [0_u32, 1_u32, 2_u32] # '[', '1', ':'
    buffer = Simdjson::Stage1Buffer.new(indices.to_unsafe, indices.size, indices)
    Simdjson::Stage2.parse(bytes, buffer, 4, false, false).error.should eq(Simdjson::ErrorCode::TapeError)
  end
end
