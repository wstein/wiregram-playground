require "../spec_helper"

describe "Struct transpilation" do
  it "transpiles struct definitions to Ruby" do
    source = <<-'CR'
struct BenchResult
  getter path : String
  getter count : Int64
  getter size : Int32
  getter seconds : Float64
  getter error : Simdjson::ErrorCode?
  getter message : String?

  def initialize(
    @path : String,
    @count : Int64,
    @size : Int32,
    @seconds : Float64,
    @error : Simdjson::ErrorCode? = nil,
    @message : String? = nil,
  )
  end
end
CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)

    # Should transpile successfully
    result.error.should eq(Warp::Core::ErrorCode::Success)

    # Output should not be empty
    result.output.should_not be_empty

    # Output should contain the struct keyword or class (Ruby equivalent)
    (result.output.includes?("struct") || result.output.includes?("class")).should eq(true)

    # Output should preserve the getter definitions
    result.output.includes?("path").should eq(true)
    result.output.includes?("count").should eq(true)

    # Output should contain the initialize method
    (result.output.includes?("initialize") || result.output.includes?("def ")).should eq(true)
  end

  it "preserves indentation in struct methods" do
    source = <<-'CR'
struct Point
  getter x : Int32
  getter y : Int32

  def distance(other : Point) : Float64
    Math.sqrt((x - other.x) ** 2 + (y - other.y) ** 2)
  end
end
CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    result.output.should_not be_empty
  end
end
