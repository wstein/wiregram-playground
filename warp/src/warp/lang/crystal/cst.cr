module Warp::Lang::Crystal
  module CST
    # Crystal-specific CST node kinds (Phase 1 minimal set)
    enum NodeKind
      Root
      RawText
      MethodDef
      ClassDef
      ModuleDef
      StructDef
      EnumDef
      MacroDef
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
      getter leading_trivia : Array(Warp::Lang::Crystal::Token)
      getter method_payload : MethodDefPayload?

      def initialize(
        @kind : NodeKind,
        @children : Array(GreenNode) = [] of GreenNode,
        @text : String? = nil,
        @leading_trivia : Array(Warp::Lang::Crystal::Token) = [] of Warp::Lang::Crystal::Token,
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

      def leading_trivia : Array(Warp::Lang::Crystal::Token)
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

    # Parser: builds CST from tokens preserving all trivia
    class Parser
      @bytes : Bytes
      @tokens : Array(Warp::Lang::Crystal::Token)
      @pos : Int32

      def initialize(@bytes, @tokens)
        @pos = 0
      end

      def self.parse(bytes : Bytes, tokens : Array(Warp::Lang::Crystal::Token)) : Tuple(GreenNode?, Warp::Core::ErrorCode)
        parser = new(bytes, tokens)
        root = parser.parse_program
        {root, Warp::Core::ErrorCode::Success}
      end

      def parse_program : GreenNode
        trivia = collect_trivia
        children = [] of GreenNode

        while @pos < @tokens.size && current.kind != TokenKind::Eof
          case current.kind
          when TokenKind::Def
            children << parse_simple_block(NodeKind::MethodDef)
          when TokenKind::Class
            children << parse_simple_block(NodeKind::ClassDef)
          when TokenKind::Module
            children << parse_simple_block(NodeKind::ModuleDef)
          when TokenKind::Struct
            children << parse_simple_block(NodeKind::StructDef)
          when TokenKind::Enum
            children << parse_simple_block(NodeKind::EnumDef)
          when TokenKind::Macro
            children << parse_simple_block(NodeKind::MacroDef)
          else
            advance
          end
        end

        GreenNode.new(NodeKind::Root, children)
      end

      private def parse_simple_block(kind : NodeKind) : GreenNode
        trivia = collect_trivia
        advance

        while @pos < @tokens.size && current.kind != TokenKind::End
          advance
        end

        advance if current.kind == TokenKind::End

        GreenNode.new(kind, [] of GreenNode)
      end

      private def collect_trivia : Array(Warp::Lang::Crystal::Token)
        trivia = [] of Warp::Lang::Crystal::Token

        while @pos < @tokens.size
          kind = current.kind
          if kind == TokenKind::Whitespace || kind == TokenKind::Newline || kind == TokenKind::CommentLine
            trivia << current
            advance
          else
            break
          end
        end

        trivia
      end

      private def current : Warp::Lang::Crystal::Token
        return @tokens[-1] if @pos >= @tokens.size
        @tokens[@pos]
      end

      private def advance
        @pos += 1 if @pos < @tokens.size
      end
    end
  end
end
