# Crystal Language Support: Token Definitions (Phase 1)

module Warp
  module Lang
    module Crystal
      alias ErrorCode = Warp::Core::ErrorCode

      # Trivia kinds stored alongside tokens for whitespace/comments.
      enum TriviaKind
        Whitespace
        Newline
        CommentLine
        CommentBlock
      end

      # Trivia carries non-semantic source text (whitespace/comments).
      struct Trivia
        property kind : TriviaKind
        property start : Int32
        property length : Int32

        def initialize(@kind : TriviaKind, @start : Int32, @length : Int32)
        end
      end

      enum TokenKind
        # Keywords
        Def
        End
        Class
        Module
        Struct
        Enum
        Macro
        If
        Elsif
        Else
        Unless
        While
        Until
        For
        In
        Do
        When
        Return
        Break
        Next
        Yield
        True
        False
        Nil
        Lib
        Fun
        Require
        Include
        Extend
        Abstract
        Alias
        Annotation
        Private
        Protected
        Self
        Super

        # Identifiers and Literals
        Identifier
        Constant
        InstanceVar
        ClassVar
        GlobalVar
        MacroVar
        Symbol
        String
        Regex
        Char
        Number
        Float

        # Operators
        Plus
        Minus
        Star
        Slash
        Percent
        Power
        Equal
        EqualEqual
        NotEqual
        LessThan
        GreaterThan
        LessEqual
        GreaterEqual
        LogicalAnd
        LogicalOr
        Not
        Ampersand
        Pipe
        Caret
        Tilde
        LeftShift
        RightShift
        Dot
        DoubleColon
        Colon
        Arrow
        FatArrow
        Question
        At

        # Delimiters
        LParen
        RParen
        LBracket
        RBracket
        LBrace
        RBrace
        Comma
        Semicolon

        # Macro delimiters
        MacroStart
        MacroEnd

        # Whitespace and Comments
        Whitespace
        Newline
        CommentLine

        # Special
        Unknown
        Eof
      end

      struct Token
        property kind : TokenKind
        property start : Int32
        property length : Int32
        property trivia : Array(Trivia)

        def initialize(
          @kind : TokenKind,
          @start : Int32,
          @length : Int32,
          @trivia : Array(Trivia) = [] of Trivia,
        )
        end
      end
    end
  end
end
