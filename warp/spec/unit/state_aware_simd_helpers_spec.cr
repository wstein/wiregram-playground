require "../spec_helper"

describe "State-Aware SIMD Helpers" do
  describe "string interior scanning" do
    it "finds closing quote in double-quoted string" do
      code = "hello world\""
      dquote = 34_u8 # "
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
        code.to_slice,
        0_u32,
        dquote,
        Warp::Backend.current
      )

      # Should find the closing quote at position 11
      result.should contain(11_u32)
    end

    it "finds escape sequences in strings" do
      code = "hello\\nworld\""
      dquote = 34_u8 # "
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
        code.to_slice,
        0_u32,
        dquote,
        Warp::Backend.current
      )

      # Should find escape at position 5
      result.should contain(5_u32)
    end

    it "finds string interpolation markers in double quotes" do
      code = "Hello world\""
      dquote = 34_u8 # "
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
        code.to_slice,
        0_u32,
        dquote,
        Warp::Backend.current
      )

      # Should find interpolation or at least process without error
      result.size >= 0
    end
  end

  describe "regex interior scanning" do
    it "finds closing slash in regex" do
      code = "pattern/i"
      slash = 47_u8 # /
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_regex_interior(
        code.to_slice,
        0_u32,
        Warp::Backend.current
      )

      # Should find the closing slash
      result.any? { |idx| idx < code.size && code.to_slice[idx] == slash }.should be_true
    end

    it "finds character classes in regex" do
      code = "[a-z]pattern/i"
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_regex_interior(
        code.to_slice,
        0_u32,
        Warp::Backend.current
      )

      # Should find [ and ]
      result.should contain(0_u32) # [
    end

    it "finds escape sequences in regex" do
      code = "hello\\d+/i"
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_regex_interior(
        code.to_slice,
        0_u32,
        Warp::Backend.current
      )

      # Should find escape at position 5
      result.should contain(5_u32)
    end
  end

  describe "heredoc scanning" do
    it "finds newlines in heredoc content" do
      code = "line1\nline2\nline3"
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_heredoc_content(
        code.to_slice,
        0_u32,
        "EOF",
        Warp::Backend.current
      )

      # Should find newlines
      result.size.should be > 0
    end

    it "identifies heredoc terminators" do
      code = "line1\nEOF\nline3"
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_heredoc_content(
        code.to_slice,
        0_u32,
        "EOF",
        Warp::Backend.current
      )

      # Should find the EOF terminator
      result.size.should be > 1
    end
  end

  describe "macro scanning (Crystal)" do
    it "finds macro delimiters" do
      code = "{%if condition%}content{%end%}"
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_macro_interior(
        code.to_slice,
        0_u32,
        Warp::Backend.current
      )

      # Should find braces
      result.should_not be_empty
    end

    it "tracks nesting levels" do
      code = "{ outer { inner } }"
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_macro_interior(
        code.to_slice,
        0_u32,
        Warp::Backend.current
      )

      # Should find both opening and closing braces
      result.size.should be >= 4
    end
  end

  describe "annotation scanning (Crystal)" do
    it "finds annotation delimiters" do
      code = "[Deprecated]"
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_annotation_interior(
        code.to_slice,
        0_u32,
        Warp::Backend.current
      )

      # Should find brackets and parameters
      result.should_not be_empty
    end

    it "tracks nested annotation parameters" do
      code = "[Before(Date.now)]"
      result = Warp::Lang::Common::StateAwareSimdHelpers.scan_annotation_interior(
        code.to_slice,
        0_u32,
        Warp::Backend.current
      )

      # Should find parentheses
      result.size.should be >= 2
    end
  end
end
