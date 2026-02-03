require "../spec_helper"

describe "CST trivia (parser-level ignore)" do
  it "ignores leading trivia when building CST (Ruby)" do
    base = "def hello\n  \"world\"\nend"
    with_trivia = "# leading comment\n\n  # another\n" + base

    tokens1, err1 = Warp::Lang::Ruby::Lexer.scan(base.to_slice)
    err1.should eq(Warp::Core::ErrorCode::Success)
    cst1, pe1 = Warp::Lang::Ruby::CST::Parser.parse(base.to_slice, tokens1)
    pe1.should eq(Warp::Core::ErrorCode::Success)
    cst1.should_not be_nil

    tokens2, err2 = Warp::Lang::Ruby::Lexer.scan(with_trivia.to_slice)
    err2.should eq(Warp::Core::ErrorCode::Success)
    cst2, pe2 = Warp::Lang::Ruby::CST::Parser.parse(with_trivia.to_slice, tokens2)
    pe2.should eq(Warp::Core::ErrorCode::Success)
    cst2.should_not be_nil

    cst1.children.size.should eq(cst2.children.size)
    cst1.children[0].kind.should eq(cst2.children[0].kind)
  end

  it "ignores leading trivia when building CST (Crystal)" do
    base = "def hello\n  \"world\"\nend"
    with_trivia = "# leading comment\n\n" + base

    tokens1, err1 = Warp::Lang::Crystal::Lexer.scan(base.to_slice)
    err1.should eq(Warp::Core::ErrorCode::Success)
    cst1, pe1 = Warp::Lang::Crystal::CST::Parser.parse(base.to_slice, tokens1)
    pe1.should eq(Warp::Core::ErrorCode::Success)

    tokens2, err2 = Warp::Lang::Crystal::Lexer.scan(with_trivia.to_slice)
    err2.should eq(Warp::Core::ErrorCode::Success)
    cst2, pe2 = Warp::Lang::Crystal::CST::Parser.parse(with_trivia.to_slice, tokens2)
    pe2.should eq(Warp::Core::ErrorCode::Success)

    cst1.children.size.should eq(cst2.children.size)
    cst1.children[0].kind.should eq(cst2.children[0].kind)
  end
end
