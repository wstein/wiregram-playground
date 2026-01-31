module Warp::Lang::Crystal
  module CST
    # Crystal-specific CST node kinds (Phase 1 minimal set)
    enum NodeKind
      Root
      RawText
      MethodDef
    end

    struct ParamInfo
      getter name : String
      getter type : String?

      def initialize(@name : String, @type : String? = nil)
      end
    end

    struct MethodDefPayload
      getter name : String
      getter params : Array(ParamInfo)
      getter return_type : String?
      getter body : String
      getter had_parens : Bool

      def initialize(
        @name : String,
        @params : Array(ParamInfo),
        @return_type : String?,
        @body : String,
        @had_parens : Bool,
      )
      end
    end

    # GreenNode: immutable tree node holding structure and trivia
    class GreenNode
      getter kind : NodeKind
      getter children : Array(GreenNode)
      getter text : String?
      getter leading_trivia : Array(Warp::Lang::Ruby::Token)
      getter method_payload : MethodDefPayload?

      def initialize(
        @kind : NodeKind,
        @children : Array(GreenNode) = [] of GreenNode,
        @text : String? = nil,
        @leading_trivia : Array(Warp::Lang::Ruby::Token) = [] of Warp::Lang::Ruby::Token,
        @method_payload : MethodDefPayload? = nil,
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

      def leading_trivia : Array(Warp::Lang::Ruby::Token)
        @green.leading_trivia
      end

      def method_payload : MethodDefPayload?
        @green.method_payload
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
