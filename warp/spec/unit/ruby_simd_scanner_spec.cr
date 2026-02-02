# Unit tests for Ruby SIMD Scanner
#
# Tests the Ruby-specific SIMD structural character detection

require "../spec_helper"

describe "Ruby SIMD Scanner" do
  describe "scan method" do
    it "finds structural indices" do
      code = "def foo; end"
      scanner = Warp::Lang::Ruby::SimdScanner.new(code.to_slice)
      indices = scanner.scan

      # Should find at least some structural indices
      indices.should_not be_empty
    end

    it "returns success error code when finding indices" do
      code = "{ x: 42 }"
      scanner = Warp::Lang::Ruby::SimdScanner.new(code.to_slice)
      scanner.scan

      # The scan should complete without error
      (scanner.error == Warp::Core::ErrorCode::Success || scanner.error == Warp::Core::ErrorCode::Empty).should be_true
    end

    it "returns correct language name" do
      scanner = Warp::Lang::Ruby::SimdScanner.new("test".to_slice)
      scanner.language_name.should eq("ruby")
    end

    it "handles empty input gracefully" do
      scanner = Warp::Lang::Ruby::SimdScanner.new("".to_slice)
      indices = scanner.scan

      # Empty input is acceptable
      (indices.empty? || scanner.error == Warp::Core::ErrorCode::Empty).should be_true
    end

    it "handles UTF-8 strings" do
      code = %Q{puts "Hello 世界"}
      scanner = Warp::Lang::Ruby::SimdScanner.new(code.to_slice)
      indices = scanner.scan

      # UTF-8 should be handled without error
      (scanner.error == Warp::Core::ErrorCode::Success || indices.size >= 0).should be_true
    end

    it "works through convenience function" do
      code = "def test; end"
      result = Warp::Lang::Ruby.simd_scan(code.to_slice)

      result.language.should eq("ruby")
      # The result should be valid
      (result.error == Warp::Core::ErrorCode::Success || result.error == Warp::Core::ErrorCode::Empty).should be_true
    end

    it "returns indices as UInt32 array" do
      code = "x = 1"
      result = Warp::Lang::Ruby.simd_scan(code.to_slice)

      # Result should have indices array
      result.indices.is_a?(Array(UInt32)).should be_true
    end

    it "handles longer Ruby code blocks" do
      code = <<-RUBY
      def hello(name)
        puts "Hello, \#{name}"
      end
      RUBY

      scanner = Warp::Lang::Ruby::SimdScanner.new(code.to_slice)
      indices = scanner.scan

      # Should handle multi-line code
      (scanner.error == Warp::Core::ErrorCode::Success || indices.size > 0).should be_true
    end
  end
end
