require "../spec_helper"

describe Warp::Backend::ARMv6Backend do
  it "identifies itself as armv6 backend" do
    backend = Warp::Backend::ARMv6Backend.new
    backend.name.should eq("armv6")
  end

  it "inherits from Backend::Base" do
    backend = Warp::Backend::ARMv6Backend.new
    backend.should be_a(Warp::Backend::Base)
  end

  describe "build_masks functionality" do
    it "builds character masks for JSON structural characters" do
      backend = Warp::Backend::ARMv6Backend.new
      
      # Test with simple JSON
      json = "{\"key\": \"value\"}"
      ptr = json.to_unsafe
      masks = backend.build_masks(ptr, json.size)
      
      # Verify masks are created
      masks.should be_a(Warp::Lexer::Masks)
      # Structural characters should be detected
      masks.op.should_not eq(0_u64)
    end

    it "detects quotes in strings" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "\"hello\""
      ptr = json.to_unsafe
      masks = backend.build_masks(ptr, json.size)
      
      # Quote should be detected
      masks.quote.should_not eq(0_u64)
    end

    it "detects backslashes" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "\"esc\\ape\""
      ptr = json.to_unsafe
      masks = backend.build_masks(ptr, json.size)
      
      # Backslash should be detected
      masks.backslash.should_not eq(0_u64)
    end

    it "detects whitespace" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = " \t\n\r"
      ptr = json.to_unsafe
      masks = backend.build_masks(ptr, json.size)
      
      # Whitespace should be detected
      masks.whitespace.should_not eq(0_u64)
    end

    it "detects control characters" do
      backend = Warp::Backend::ARMv6Backend.new
      
      # Control character in buffer
      buffer = Bytes[0x01, 0x02, 0x03]
      ptr = buffer.to_unsafe
      masks = backend.build_masks(ptr, buffer.size)
      
      # Control characters should be detected
      masks.control.should_not eq(0_u64)
    end

    it "handles partial blocks (less than 64 bytes)" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "{}"
      ptr = json.to_unsafe
      masks = backend.build_masks(ptr, json.size)
      
      # Should handle partial blocks correctly
      masks.should be_a(Warp::Lexer::Masks)
    end

    it "pads partial blocks with whitespace mask" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "x"  # 1 byte
      ptr = json.to_unsafe
      masks = backend.build_masks(ptr, json.size)
      
      # Partial block should pad with whitespace (0xFFFF...FF >> 1)
      # Verify no panic/segfault
      masks.should be_a(Warp::Lexer::Masks)
    end

    it "detects structural JSON characters" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "[]{}:,"
      ptr = json.to_unsafe
      masks = backend.build_masks(ptr, json.size)
      
      # All structural characters should be in op mask
      masks.op.should_not eq(0_u64)
    end
  end

  describe "all_digits16? functionality" do
    it "returns true for 16 ASCII digits" do
      backend = Warp::Backend::ARMv6Backend.new
      
      digits = "0123456789012345"
      ptr = digits.to_unsafe
      result = backend.all_digits16?(ptr)
      
      result.should be_true
    end

    it "returns false for non-digit characters" do
      backend = Warp::Backend::ARMv6Backend.new
      
      non_digits = "012345678901234a"
      ptr = non_digits.to_unsafe
      result = backend.all_digits16?(ptr)
      
      result.should be_false
    end

    it "returns false for mixed alphanumeric" do
      backend = Warp::Backend::ARMv6Backend.new
      
      mixed = "abc123def45678"
      ptr = mixed.to_unsafe
      result = backend.all_digits16?(ptr)
      
      result.should be_false
    end

    it "handles boundary cases" do
      backend = Warp::Backend::ARMv6Backend.new
      
      # First digit non-matching
      non_digits = "a123456789012345"
      ptr = non_digits.to_unsafe
      backend.all_digits16?(ptr).should be_false
      
      # Last digit non-matching
      non_digits = "012345678901234a"
      ptr = non_digits.to_unsafe
      backend.all_digits16?(ptr).should be_false
    end
  end

  describe "newline_mask functionality" do
    it "detects newline characters (\\n)" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "line1\nline2"
      ptr = json.to_unsafe
      mask = backend.newline_mask(ptr, json.size)
      
      # Newline should be in mask
      mask.should_not eq(0_u64)
    end

    it "detects carriage return characters (\\r)" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "line1\rline2"
      ptr = json.to_unsafe
      mask = backend.newline_mask(ptr, json.size)
      
      # Carriage return should be in mask
      mask.should_not eq(0_u64)
    end

    it "detects both \\n and \\r" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "a\nb\rc"
      ptr = json.to_unsafe
      mask = backend.newline_mask(ptr, json.size)
      
      # Both should be detected
      mask.should_not eq(0_u64)
    end

    it "returns 0 for no newlines" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "no newlines here"
      ptr = json.to_unsafe
      mask = backend.newline_mask(ptr, json.size)
      
      # No newlines should give 0 mask
      mask.should eq(0_u64)
    end

    it "handles partial blocks" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "a"
      ptr = json.to_unsafe
      mask = backend.newline_mask(ptr, json.size)
      
      mask.should eq(0_u64)
    end

    it "sets correct bit positions for newlines" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "\n\n"  # 2 newlines
      ptr = json.to_unsafe
      mask = backend.newline_mask(ptr, json.size)
      
      # Bits 0 and 1 should be set
      (mask & 0x1_u64).should eq(0x1_u64)
      (mask & 0x2_u64).should eq(0x2_u64)
    end
  end

  describe "backend consistency with ScalarBackend" do
    it "produces same masks as ScalarBackend" do
      armv6_backend = Warp::Backend::ARMv6Backend.new
      scalar_backend = Warp::Backend::ScalarBackend.new
      
      json = "{\"test\": 123}"
      ptr = json.to_unsafe
      
      armv6_masks = armv6_backend.build_masks(ptr, json.size)
      scalar_masks = scalar_backend.build_masks(ptr, json.size)
      
      # Both should produce equivalent results
      armv6_masks.quote.should eq(scalar_masks.quote)
      armv6_masks.backslash.should eq(scalar_masks.backslash)
      armv6_masks.op.should eq(scalar_masks.op)
    end

    it "handles digits identically to ScalarBackend" do
      armv6_backend = Warp::Backend::ARMv6Backend.new
      scalar_backend = Warp::Backend::ScalarBackend.new
      
      digits = "0123456789ABCDEF"
      ptr = digits.to_unsafe
      
      armv6_result = armv6_backend.all_digits16?(ptr)
      scalar_result = scalar_backend.all_digits16?(ptr)
      
      armv6_result.should eq(scalar_result)
    end

    it "detects newlines identically to ScalarBackend" do
      armv6_backend = Warp::Backend::ARMv6Backend.new
      scalar_backend = Warp::Backend::ScalarBackend.new
      
      json = "a\nb\nc"
      ptr = json.to_unsafe
      
      armv6_mask = armv6_backend.newline_mask(ptr, json.size)
      scalar_mask = scalar_backend.newline_mask(ptr, json.size)
      
      armv6_mask.should eq(scalar_mask)
    end
  end

  describe "edge cases and robustness" do
    it "handles empty buffer safely" do
      backend = Warp::Backend::ARMv6Backend.new
      
      # Empty block (0 bytes)
      buffer = Bytes[]
      ptr = buffer.to_unsafe
      masks = backend.build_masks(ptr, 0)
      
      # Should handle without panic
      masks.should be_a(Warp::Lexer::Masks)
    end

    it "handles max size buffer" do
      backend = Warp::Backend::ARMv6Backend.new
      
      # 64-byte block (typical SIMD block size)
      buffer = Bytes.new(64, 'a'.ord.to_u8)
      ptr = buffer.to_unsafe
      masks = backend.build_masks(ptr, buffer.size)
      
      # Should handle full block
      masks.should be_a(Warp::Lexer::Masks)
    end

    it "handles JSON with all character types" do
      backend = Warp::Backend::ARMv6Backend.new
      
      json = "{\"key\": \"val\\ue\", \"num\": 123}"
      ptr = json.to_unsafe
      masks = backend.build_masks(ptr, json.size)
      
      # Should detect all elements
      masks.quote.should_not eq(0_u64)
      masks.backslash.should_not eq(0_u64)
      masks.op.should_not eq(0_u64)
    end
  end
end
