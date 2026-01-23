# frozen_string_literal: true

module WireGram
  module Core
    # Base Lexer - Foundation for tokenization
    # Provides error recovery and resilient tokenization
    class BaseLexer
      attr_reader :source, :position, :tokens, :errors

      def initialize(source)
        @source = source
        @position = 0
        @tokens = []
        @errors = []
      end

      # Tokenize the source code
      def tokenize
        @tokens = []
        @errors = []
        @position = 0

        while @position < @source.length
          skip_whitespace
          break if @position >= @source.length

          unless try_tokenize_next
            # Error recovery: skip character and continue
            @errors << { 
              type: :unknown_character, 
              char: current_char, 
              position: @position 
            }
            advance
          end
        end

        @tokens << { type: :eof, value: nil, position: @position }
        @tokens
      end

      protected

      # To be implemented by subclasses
      def try_tokenize_next
        raise NotImplementedError, "Subclasses must implement try_tokenize_next"
      end

      def current_char
        @source[@position]
      end

      def peek_char(offset = 1)
        @source[@position + offset]
      end

      def advance
        @position += 1
      end

      def skip_whitespace
        advance while current_char&.match?(/\s/)
      end

      def add_token(type, value = nil)
        @tokens << { type: type, value: value, position: @position }
      end
    end
  end
end
