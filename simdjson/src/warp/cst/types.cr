# CST Type Definitions
#
# ARCHITECTURAL NOTE: This file defines the JSON-specific CST types that are used
# throughout the existing parser. As Warp expands to support Ruby and Crystal,
# each language will define its own module with similar structures.
#
# For multi-language support, language-specific types are defined in:
# - src/warp/lang/json/types.cr
# - src/warp/lang/ruby/types.cr
# - src/warp/lang/crystal/types.cr (future)
#
# Current JSON parser continues to use these backward-compatible types.

module Warp
  module CST
    # TokenKind: JSON-specific lexical tokens
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

    # Token: represents a lexical unit with kind, position, and length
    struct Token
      getter kind : TokenKind
      getter start : Int32
      getter length : Int32

      def initialize(@kind : TokenKind, @start : Int32, @length : Int32)
      end
    end

    # NodeKind: JSON-specific syntax tree node types
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

    # GreenNode: immutable tree node holding structure and trivia
    # Used for lossless CST construction
    class GreenNode
      getter kind : NodeKind
      getter children : Array(GreenNode)
      getter token : Token?
      getter leading_trivia : Array(Token)

      def initialize(@kind : NodeKind, @children : Array(GreenNode) = [] of GreenNode, @token : Token? = nil, @leading_trivia : Array(Token) = [] of Token)
      end
    end

    # RedNode: provides parent/child navigation over GreenNode
    # Used for efficient tree traversal
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

    # Document: wraps the original bytes and the root RedNode
    class Document
      getter bytes : Bytes
      getter root : RedNode

      def initialize(@bytes : Bytes, @root : RedNode)
      end
    end

    # ParseResult: tuple of optional document and error code
    struct Result
      getter doc : Document?
      getter error : Core::ErrorCode

      def initialize(@doc : Document?, @error : Core::ErrorCode)
      end
    end
  end
end
