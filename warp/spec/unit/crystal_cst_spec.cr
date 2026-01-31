require "../spec_helper"

describe "Crystal CST Parser" do
  it "parses method definitions" do
    source = "def hello\n  1 + 1\nend"
    tokens, error = Warp::Lang::Crystal::Lexer.scan(source.to_slice)
    error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(source.to_slice, tokens)
    parse_error.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    children = root.not_nil!.children
    children.size.should eq(1)
    children[0].kind.should eq(Warp::Lang::Crystal::CST::NodeKind::MethodDef)
  end

  it "parses class and enum blocks" do
    source = "class Foo\nend\nenum Color\n  Red\nend"
    tokens, error = Warp::Lang::Crystal::Lexer.scan(source.to_slice)
    error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(source.to_slice, tokens)
    parse_error.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    kinds = root.not_nil!.children.map(&.kind)
    kinds.should contain(Warp::Lang::Crystal::CST::NodeKind::ClassDef)
    kinds.should contain(Warp::Lang::Crystal::CST::NodeKind::EnumDef)
  end
end
