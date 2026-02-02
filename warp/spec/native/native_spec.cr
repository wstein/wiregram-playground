require "../spec_helper"

describe "native (aarch64) helpers" do
  {% if flag?(:aarch64) %}
  it "invokes NEON UTF-8 helpers directly" do
    state = 0_u32
    bytes = Bytes[0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
                  0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50]
    backend = Warp::Backend.current
    backend.ascii_block?(bytes.to_unsafe).should be_true
    backend.validate_block(bytes.to_unsafe, pointerof(state)).should be_true
  end

  it "validates multibyte UTF-8 sequences across blocks" do
    validator = Warp::Lexer::Utf8Validator.new
    bytes = Bytes.new(32, 'a'.ord.to_u8)
    bytes[15] = 0xF0
    bytes[16] = 0x90
    bytes[17] = 0x80
    bytes[18] = 0x80
    validator.consume(bytes.to_unsafe, bytes.size).should be_true
    validator.finish?.should be_true
  end

  it "rejects invalid UTF-8 continuation across blocks" do
    validator = Warp::Lexer::Utf8Validator.new
    bytes = Bytes.new(32, 'a'.ord.to_u8)
    bytes[15] = 0xF0
    bytes[16] = 0x41
    validator.consume(bytes.to_unsafe, bytes.size).should be_false
  end

  it "packs pending UTF-8 state before NEON validation" do
    validator = Warp::Lexer::Utf8Validator.new
    lead = Bytes[0xE0]
    validator.validate_scalar(lead.to_unsafe, lead.size).should be_true
    validator.finish?.should be_false
    tail = Bytes[0xA0, 0x80]
    validator.consume(tail.to_unsafe, tail.size).should be_true
    validator.finish?.should be_true
  end

  it "builds NEON masks for known bytes" do
    bytes = Bytes['{'.ord, '}'.ord, '['.ord, ']'.ord, ':'.ord, ','.ord, '"'.ord, '\\'.ord]
    masks = Warp::Backend::NeonMasks.scan8(bytes.to_unsafe)
    masks.op.should_not eq(0_u8)
    masks.quote.should_not eq(0_u8)
    masks.backslash.should_not eq(0_u8)
    masks.whitespace.should eq(0_u8)
    masks.control.should eq(0_u8)
  end

  it "builds NEON masks for 16-byte blocks" do
    bytes = Bytes[
      '{'.ord.to_u8, '}'.ord.to_u8, '['.ord.to_u8, ']'.ord.to_u8,
      ':'.ord.to_u8, ','.ord.to_u8, '"'.ord.to_u8, '\\'.ord.to_u8,
      ' '.ord.to_u8, '\t'.ord.to_u8, '\n'.ord.to_u8, '\r'.ord.to_u8,
      0x01_u8, 'a'.ord.to_u8, 'b'.ord.to_u8, 'c'.ord.to_u8,
    ]
    masks = Warp::Backend::NeonMasks.scan16(bytes.to_unsafe)

    backslash = 0_u16
    quote = 0_u16
    whitespace = 0_u16
    op = 0_u16
    control = 0_u16
    16.times do |i|
      b = bytes[i]
      bit = 1_u16 << i
      control |= bit if b <= 0x1f
      case b
      when 0x20, 0x09
        whitespace |= bit
      when 0x0a, 0x0d
        op |= bit
      when '{'.ord, '}'.ord, '['.ord, ']'.ord, ':'.ord, ','.ord
        op |= bit
      end
      backslash |= bit if b == '\\'.ord
      quote |= bit if b == '"'.ord
    end

    masks.backslash.should eq(backslash)
    masks.quote.should eq(quote)
    masks.whitespace.should eq(whitespace)
    masks.op.should eq(op)
    masks.control.should eq(control)
  end
  {% end %}
end
