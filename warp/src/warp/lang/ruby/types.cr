# Ruby Language Support: Node and Token Definitions
#
# Placeholder for Ruby-specific TokenKind and NodeKind enums.
# This will be expanded to support full Ruby parsing.

module Warp
  module Lang
    module Ruby
      # Ruby TokenKind enum: Ruby-specific lexical categories
      # TODO: Expand to include Ruby tokens (IDENTIFIER, KEYWORD, HEREDOC, etc.)
      enum TokenKind
        # Keywords
        Def
        End
        Class
        Module
        If
        Elsif
        Else
        Unless
        Case
        When
        While
        Until
        For
        In
        Do
        Break
        Next
        Return
        Yield
        Self
        Super
        True
        False
        Nil

        # Identifiers and Literals
        Identifier
        Constant
        InstanceVar
        ClassVar
        GlobalVar
        Symbol
        String
        InterpolatedString
        Regex
        Number
        Float
        Heredoc

        # Operators
        Plus
        Minus
        Star
        Slash
        Percent
        Power
        Equal
        PlusEqual
        MinusEqual
        StarEqual
        SlashEqual
        PercentEqual
        PowerEqual
        Ampersand
        Pipe
        Caret
        Tilde
        LeftShift
        RightShift
        LogicalAnd
        LogicalOr
        Not
        Match
        NotMatch
        Spaceship
        LessThan
        GreaterThan
        LessEqual
        GreaterEqual
        Range
        ExclusiveRange
        Arrow
        DoubleColon
        DoubleSplat
        Splat

        # Delimiters
        LParen
        RParen
        LBracket
        RBracket
        LBrace
        RBrace
        Comma
        Dot
        Semicolon
        Colon
        Question
        At
        DoubleAt

        # Whitespace and Comments
        Whitespace
        Newline
        CommentLine
        CommentBlock

        # Special
        Unknown
        Eof
      end

      # Ruby NodeKind enum: Ruby-specific syntax tree node types
      # TODO: Expand with full Ruby AST node types
      enum NodeKind
        Root
        Program

        # Definitions
        MethodDef
        ClassDef
        ModuleDef
        SingletonMethodDef

        # Control Flow
        If
        Unless
        Case
        When
        While
        Until
        For
        Break
        Next
        Return
        Yield

        # Expressions
        Binary
        Unary
        Call
        Index
        Assignment
        MultipleAssignment

        # Literals
        String
        InterpolatedString
        Symbol
        Array
        Hash
        Range
        Regex
        Number
        Boolean
        Nil

        # Structure
        Block
        Lambda
        Proc
        Begin
        Rescue
        Ensure
        Retry
        Raise

        # Special
        Identifier
        Constant
        InstanceVar
        ClassVar
        GlobalVar
        Self
        Super

        # Sorbet / Type Annotations
        SorbetSig
        TypeAnnotation

        # Trivia markers
        Comment
        Whitespace
      end

      # Type aliases for convenient use in Ruby parser
      # Note: These reference CST generics which are loaded after this file
      # in the require chain. Actual aliasing happens in derived files.
    end
  end
end
