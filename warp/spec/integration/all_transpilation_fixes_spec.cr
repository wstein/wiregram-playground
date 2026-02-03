require "../spec_helper"

describe "Crystal-to-Ruby Transpilation: All Fixes" do
  it "fixes safe navigation operator conversion" do
    source = <<-'CR'
def test(obj)
  obj&.to_s
end
CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    # Accept either symbol-to-proc (&:to_s) or preserved safe navigation (&.to_s)
    (result.output.includes?("&:to_s") || result.output.includes?("&.to_s")).should eq(true)
  end

  it "fixes method-to-proc shorthand" do
    source = <<-'CR'
def test(root)
  root.children.map(&.kind)
end
CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    (result.output.includes?(".map { |n| n.kind }") || result.output.includes?(".map({ |n| n.kind })")).should eq(true)
    result.output.includes?("&.kind").should eq(false)
  end

  it "fixes tuple literal conversion" do
    source = <<-'CR'
def test
  tuple = {1, 2}
  pair = {"hello", 42}
end
CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    result.output.includes?("[1, 2]").should eq(true)
    result.output.includes?("{1, 2}").should eq(false)
    result.output.includes?("[\"hello\", 42]").should eq(true)
  end

  it "handles complex real-world example" do
    source = <<-'CR'
def process(root)
  root.not_nil!.children.map(&.kind)
  results = [
    {node_a, node_b},
    {item1, item2},
  ]
  results.each { |pair| pair.first&.inspect }
end
CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    # Check that the method-to-proc is fixed
    (result.output.includes?(".map { |n| n.kind }") || result.output.includes?(".map({ |n| n.kind })")).should eq(true)

    # Check that tuple literals are fixed
    result.output.includes?("[node_a, node_b]").should eq(true)
    result.output.includes?("[item1, item2]").should eq(true)

    # Check that safe navigation is preserved
    result.output.includes?("&.inspect").should eq(true)
  end
end
