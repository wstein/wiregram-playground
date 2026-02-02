require "../spec_helper"

describe "Crystal Syntax Transpilation" do
  describe "numeric suffixes" do
    it "removes Crystal numeric suffixes like _u64, _i32, etc" do
      source = <<-'CR'
def calculate
  by = 23_u8
  w = 3.1415_f32
  x = 42_u64
  y = 100_i32
  z = 3.14_f64
  a = 1_000_000_u64
  result = x + y + z
end
CR

      result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)

      # Should transpile successfully
      result.error.should eq(Warp::Core::ErrorCode::Success)
      result.output.should_not be_empty

      # Should NOT contain Crystal numeric suffixes
      result.output.includes?("_u8").should eq(false)
      result.output.includes?("_u64").should eq(false)
      result.output.includes?("_i32").should eq(false)
      result.output.includes?("_f32").should eq(false)
      result.output.includes?("_f64").should eq(false)
    end
  end

  describe "array type annotations" do
    it "converts [] of Type to []" do
      source = <<-'CR'
def get_numbers
  arr = [] of Int32
  arr2 = [] of String
  arr3 = [] of Float64
end
CR

      result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)

      # Should transpile successfully
      result.error.should eq(Warp::Core::ErrorCode::Success)
      result.output.should_not be_empty

      # Should NOT contain "of Type" syntax
      result.output.includes?("of Int32").should eq(false)
      result.output.includes?("of String").should eq(false)
      result.output.includes?("of Float64").should eq(false)

      # Should contain empty array literals
      result.output.includes?("[]").should eq(true)
    end
  end

  describe "tuple literals" do
    it "converts tuple literal braces {a, b} to array literal [a, b]" do
      source = <<-'CR'
def create_tuple
  tuple = {1, 2}
  pair = {"hello", 42}
  triple = {x, y, z}
end
CR

      result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)

      # Should transpile successfully
      result.error.should eq(Warp::Core::ErrorCode::Success)
      result.output.should_not be_empty

      # Tuples with braces should be converted to arrays with brackets
      # The actual format may vary, but braces should be replaced with brackets
      result.output.includes?("{1, 2}").should eq(false)
      result.output.includes?("[1, 2]").should eq(true)
    end
  end

  describe "complex real-world example" do
    it "transpiles struct with numeric literals and array types correctly" do
      source = <<-'CR'
struct BenchResult
  getter path : String
  getter count : Int64
  getter size : Int32
  getter seconds : Float64

  def initialize(
    @path : String,
    @count : Int64,
    @size : Int32,
    @seconds : Float64,
  )
    @errors = [] of String
    @codes = [] of Int32
  end
end
CR

      result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)

      # Should transpile successfully
      result.error.should eq(Warp::Core::ErrorCode::Success)
      result.output.should_not be_empty

      # Should contain struct definition
      (result.output.includes?("struct") || result.output.includes?("class")).should eq(true)

      # Should NOT contain Crystal syntax errors
      result.output.includes?("_i64").should eq(false)
      result.output.includes?("_i32").should eq(false)
      result.output.includes?("_f64").should eq(false)

      # Should not have "[] of" syntax
      result.output.includes?("[] of").should eq(false)
    end
  end
end
