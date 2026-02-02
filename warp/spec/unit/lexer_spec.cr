require "../spec_helper"

describe Warp::Lexer do
  it "scans escapes and strings across blocks" do
    scanner = Warp::Lexer::EscapeScanner.new
    res = scanner.next(0_u64)
    res.escaped.should eq(0_u64)
    res.escape.should eq(0_u64)

    res = scanner.next(0b1010_u64)
    res.escaped.should_not eq(0_u64)

    Warp::Lexer::EscapeScanner.next_escape_and_terminal_code(0b1010_u64).should_not eq(0_u64)

    string_scanner = Warp::Lexer::StringScanner.new
    block = string_scanner.next(0b10_u64, 0b01_u64)
    block.string_tail.should_not eq(0_u64)
    string_scanner.finish.should eq(Warp::ErrorCode::UnclosedString)
    string_scanner.next(0_u64, 0b01_u64)
    string_scanner.finish.should eq(Warp::ErrorCode::Success)
  end

  it "evaluates string and character blocks" do
    sb = Warp::Lexer::StringBlock.new(0b1_u64, 0b10_u64, 0b11_u64)
    sb.string_tail.should eq(0b01_u64)
    sb.non_quote_inside_string(0b1111_u64).should eq(0b11_u64)
    sb.non_quote_outside_string(0b1111_u64).should eq(0b1100_u64)

    cb = Warp::Lexer::CharacterBlock.new(0b10_u64, 0b01_u64)
    cb.scalar.should eq(~0b11_u64)

    jb = Warp::Lexer::JsonBlock.new(sb, cb, 0b0100_u64)
    jb.structural_start.should_not eq(0_u64)
    jb.non_quote_inside_string(0b1111_u64).should eq(0b11_u64)
  end

  it "tracks UTF-8 state transitions explicitly" do
    validator = Warp::Lexer::Utf8Validator.new
    bytes = Bytes[0xf0, 0x90, 0x80, 0x80, 0x7b]
    validator.consume(bytes.to_unsafe, bytes.size).should be_true
    validator.finish?.should be_true
  end

  it "validates all UTF-8 lead byte categories in scalar mode" do
    validator = Warp::Lexer::Utf8Validator.new
    bytes = Bytes[
      0xC2, 0x80,
      0xE0, 0xA0, 0x80,
      0xE1, 0x80, 0x80,
      0xED, 0x80, 0x80,
      0xF0, 0x90, 0x80, 0x80,
      0xF1, 0x80, 0x80, 0x80,
      0xF4, 0x8F, 0x80, 0x80
    ]
    validator.validate_scalar(bytes.to_unsafe, bytes.size).should be_true
    validator.finish?.should be_true
  end

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
    result = Warp::Lexer.index(payload)
    result.error.should eq(Warp::ErrorCode::Success)
  end

  it "returns Empty for whitespace-only input" do
    bytes = "   \t".to_slice
    result = Warp::Lexer.index(bytes)
    result.error.should eq(Warp::ErrorCode::Empty)
  end

  it "returns UnclosedString for unterminated string" do
    bytes = %({"a":"b}).to_slice
    result = Warp::Lexer.index(bytes)
    result.error.should eq(Warp::ErrorCode::UnclosedString)
  end

  it "returns UnescapedChars for raw control characters in strings" do
    bytes = Bytes[0x7b, 0x22, 0x61, 0x22, 0x3a, 0x22, 0x01, 0x22, 0x7d]
    result = Warp::Lexer.index(bytes)
    result.error.should eq(Warp::ErrorCode::UnescapedChars)
  end

  it "returns Utf8Error for invalid UTF-8" do
    bytes = Bytes[0x7b, 0x22, 0x61, 0x22, 0x3a, 0x22, 0xc0, 0xaf, 0x22, 0x7d]
    result = Warp::Lexer.index(bytes)
    result.error.should eq(Warp::ErrorCode::Utf8Error)
  end

  it "handles multi-block inputs and trailing whitespace" do
    padding = Bytes.new(70, ' '.ord.to_u8)
    bytes = Bytes[0x7b] + padding + Bytes[0x7d]
    result = Warp::Lexer.index(bytes)
    result.error.should eq(Warp::ErrorCode::Success)
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
    Warp::Lexer.prefix_xor(mask).should eq(expected)
  end
end
