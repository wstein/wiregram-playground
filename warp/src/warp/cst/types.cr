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

# Suggestion #3: NodeKind Union Type
#
# To support multiple languages without massive enum bloat, we define an abstract
# base type for NodeKind. This allows the pipeline to work with either JSON or
# Ruby (or any future language) node kinds using polymorphism instead of enum
# matching on hardcoded types.
#
# IMPLEMENTATION NOTE:
# Crystal doesn't have true union types, so we use an abstract enum or module
# pattern. Each language provides its own NodeKind enum (e.g., JSON::NodeKind,
# Ruby::NodeKind), and the core pipeline uses type-erased references where needed.

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
      getter trailing_trivia : Array(Token)

      def initialize(
        @kind : NodeKind,
        @children : Array(GreenNode) = [] of GreenNode,
        @token : Token? = nil,
        @leading_trivia : Array(Token) = [] of Token,
        @trailing_trivia : Array(Token) = [] of Token,
      )
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

      def trailing_trivia : Array(Token)
        @green.trailing_trivia
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

    # ============================================================================
    # Suggestion #3: Language-Agnostic Node Kind Interface
    # ============================================================================
    #
    # To support multiple languages without a monolithic enum, we provide a
    # polymorphic mechanism for node kinds. Each language defines its own
    # NodeKind enum (JSON::NodeKind, Ruby::NodeKind, etc.), and the core
    # pipeline can work with any of them.
    #
    # Pattern: Language modules provide their own NodeKind enum, and if needed,
    # a wrapper/adapter for core pipeline integration.
    #
    # Example usage in a language-agnostic traversal:
    #   def walk(node : RedNode)
    #     case node.kind
    #     when JSON::NodeKind::Object, JSON::NodeKind::Array
    #       # Handle JSON containers
    #     when Ruby::NodeKind::MethodDef, Ruby::NodeKind::ClassDef
    #       # Handle Ruby definitions
    #     else
    #       # Handle others
    #     end
    #   end
    #
    # RATIONALE:
    # Crystal's strong typing prevents true union types in enums, but we can:
    # 1. Keep each language's NodeKind as a separate enum
    # 2. Use the node.kind method which returns the specific enum value
    # 3. Pattern match on language-specific variants in traversal code
    # 4. Avoid massive enum bloat by keeping JSON, Ruby, Crystal enums separate
    #
    # This approach maintains type safety while allowing extensibility.
  end
end
