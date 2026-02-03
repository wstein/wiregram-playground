require "../spec_helper"

def slice_trivia_text(bytes : Bytes, trivia : Array(Warp::Lang::Crystal::Trivia)) : String
  String.build do |io|
    trivia.each do |t|
      io << String.new(bytes[t.start, t.length])
    end
  end
end

describe "Crystal CST trivia" do
  it "attaches trailing trivia to last method node including EOF trivia" do
    source = <<-CR
    def hello
      1
    end
    # tail
    CR

    bytes = source.to_slice
    tokens, error = Warp::Lang::Crystal::Lexer.scan(bytes)
    error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_err = Warp::Lang::Crystal::CST::Parser.parse(bytes, tokens)
    parse_err.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    method_node = root.not_nil!.children.first
    method_node.kind.should eq(Warp::Lang::Crystal::CST::NodeKind::MethodDef)

    trailing = method_node.trailing_trivia
    trailing.size.should be > 0

    trailing_text = slice_trivia_text(bytes, trailing)
    trailing_text.includes?("# tail").should eq(true)
  end
end
