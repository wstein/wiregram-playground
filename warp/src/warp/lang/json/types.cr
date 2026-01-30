# JSON Language Support: Node and Token Definitions
#
# Defines JSON-specific TokenKind and NodeKind enums and provides
# type aliases for convenient use throughout the JSON parser.

module Warp
  module Lang
    module JSON
      # JSON TokenKind enum: JSON-specific lexical categories
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

      # JSON NodeKind enum: JSON-specific syntax tree node types
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

      # Type aliases for convenient use in JSON parser
      # Note: These reference CST generics which are loaded after this file
      # in the require chain. Actual aliasing happens in src/warp/cst/types.cr
    end
  end
end
