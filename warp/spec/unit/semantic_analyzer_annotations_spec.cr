require "../spec_helper"

describe "SemanticAnalyzer annotations" do
  it "collects inline sigs and inline RBS comments" do
    source = <<-RUBY
    # @rbs (String) -> String
    def greet(name)
      name
    end

    sig { params(x: String).returns(Integer) }
    def size(x)
      x.length
    end
    RUBY

    bytes = source.to_slice
    tokens, err = Warp::Lang::Ruby::Lexer.scan(bytes)
    err.should eq(Warp::Core::ErrorCode::Success)

    root, parse_err = Warp::Lang::Ruby::CST::Parser.parse(bytes, tokens)
    parse_err.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    analyzer = Warp::Lang::Ruby::SemanticAnalyzer.new(bytes, tokens, root.not_nil!)
    context = analyzer.analyze

    context.annotations.inline_rbs_methods.has_key?("greet").should be_true
    context.annotations.sig_methods.has_key?("size").should be_true
  end
end
