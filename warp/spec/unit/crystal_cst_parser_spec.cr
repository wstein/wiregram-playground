require "../spec_helper"

describe "Crystal CST parser" do
  it "parses top-level require and ENV assignment" do
    bytes = File.read("spec/spec_helper.cr").to_slice

    tokens, lex_error, lex_pos = Warp::Lang::Crystal::Lexer.scan(bytes)
    lex_error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(bytes, tokens)
    parse_error.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    if root
      found_require = root.children.any? { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::Require }
      found_assign = root.children.any? { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::Assignment }
      found_require.should be_true
      found_assign.should be_true
    end
  end

  it "parses method definitions with various signature styles" do
    src = %(
def simple_method
  puts "hello"
end

def method_with_params(name, age : Int32)
  name + " is " + age.to_s
end

def method_with_return : String
  "result"
end
    ).to_slice

    tokens, lex_error, _ = Warp::Lang::Crystal::Lexer.scan(src)
    lex_error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(src, tokens)
    parse_error.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    if root
      methods = root.children.select { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::MethodDef }
      methods.size.should be >= 3

      # Check that first method has payload with name
      if payload = methods[0].method_payload
        payload.name.should eq("simple_method")
      end
    end
  end

  it "parses class definitions with nested methods" do
    src = %(
class Person
  def initialize(name)
    @name = name
  end

  def greet
    "Hello"
  end
end
    ).to_slice

    tokens, lex_error, _ = Warp::Lang::Crystal::Lexer.scan(src)
    lex_error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(src, tokens)
    parse_error.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    if root
      class_defs = root.children.select { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::ClassDef }
      class_defs.size.should be >= 1
    end
  end

  it "parses module definitions with nested content" do
    src = %(
module Utils
  def self.helper
    42
  end
end
    ).to_slice

    tokens, lex_error, _ = Warp::Lang::Crystal::Lexer.scan(src)
    lex_error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(src, tokens)
    parse_error.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    if root
      module_defs = root.children.select { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::ModuleDef }
      module_defs.size.should be >= 1
    end
  end

  it "parses constant definitions with type annotations" do
    src = %(
MAX_SIZE = 100
CONFIG : Hash(String, String) = {"key" => "value"}
PI = 3.14159
    ).to_slice

    tokens, lex_error, _ = Warp::Lang::Crystal::Lexer.scan(src)
    lex_error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(src, tokens)
    parse_error.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    if root
      const_defs = root.children.select { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::ConstantDef }
      const_defs.size.should be >= 1

      # Check payload of first constant
      if payload = const_defs[0].constant_payload
        payload.name.should eq("MAX_SIZE")
        payload.value.should eq("100")
      end
    end
  end

  it "parses struct and enum definitions" do
    src = %(
struct Point
  property x : Int32
  property y : Int32
end

enum Color
  Red
  Green
  Blue
end
    ).to_slice

    tokens, lex_error, _ = Warp::Lang::Crystal::Lexer.scan(src)
    lex_error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(src, tokens)
    parse_error.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    if root
      struct_defs = root.children.select { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::StructDef }
      enum_defs = root.children.select { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::EnumDef }

      struct_defs.size.should be >= 1
      enum_defs.size.should be >= 1
    end
  end

  it "parses top-level method calls with dot notation" do
    src = %(
puts "hello"
obj.method_name
root.not_nil!.children.map(&.kind)
    ).to_slice

    tokens, lex_error, _ = Warp::Lang::Crystal::Lexer.scan(src)
    lex_error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(src, tokens)
    parse_error.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    if root
      # Should have some parsed nodes
      root.children.size.should be > 0
    end
  end

  it "parses macro definitions" do
    src = %(
macro define_getter(name)
  def {{ name }}
    @{{ name }}
  end
end
    ).to_slice

    tokens, lex_error, _ = Warp::Lang::Crystal::Lexer.scan(src)
    lex_error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(src, tokens)
    parse_error.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    if root
      macro_defs = root.children.select { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::MacroDef }
      macro_defs.size.should be >= 1
    end
  end

  it "parses mixed program with multiple top-level constructs" do
    src = %(
require "json"

VERSION = "1.0.0"

class Handler
  def process
    42
  end
end

module Helpers
  def self.format(data)
    data
  end
end
    ).to_slice

    tokens, lex_error, _ = Warp::Lang::Crystal::Lexer.scan(src)
    lex_error.should eq(Warp::Core::ErrorCode::Success)

    root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(src, tokens)
    parse_error.should eq(Warp::Core::ErrorCode::Success)
    root.should_not be_nil

    if root
      # Check we have all major constructs
      has_require = root.children.any? { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::Require }
      has_const = root.children.any? { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::ConstantDef }
      has_class = root.children.any? { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::ClassDef }
      has_module = root.children.any? { |c| c.kind == Warp::Lang::Crystal::CST::NodeKind::ModuleDef }

      has_require.should be_true
      has_const.should be_true
      has_class.should be_true
      has_module.should be_true
    end
  end
end
