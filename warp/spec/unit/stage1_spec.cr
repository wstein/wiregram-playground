require "../spec_helper"

describe Simdjson::Stage1 do
  it "scans escapes and strings across blocks" do
    scanner = Simdjson::Stage1::EscapeScanner.new
    res = scanner.next(0_u64)
    res.escaped.should eq(0_u64)
    res.escape.should eq(0_u64)

    res = scanner.next(0b1010_u64)
    res.escaped.should_not eq(0_u64)

    Simdjson::Stage1::EscapeScanner.next_escape_and_terminal_code(0b1010_u64).should_not eq(0_u64)

    string_scanner = Simdjson::Stage1::StringScanner.new
    block = string_scanner.next(0b10_u64, 0b01_u64)
    block.string_tail.should_not eq(0_u64)
    string_scanner.finish.should eq(Simdjson::ErrorCode::UnclosedString)
    string_scanner.next(0_u64, 0b01_u64)
    string_scanner.finish.should eq(Simdjson::ErrorCode::Success)
  end

  it "evaluates string and character blocks" do
    sb = Simdjson::Stage1::StringBlock.new(0b1_u64, 0b10_u64, 0b11_u64)
    sb.string_tail.should eq(0b01_u64)
    sb.non_quote_inside_string(0b1111_u64).should eq(0b11_u64)
    sb.non_quote_outside_string(0b1111_u64).should eq(0b1100_u64)

    cb = Simdjson::Stage1::CharacterBlock.new(0b10_u64, 0b01_u64)
    cb.scalar.should eq(~0b11_u64)

    jb = Simdjson::Stage1::JsonBlock.new(sb, cb, 0b0100_u64)
    jb.structural_start.should_not eq(0_u64)
    jb.non_quote_inside_string(0b1111_u64).should eq(0b11_u64)
  end

  it "tracks UTF-8 state transitions explicitly" do
    validator = Simdjson::Stage1::Utf8Validator.new
    bytes = Bytes[0xf0, 0x90, 0x80, 0x80, 0x7b]
    validator.consume(bytes.to_unsafe, bytes.size).should be_true
    validator.finish?.should be_true
  end

  {% if flag?(:aarch64) %}
  it "invokes NEON UTF-8 helpers directly" do
    state = 0_u32
    bytes = Bytes[0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
                  0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50]
    Simdjson::Stage1::Utf8::Neon.ascii_block?(bytes.to_unsafe).should be_true
    Simdjson::Stage1::Utf8::Neon.validate_block(bytes.to_unsafe, pointerof(state)).should be_true
  end
  {% end %}

  it "runs UTF-8 validation for diverse sequences" do
    payload = Bytes[
      0x7b, 0x22, 0x61, 0x22, 0x3a, 0x22,
      0xc2, 0xa2,       # U+00A2
      0xe0, 0xa0, 0x80, # U+0800
      0xe1, 0x88, 0xb4, # U+1234
      0xed, 0x9f, 0xbf, # U+D7FF
      0xee, 0x80, 0x80, # U+E000
      0xf0, 0x90, 0x80, 0x80, # U+10000
      0xf1, 0x80, 0x80, 0x80,
      0xf4, 0x8f, 0xbf, 0xbf, # U+10FFFF
      0x22, 0x7d
    ]
    result = Simdjson::Stage1.index(payload)
    result.error.should eq(Simdjson::ErrorCode::Success)
  end

  it "returns Empty for whitespace-only input" do
    bytes = "   \n\t".to_slice
    result = Simdjson::Stage1.index(bytes)
    result.error.should eq(Simdjson::ErrorCode::Empty)
  end

  it "returns UnclosedString for unterminated string" do
    bytes = %({"a":"b}).to_slice
    result = Simdjson::Stage1.index(bytes)
    result.error.should eq(Simdjson::ErrorCode::UnclosedString)
  end

  it "returns UnescapedChars for raw control characters in strings" do
    bytes = Bytes[0x7b, 0x22, 0x61, 0x22, 0x3a, 0x22, 0x01, 0x22, 0x7d]
    result = Simdjson::Stage1.index(bytes)
    result.error.should eq(Simdjson::ErrorCode::UnescapedChars)
  end

  it "returns Utf8Error for invalid UTF-8" do
    bytes = Bytes[0x7b, 0x22, 0x61, 0x22, 0x3a, 0x22, 0xc0, 0xaf, 0x22, 0x7d]
    result = Simdjson::Stage1.index(bytes)
    result.error.should eq(Simdjson::ErrorCode::Utf8Error)
  end

  it "handles multi-block inputs and trailing whitespace" do
    padding = Bytes.new(70, ' '.ord.to_u8)
    bytes = Bytes[0x7b] + padding + Bytes[0x7d]
    result = Simdjson::Stage1.index(bytes)
    result.error.should eq(Simdjson::ErrorCode::Success)
    result.indices.size.should be >= 2
  end

  it "computes prefix xor for bitmasks" do
    mask = 0b1011_u64
    expected = 0_u64
    parity = 0_u64
    64.times do |i|
      parity ^= ((mask >> i) & 1_u64)
      expected |= (parity << i)
    end
    Simdjson::Stage1.prefix_xor(mask).should eq(expected)
  end

  {% if flag?(:aarch64) %}
  it "builds NEON masks for known bytes" do
    bytes = Bytes['{'.ord, '}'.ord, '['.ord, ']'.ord, ':'.ord, ','.ord, '"'.ord, '\\'.ord]
    masks = Simdjson::Stage1::Neon.scan8(bytes.to_unsafe)
    masks.op.should_not eq(0_u8)
    masks.quote.should_not eq(0_u8)
    masks.backslash.should_not eq(0_u8)
    masks.whitespace.should eq(0_u8)
    masks.control.should eq(0_u8)
  end
  {% end %}
end
