# frozen_string_literal: true

require "./token"
require "./token_stream"

module WireGram
  module Core
    alias TokenSource = Array(Token) | TokenStream | StreamingTokenStream

    # Base Parser - Foundation for parsing
    # Provides error recovery and resilient parsing
    class BaseParser
      @tokens : TokenSource
      getter tokens
      getter position : Int32
      getter errors : Array(Hash(Symbol, String | Int32 | TokenType | Symbol | Nil))

      def initialize(tokens : TokenSource)
        @tokens = tokens
        @position = 0
        @errors = [] of Hash(Symbol, String | Int32 | TokenType | Symbol | Nil)
      end

      # Parse the tokens into an AST
      def parse
        raise "Subclasses must implement parse"
      end

      private def current_token : Token?
        token_at(@position)
      end

      def peek_token(offset = 1) : Token?
        token_at(@position + offset)
      end

      private def token_at(index : Int32) : Token?
        tokens = @tokens
        case tokens
        when Array(Token)
          tokens[index]?
        else
          tokens[index]
        end
      end

      def advance
        @position += 1
        # Notify token source (if it's a streaming source) so it can drop consumed tokens
        if @tokens.is_a?(WireGram::Core::StreamingTokenStream)
          streaming = @tokens.as(WireGram::Core::StreamingTokenStream)
          streaming.consume_to(@position)
        end
      end

      def expect(type : TokenType) : Token?
        token = current_token
        if token && token.type == type
          advance
          token
        else
          # Error recovery
          error = {} of Symbol => String | Int32 | TokenType | Symbol | Nil
          error[:type] = "unexpected_token"
          error[:expected] = type
          error[:got] = token ? token.type : WireGram::Core::TokenType::Eof
          error[:position] = token ? token.position : @position
          @errors << error
          nil
        end
      end

      def expect(type : Symbol) : Token?
        expect(TokenType.from_symbol(type))
      end

      def at_end? : Bool
        token = current_token
        token.nil? || token.type == WireGram::Core::TokenType::Eof
      end

      # Synchronize after an error - find next safe point
      def synchronize
        token = current_token
        until at_end? || (token && token.type == WireGram::Core::TokenType::Semicolon)
          advance
          token = current_token
        end
        advance unless at_end?
      end
    end
  end
end
