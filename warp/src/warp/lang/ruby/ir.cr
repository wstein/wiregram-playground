# Ruby semantic IR for transpilation

module Warp
  module Lang
    module Ruby
      module IR
        enum Kind
          Program
          Def
          Class
          Module
          Call
          Block
          Return
          If
          Unless
          While
          Literal
          Identifier
          Assignment
          Array
          Hash
          Binary
          Opaque
        end

        class Node
          getter kind : Kind
          getter children : Array(Node)
          getter value : String?
          getter start : Int32
          getter length : Int32
          property meta : Hash(String, String)?

          def initialize(
            @kind : Kind,
            @children : Array(Node) = [] of Node,
            @value : String? = nil,
            @start : Int32 = 0,
            @length : Int32 = 0,
            @meta : Hash(String, String)? = nil,
          )
          end

          def span_end : Int32
            @start + @length
          end
        end

        class Builder
          def self.from_ast(node : AST::Node) : Node
            case node.kind
            when NodeKind::Program
              Node.new(Kind::Program, node.children.map { |c| from_ast(c) }, nil, node.start, node.length)
            when NodeKind::MethodDef
              Node.new(Kind::Def, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length, node.meta)
            when NodeKind::ClassDef
              Node.new(Kind::Class, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length, node.meta)
            when NodeKind::ModuleDef
              Node.new(Kind::Module, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length, node.meta)
            when NodeKind::Call
              Node.new(Kind::Call, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length, node.meta)
            when NodeKind::Block
              Node.new(Kind::Block, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length, node.meta)
            when NodeKind::Return
              Node.new(Kind::Return, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length)
            when NodeKind::If
              Node.new(Kind::If, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length)
            when NodeKind::Unless
              Node.new(Kind::Unless, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length)
            when NodeKind::While
              Node.new(Kind::While, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length)
            when NodeKind::Identifier, NodeKind::Constant, NodeKind::InstanceVar, NodeKind::ClassVar, NodeKind::GlobalVar
              Node.new(Kind::Identifier, [] of Node, node.value, node.start, node.length)
            when NodeKind::String, NodeKind::Regex, NodeKind::Number, NodeKind::Symbol, NodeKind::Boolean, NodeKind::Nil
              Node.new(Kind::Literal, [] of Node, node.value, node.start, node.length, {"literal_kind" => node.kind.to_s})
            when NodeKind::Assignment
              Node.new(Kind::Assignment, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length)
            when NodeKind::Array
              Node.new(Kind::Array, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length)
            when NodeKind::Hash
              Node.new(Kind::Hash, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length)
            when NodeKind::Binary
              Node.new(Kind::Binary, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length)
            else
              Node.new(Kind::Opaque, node.children.map { |c| from_ast(c) }, node.value, node.start, node.length)
            end
          end
        end
      end
    end
  end
end
