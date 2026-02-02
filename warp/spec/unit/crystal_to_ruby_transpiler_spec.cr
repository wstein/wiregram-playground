require "../spec_helper"

describe "CrystalToRubyTranspiler" do
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

  it "handles nilable types" do
    source = "def maybe(name : String?) : String?\n  name\nend"
    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.output.should contain("sig { params(name: T.nilable(String)).returns(T.nilable(String)) }")
  end

  it "translates method-to-proc shorthand &.ident to Ruby &:ident" do
    source = "def test(root)\n  kinds = root.not_nil!.children.map(&.kind)\nend"
    result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    result.output.should contain(".map(&:kind)")
  end
end
