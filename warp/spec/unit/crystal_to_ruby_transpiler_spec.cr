require "../spec_helper"

describe "CrystalToRubyTranspiler (CST-driven)" do
  it "transforms require to require_relative for relative paths" do
    source = <<-CR
      require "./foo"
      require "../bar"
      require_relative "./baz"
    CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    output = result.output
    output.includes?("require_relative \"./foo\"").should eq(true)
    output.includes?("require_relative \"../bar\"").should eq(true)
    output.includes?("require_relative \"./baz\"").should eq(true)
    output.includes?("require \"./\"").should eq(false)
  end

  it "converts &.method to explicit Ruby block" do
    source = <<-CR
      def process(items)
        items.map(&.to_s)
      end
    CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    output = result.output
    (output.includes?(".map { |n| n.to_s }") || output.includes?(".map({ |n| n.to_s })")).should eq(true)
    output.includes?("&.to_s").should eq(false)
  end

  it "emits Sorbet sig for typed method parameters" do
    source = <<-CR
      def add(x : Int32, y : Int32) : Int32
        x + y
      end
    CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    output = result.output
    output.includes?("sig {").should eq(true)
    output.includes?("params(").should eq(true)
    output.includes?("returns(Integer)").should eq(true)
    output.includes?("def add(x, y)").should eq(true)
  end

  it "handles untyped method parameters gracefully" do
    source = <<-'CR'
      def greet(name)
        "Hello, #{name}"
      end
    CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    output = result.output
    output.includes?("def greet(name)").should eq(true)
    # No sig needed for untyped
    output.includes?("sig {").should eq(false)
  end

  it "translates Crystal types to Ruby types (String)" do
    source = <<-CR
      def process(s : String) : String
        s
      end
    CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    output = result.output
    output.includes?("String").should eq(true)
  end

  it "handles nilable types (T.nilable)" do
    source = <<-CR
      def maybe(x : String?) : String?
        x
      end
    CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    output = result.output
    output.includes?("T.nilable").should eq(true)
  end

  it "does not duplicate slashes in require_relative paths" do
    source = <<-CR
      require "./warp/ast"
    CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    output = result.output
    output.includes?("require_relative \".//").should eq(false)
    output.includes?("require_relative \"./warp/ast\"").should eq(true)
  end

  it "preserves comments in output" do
    source = <<-CR
      # This is a comment
      require "./foo"
    CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    output = result.output
    output.includes?("# This is a comment").should eq(true)
  end

  it "handles method with multiple parameters of mixed types" do
    source = <<-CR
      def calculate(x : Int32, y : Float32, name : String) : Float32
        (x + y).to_f * 1.5
      end
    CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    output = result.output
    output.includes?("sig {").should eq(true)
    output.includes?("x: Integer").should eq(true)
    output.includes?("y: Float").should eq(true)
    output.includes?("name: String").should eq(true)
    output.includes?(".returns(Float)").should eq(true)
  end

  it "strips type annotations from method signature in output" do
    source = <<-CR
      def process(items : Array(String)) : Array(String)
        items
      end
    CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    output = result.output
    # Def line should NOT have type annotations
    output.includes?("def process(items)").should eq(true)
    output.includes?("def process(items : Array(String))").should eq(false)
  end

  it "inserts Sorbet sigs and strips types" do
    source = <<-CR
      def greet(name : String, age : Int32) : String
        "hello \#{name}"
      end
    CR

    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)

    result.output.should contain("sig { params(name: String, age: Integer).returns(String) }")
    result.output.should contain("def greet(name, age)")
  end

  it "handles nilable types (legacy test)" do
    source = "def maybe(name : String?) : String?\n  name\nend"
    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.output.should contain("sig { params(name: T.nilable(String)).returns(T.nilable(String)) }")
  end

  it "translates method-to-proc shorthand &.ident to Ruby explicit block (legacy)" do
    source = "def test(root)\n  kinds = root.not_nil!.children.map(&.kind)\nend"
    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    (result.output.includes?(".map { |n| n.kind }") || result.output.includes?(".map({ |n| n.kind })")).should eq(true)
  end
end
