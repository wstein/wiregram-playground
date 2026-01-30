require "../spec_helper"

describe "Ruby Transpiler Phase 2" do
  it "parses corpus files into AST" do
    corpus_files = Dir.glob("corpus/ruby/*.rb")
    corpus_files.each do |file|
      source = File.read(file)
      result = Warp::Lang::Ruby::Parser.parse(source.to_slice)
      result.error.should eq(Warp::Core::ErrorCode::Success)
      result.node.not_nil!.kind.should eq(Warp::Lang::Ruby::NodeKind::Program)
    end
  end

  it "builds IR and transpiles simple definitions" do
    source = "class Greeter\n  def hello(name)\n    puts \"hi\"\n  end\nend"
    ast = Warp::Lang::Ruby::Parser.parse(source.to_slice)
    ast.error.should eq(Warp::Core::ErrorCode::Success)

    ir = Warp::Lang::Ruby::IR::Builder.from_ast(ast.node.not_nil!)
    ir.kind.should eq(Warp::Lang::Ruby::IR::Kind::Program)

    result = Warp::Lang::Ruby::Transpiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    result.output.should contain("class Greeter")
    result.output.should contain("def hello")
  end

  it "adds return type annotations for literal returns" do
    source = "def answer\n  42\nend"
    result = Warp::Lang::Ruby::Transpiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    result.output.should contain("def answer : Int32")
  end
end
