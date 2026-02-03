require "../spec_helper"

describe "Escape and string edge cases" do
  it "parses escaped quotes in JSON strings (integration)" do
    json = %q({"a":"foo\\bar","b":"He said \"hello\"","c":"end"})
    parser = Warp::Parser.new
    result = parser.parse_document(json.to_slice)
    result.error.success?.should be_true
  end

  it "StringScanner and EscapeScanner produce consistent masks" do
    json = %q({"a":"foo\\bar","b":"He said \"hello\"","c":"end"})
    bytes = json.to_slice
    ptr = bytes.to_unsafe
    masks = Warp::Backend.current.build_masks(ptr, bytes.size)

    sc = Warp::Lexer::StringScanner.new
    block = sc.next(masks.backslash, masks.quote)

    # There should be some backslash-derived escaped bits and quote bits
    block.escaped.should_not eq(0_u64)
    block.quote.should_not eq(0_u64)
    # Escaped bits are a subset of the original quote mask
    (block.escaped & masks.quote).should eq(block.escaped)
    # After removing escaped quotes, the quote mask inside the block should
    # not include any escaped bits.
    (block.quote & block.escaped).should eq(0_u64)
  end

  it "TokenAssembler emits string tokens for escaped strings" do
    json = %q({"a":"foo\\bar","b":"He said \"hello\"","c":"end"})
    bytes = json.to_slice
    stage1 = Warp::Lexer.index(bytes)
    stage1.error.success?.should be_true

    tokens = [] of Warp::Core::Token
    err = Warp::Lexer::TokenAssembler.each_token(bytes, stage1.buffer) do |tok|
      tokens << tok
    end
    err.success?.should be_true

    # Ensure we have string tokens and that lengths make sense
    string_tokens = tokens.select { |t| t.type == Warp::TokenType::String }
    string_tokens.size.should be > 0
    string_tokens.each do |t|
      slice = t.slice(bytes)
      slice.should_not be_nil
      slice.size.should be >= 0
    end

    # Structural start produced for this block must not include escaped quotes
    # (string scanner must mark escaped quotes and structural mask should
    # exclude them).
    sc = Warp::Lexer::StringScanner.new

    # Rebuild masks for this bytes slice and compute a JsonBlock to inspect
    ptr = bytes.to_unsafe
    masks = Warp::Backend.current.build_masks(ptr, bytes.size)
    jb = Warp::Lexer::Scanner.new.next(masks.backslash, masks.quote, masks.whitespace, masks.op)
    (jb.structural_start & jb.strings.escaped).should eq(0_u64)
  end

  it "parses root string with multiple escapes" do
    bytes = Bytes[0x22, 0x5c, 0x5c, 0x5c, 0x22, 0x22]
    parser = Warp::Parser.new
    parser.parse_document(bytes).error.success?.should be_true
  end
end
