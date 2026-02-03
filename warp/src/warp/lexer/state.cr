module Warp
  module Lexer
    # LexerState provides a lightweight stack-based state machine that
    # callers (parser or lexer) can use to coordinate lexing context.
    class LexerState
      enum State
        Root
        ObjectKey
        ObjectValue
        ArrayElement
        String
        StringEscape
        Comment
        Regex
        Heredoc
        Macro
        Annotation
      end

      property stack : Array(State) = [] of State

      def current : State
        stack.last? || State::Root
      end

      def push(state : State)
        stack << state
      end

      def pop : State?
        stack.pop?
      end

      def reset
        stack.clear
      end

      def in_string? : Bool
        current == State::String || current == State::StringEscape
      end
    end
  end
end
