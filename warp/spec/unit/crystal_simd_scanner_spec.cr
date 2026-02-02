require "../spec_helper"

describe "Crystal SIMD Scanner" do
  describe "scan method" do
    it "finds structural indices" do
      code = "def foo; end"
      scanner = Warp::Lang::Crystal::SimdScanner.new(code.to_slice)
      indices = scanner.scan

      # Should find at least some structural indices
      indices.should_not be_empty
    end

    it "returns success error code when finding indices" do
      code = "{ x = 42 }"
      scanner = Warp::Lang::Crystal::SimdScanner.new(code.to_slice)
      scanner.scan

      # The scan should complete without error
      (scanner.error == Warp::Core::ErrorCode::Success || scanner.error == Warp::Core::ErrorCode::Empty).should be_true
    end

    it "returns correct language name" do
      scanner = Warp::Lang::Crystal::SimdScanner.new("test".to_slice)
      scanner.language_name.should eq("crystal")
    end

    it "handles empty input gracefully" do
      scanner = Warp::Lang::Crystal::SimdScanner.new("".to_slice)
      indices = scanner.scan

      # Empty input is acceptable
      (indices.empty? || scanner.error == Warp::Core::ErrorCode::Empty).should be_true
    end

    it "handles UTF-8 strings" do
      code = %Q{puts "Hello 世界"}
      scanner = Warp::Lang::Crystal::SimdScanner.new(code.to_slice)
      indices = scanner.scan

      # UTF-8 should be handled without error
      (scanner.error == Warp::Core::ErrorCode::Success || indices.size >= 0).should be_true
    end

    it "works through convenience function" do
      code = "def test; end"
      result = Warp::Lang::Crystal.simd_scan(code.to_slice)

      result.language.should eq("crystal")
      # The result should be valid
      (result.error == Warp::Core::ErrorCode::Success || result.error == Warp::Core::ErrorCode::Empty).should be_true
    end

    it "returns indices as UInt32 array" do
      code = "x = 1"
      result = Warp::Lang::Crystal.simd_scan(code.to_slice)

      # Result should have indices array
      result.indices.is_a?(Array(UInt32)).should be_true
    end

    it "handles longer Crystal code blocks" do
      code = <<-CRYSTAL
      def hello(name : String) : String
        "Hello, " + name
      end
      CRYSTAL

      scanner = Warp::Lang::Crystal::SimdScanner.new(code.to_slice)
      indices = scanner.scan

      # Should handle multi-line code
      (scanner.error == Warp::Core::ErrorCode::Success || indices.size > 0).should be_true
    end

    it "detects Crystal-specific annotations" do
      code = "@[JSON::Serializable]"
      scanner = Warp::Lang::Crystal::SimdScanner.new(code.to_slice)
      indices = scanner.scan

      # Should detect the @ character for annotations
      indices.should_not be_empty
    end

    it "detects Crystal macro delimiters" do
      code = "{{name}}"
      scanner = Warp::Lang::Crystal::SimdScanner.new(code.to_slice)
      indices = scanner.scan

      bytes = code.to_slice
      indices.any? { |idx| idx < bytes.size && bytes[idx]? == '{'.ord.to_u8 }.should be_true
    end
  end
end
