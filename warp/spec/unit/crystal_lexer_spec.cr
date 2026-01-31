require "../spec_helper"

describe "Crystal Lexer" do
  it "lexes simple method definition" do
    source = "def hello\n  puts \"Hello\"\nend"
    tokens, error = Warp::Lang::Crystal::Lexer.scan(source.to_slice)

    error.should eq(Warp::Core::ErrorCode::Success)
    tokens.size.should_not eq(0)
    tokens.last.kind.should eq(Warp::Lang::Crystal::TokenKind::Eof)

    kinds = tokens.map(&.kind)
    kinds.should contain(Warp::Lang::Crystal::TokenKind::Def)
    kinds.should contain(Warp::Lang::Crystal::TokenKind::Identifier)
    kinds.should contain(Warp::Lang::Crystal::TokenKind::String)
    kinds.should contain(Warp::Lang::Crystal::TokenKind::End)
  end

  it "lexes class/struct/enum keywords" do
    source = "class Foo\nend\nstruct Bar\nend\nenum Baz\nend"
    tokens, error = Warp::Lang::Crystal::Lexer.scan(source.to_slice)

    error.should eq(Warp::Core::ErrorCode::Success)
    kinds = tokens.map(&.kind)
    kinds.should contain(Warp::Lang::Crystal::TokenKind::Class)
    kinds.should contain(Warp::Lang::Crystal::TokenKind::Struct)
    kinds.should contain(Warp::Lang::Crystal::TokenKind::Enum)
  end

  it "lexes annotations and instance vars" do
    source = "@[Foo]\nclass Bar\n  def initialize(@name)\n  end\nend"
    tokens, error = Warp::Lang::Crystal::Lexer.scan(source.to_slice)

    error.should eq(Warp::Core::ErrorCode::Success)
    kinds = tokens.map(&.kind)
    kinds.should contain(Warp::Lang::Crystal::TokenKind::At)
    kinds.should contain(Warp::Lang::Crystal::TokenKind::InstanceVar)
  end

  it "detects unterminated string" do
    tokens, error = Warp::Lang::Crystal::Lexer.scan("\"unterminated".to_slice)
    error.should eq(Warp::Core::ErrorCode::StringError)
  end
end
