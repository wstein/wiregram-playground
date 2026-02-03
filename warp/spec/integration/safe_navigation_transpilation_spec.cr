require "../spec_helper"

describe "Crystal-to-Ruby Transpilation: Safe Navigation & Method-to-Proc" do
  describe "safe navigation operator" do
    it "preserves Ruby safe navigation" do
      source = <<-'CR'
def test(obj)
  result = obj&.to_s
end
CR

      result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)

      # Should transpile successfully
      result.error.should eq(Warp::Core::ErrorCode::Success)
      result.output.should_not be_empty

      # Should contain &.to_s (Ruby safe navigation)
      result.output.includes?("&.to_s").should eq(true)
    end
  end

  describe "method-to-proc shorthand" do
    it "converts &.method in method calls to explicit block" do
      source = <<-'CR'
def test(array)
  result = array.map(&.kind)
end
CR

      result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)

      # Should transpile successfully
      result.error.should eq(Warp::Core::ErrorCode::Success)
      result.output.should_not be_empty

      # Should NOT contain &.kind
      result.output.includes?("&.kind").should eq(false)

      # Should contain explicit block
      (result.output.includes?(".map { |n| n.kind }") || result.output.includes?(".map({ |n| n.kind })")).should eq(true)
    end
  end

  describe "complex example" do
    it "transpiles multiple safe navigation operators" do
      source = <<-'CR'
def process(root)
  root.not_nil!.children.map(&.kind)
end
CR

      result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)

      # Should transpile successfully
      result.error.should eq(Warp::Core::ErrorCode::Success)
      result.output.should_not be_empty

      # Should contain explicit block
      (result.output.includes?(".map { |n| n.kind }") || result.output.includes?(".map({ |n| n.kind })")).should eq(true)
    end
  end
end
