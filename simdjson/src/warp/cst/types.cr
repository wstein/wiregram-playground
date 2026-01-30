module Warp
  module CST
    enum TokenKind
      LBrace
      RBrace
      LBracket
      RBracket
      Colon
      Comma
      String
      Number
      True
      False
      Null
      Whitespace
      Newline
      CommentLine
      CommentBlock
      Unknown
      Eof
    end

    struct Token
      getter kind : TokenKind
      getter start : Int32
      getter length : Int32

      def initialize(@kind : TokenKind, @start : Int32, @length : Int32)
      end
    end

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

    class GreenNode
      getter kind : NodeKind
      getter children : Array(GreenNode)
      getter token : Token?
      getter leading_trivia : Array(Token)

      def initialize(@kind : NodeKind, @children : Array(GreenNode) = [] of GreenNode, @token : Token? = nil, @leading_trivia : Array(Token) = [] of Token)
      end
    end

    class RedNode
      getter green : GreenNode
      getter parent : RedNode?

      def initialize(@green : GreenNode, @parent : RedNode? = nil)
      end

      def kind : NodeKind
        @green.kind
      end

      def token : Token?
        @green.token
      end

      def leading_trivia : Array(Token)
        @green.leading_trivia
      end

      def children : Array(RedNode)
        @green.children.map { |child| RedNode.new(child, self) }
      end
    end

    class Document
      getter bytes : Bytes
      getter root : RedNode

      def initialize(@bytes : Bytes, @root : RedNode)
      end
    end

    struct Result
      getter doc : Document?
      getter error : Core::ErrorCode

      def initialize(@doc : Document?, @error : Core::ErrorCode)
      end
    end
  end
end
