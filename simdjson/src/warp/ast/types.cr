module Warp
  module AST
    enum NodeKind
      Root
      Object
      Array
      Pair
      String
      Number
      True
      False
      Null
    end

    class Node
      getter kind : NodeKind
      getter children : Array(Node)
      getter value : String?

      def initialize(@kind : NodeKind, @children : Array(Node) = [] of Node, @value : String? = nil)
      end
    end

    class Builder
      def self.from_cst(doc : CST::Document) : Node
        root = doc.root
        Node.new(NodeKind::Root, root.children.map { |child| build_node(child, doc.bytes) })
      end

      private def self.build_node(node : CST::RedNode, bytes : Bytes) : Node
        case node.kind
        when CST::NodeKind::Object
          Node.new(NodeKind::Object, node.children.map { |child| build_node(child, bytes) })
        when CST::NodeKind::Array
          Node.new(NodeKind::Array, node.children.map { |child| build_node(child, bytes) })
        when CST::NodeKind::Pair
          Node.new(NodeKind::Pair, node.children.map { |child| build_node(child, bytes) })
        when CST::NodeKind::String
          token = node.token
          value = token ? String.new(bytes[token.start, token.length]) : ""
          Node.new(NodeKind::String, [] of Node, value)
        when CST::NodeKind::Number
          token = node.token
          value = token ? String.build { |io| io.write(bytes[token.start, token.length]) } : ""
          Node.new(NodeKind::Number, [] of Node, value)
        when CST::NodeKind::True
          Node.new(NodeKind::True)
        when CST::NodeKind::False
          Node.new(NodeKind::False)
        when CST::NodeKind::Null
          Node.new(NodeKind::Null)
        else
          Node.new(NodeKind::Null)
        end
      end
    end

    struct Result
      getter node : Node?
      getter error : Core::ErrorCode

      def initialize(@node : Node?, @error : Core::ErrorCode)
      end
    end
  end
end
