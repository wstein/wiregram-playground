require "../spec_helper"

describe "Ruby CST" do
  describe "GreenNode construction" do
    it "can parse minimal Ruby code into CST" do
      source = "def hello\n  \"world\"\nend"
      bytes = source.to_slice
      tokens, error = Warp::Lang::Ruby::Lexer.scan(bytes)
      error.should eq(Warp::Core::ErrorCode::Success)

      cst, parse_err = Warp::Lang::Ruby::CST::Parser.parse(bytes, tokens)
      parse_err.should eq(Warp::Core::ErrorCode::Success)
      cst.should_not be_nil
      cst.kind.should eq(Warp::Lang::Ruby::CST::NodeKind::Root)
    end

    it "correctly nests method calls (chined calls)" do
      source = "root.not_nil!.children"
      bytes = source.to_slice
      tokens, _ = Warp::Lang::Ruby::Lexer.scan(bytes)
      cst, _ = Warp::Lang::Ruby::CST::Parser.parse(bytes, tokens)

      # Root -> MethodCall(children) -> MethodCall(not_nil!) -> Identifier(root)
      cst.kind.should eq(Warp::Lang::Ruby::CST::NodeKind::Root)
      cst.children.size.should eq(1)

      call_children = cst.children[0]
      call_children.kind.should eq(Warp::Lang::Ruby::CST::NodeKind::MethodCall)

      # The receiver should be another method call (not_nil!)
      receiver_not_nil = call_children.children[0]
      receiver_not_nil.kind.should eq(Warp::Lang::Ruby::CST::NodeKind::MethodCall)

      # The receiver of not_nil! should be root
      receiver_root = receiver_not_nil.children[0]
      receiver_root.kind.should eq(Warp::Lang::Ruby::CST::NodeKind::Identifier)
    end
  end

  describe "Rewriter" do
    it "emits unchanged source when no rewrites (RED test)" do
      source = "def hello\n  \"world\"\nend"
      bytes = source.to_slice
      tokens, _ = Warp::Lang::Ruby::Lexer.scan(bytes)

      rewriter = Warp::Lang::Ruby::Rewriter.new(bytes, tokens)
      output = rewriter.emit
      output.should eq(source)
    end

    it "removes a span correctly (RED test)" do
      source = "line1\nline2\nline3"
      bytes = source.to_slice
      tokens, _ = Warp::Lang::Ruby::Lexer.scan(bytes)

      rewriter = Warp::Lang::Ruby::Rewriter.new(bytes, tokens)
      rewriter.remove(6, 12) # Remove "line2\n"
      output = rewriter.emit
      output.should eq("line1\nline3")
    end

    it "replaces a span correctly (RED test)" do
      source = "def hello\nend"
      bytes = source.to_slice
      tokens, _ = Warp::Lang::Ruby::Lexer.scan(bytes)

      rewriter = Warp::Lang::Ruby::Rewriter.new(bytes, tokens)
      rewriter.replace(4, 9, "hello : String") # Replace "hello" with typed version
      output = rewriter.emit
      output.should eq("def hello : String\nend")
    end
  end

  describe "CST-to-CST Pipeline (Phase 1)" do
    it "emits unchanged output for simple method" do
      source = <<-RUBY
      def hello
        "world"
      end
      RUBY

      result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(source.to_slice)
      result.error.should eq(Warp::Core::ErrorCode::Success)
      result.output.should eq(source)
    end

    it "preserves comments without transformation" do
      source = <<-RUBY
      # This is a method
      def hello
        "world"
      end
      RUBY

      result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(source.to_slice)
      result.error.should eq(Warp::Core::ErrorCode::Success)
      result.output.should eq(source)
    end
  end
end
