module Warp::Lang::Crystal
  module CST
    # Crystal-specific CST node kinds (Phase 1 minimal set)
    enum NodeKind
      Root
      RawText
    end

    # GreenNode: immutable tree node holding structure and trivia
    class GreenNode
      getter kind : NodeKind
      getter children : Array(GreenNode)
      getter text : String?
      getter leading_trivia : Array(Warp::Core::Token)

      def initialize(
        @kind : NodeKind,
        @children : Array(GreenNode) = [] of GreenNode,
        @text : String? = nil,
        @leading_trivia : Array(Warp::Core::Token) = [] of Warp::Core::Token,
      )
      end
    end

    # RedNode: provides parent/child navigation over GreenNode
    class RedNode
      getter green : GreenNode
      getter parent : RedNode?

      def initialize(@green : GreenNode, @parent : RedNode? = nil)
      end

      def kind : NodeKind
        @green.kind
      end

      def text : String?
        @green.text
      end

      def leading_trivia : Array(Warp::Core::Token)
        @green.leading_trivia
      end

      def children : Array(RedNode)
        @green.children.map { |child| RedNode.new(child, self) }
      end
    end

    # Document: wraps output bytes and the root RedNode
    class Document
      getter bytes : Bytes
      getter root : RedNode

      def initialize(@bytes : Bytes, @root : RedNode)
      end
    end
  end
end
