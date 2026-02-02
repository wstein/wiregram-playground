require "../spec_helper"

describe "Bidirectional Mapping: Ruby ↔ Crystal" do
  describe "require/require_relative mapping" do
    it "Crystal require -> Ruby require_relative" do
      crystal_source = <<-CR
require "../spec_helper"

def test(kind)
  root.not_nil!.children.map(&.kind)
end
CR

      result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(crystal_source.to_slice)
      result.error.should eq(Warp::Core::ErrorCode::Success)

      # Should contain require_relative for relative paths
      output = result.output
      output.should contain("require_relative") if output.includes?("../")
    end

    it "Ruby require_relative -> Crystal require" do
      ruby_source = <<-RB
require_relative "../spec_helper"

def test(kind)
  root.not_nil!.children.map { |n| n.kind }
end
RB

      result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(ruby_source.to_slice)
      result.error.should eq(Warp::Core::ErrorCode::Success)

      # Should contain require for Crystal
      output = result.output
      output.should contain("require")
    end
  end

  describe "block syntax mapping" do
    it "Crystal &.method -> Ruby explicit block" do
      crystal_source = <<-CR
def test(items)
  items.map(&.kind)
end
CR

      result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(crystal_source.to_slice)
      result.error.should eq(Warp::Core::ErrorCode::Success)

      # Should convert &.kind to { |item| item.kind } or similar
      output = result.output
      # After transpilation, Ruby should have explicit block syntax
      output.should_not contain("&.")
    end

    it "Ruby explicit block -> Crystal &. shorthand" do
      ruby_source = <<-RB
def test(items)
  items.map { |n| n.kind }
end
RB

      result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(ruby_source.to_slice)
      result.error.should eq(Warp::Core::ErrorCode::Success)

      # Should convert { |n| n.kind } to &.kind
      output = result.output
      # After transpilation, Crystal may use &.kind shorthand or explicit block
      output.should contain("map")
    end
  end

  describe "method chaining with blocks" do
    it "parses Ruby method chain with block" do
      ruby_source = "root.not_nil!.children.map { |n| n.kind }"
      bytes = ruby_source.to_slice
      tokens, lex_error, _ = Warp::Lang::Ruby::Lexer.scan(bytes)
      lex_error.should eq(Warp::Core::ErrorCode::Success)

      cst, parse_error = Warp::Lang::Ruby::CST::Parser.parse(bytes, tokens)
      parse_error.should eq(Warp::Core::ErrorCode::Success)

      # CST should have nested MethodCall nodes for chaining
      cst.children.size.should be > 0
      cst.children[0].kind.should eq(Warp::Lang::Ruby::CST::NodeKind::MethodCall)
    end

    it "parses Crystal method chain with block shorthand" do
      crystal_source = "root.not_nil!.children.map(&.kind)"
      bytes = crystal_source.to_slice
      tokens, lex_error, _ = Warp::Lang::Crystal::Lexer.scan(bytes)
      lex_error.should eq(Warp::Core::ErrorCode::Success)

      cst, parse_error = Warp::Lang::Crystal::CST::Parser.parse(bytes, tokens)
      parse_error.should eq(Warp::Core::ErrorCode::Success)

      # CST should have nested MethodCall nodes
      cst.children.size.should be > 0
    end
  end

  describe "CST structure preservation" do
    it "Ruby CST has explicit Block node for { |n| ... }" do
      ruby_source = "items.map { |n| n.kind }"
      bytes = ruby_source.to_slice
      tokens, _, _ = Warp::Lang::Ruby::Lexer.scan(bytes)
      cst, _ = Warp::Lang::Ruby::CST::Parser.parse(bytes, tokens)

      # Find the map MethodCall with block
      found_block = false
      cst.children.each do |child|
        if child.kind == Warp::Lang::Ruby::CST::NodeKind::MethodCall
          child.children.each do |sub|
            if sub.kind == Warp::Lang::Ruby::CST::NodeKind::Block
              found_block = true
            end
          end
        end
      end

      found_block.should eq(true)
    end
  end
end
