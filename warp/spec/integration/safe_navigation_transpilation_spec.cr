require "../spec_helper"

describe "Crystal-to-Ruby Transpilation: Safe Navigation & Method-to-Proc" do
  describe "safe navigation operator" do
    it "converts &.method to &:method" do
      source = <<-'CR'
def test(obj)
  result = obj&.to_s
end
CR

      result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)

      # Should transpile successfully
      result.error.should eq(Warp::Core::ErrorCode::Success)
      result.output.should_not be_empty

      # Should NOT contain &.to_s
      result.output.includes?("&.to_s").should eq(false)

      # Should contain &:to_s
      result.output.includes?("&:to_s").should eq(true)
    end
  end

  describe "method-to-proc shorthand" do
    it "converts &.method in method calls to &:method" do
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

      # Should contain .map(&:kind)
      result.output.includes?(".map(&:kind)").should eq(true)
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

      # Should contain &:kind
      result.output.includes?(".map(&:kind)").should eq(true)
    end
  end
end
