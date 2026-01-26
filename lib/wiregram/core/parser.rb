# frozen_string_literal: true

module WireGram
  module Core
    # Base Parser - Foundation for parsing
    # Provides error recovery and resilient parsing
    class BaseParser
      attr_reader :tokens, :position, :errors

      def initialize(tokens)
        @tokens = tokens
        @position = 0
        @errors = []
      end

      # Parse the tokens into an AST
      def parse
        raise NotImplementedError, 'Subclasses must implement parse'
      end

      protected

      def current_token
        @tokens[@position]
      end

      def peek_token(offset = 1)
        @tokens[@position + offset]
      end

      def advance
        @position += 1
        # Notify token source (if it's a streaming source) so it can drop consumed tokens
        @tokens.consume_to(@position) if @tokens.respond_to?(:consume_to)
      end

      def expect(type)
        token = current_token
        if token && token[:type] == type
          advance
          token
        else
          # Error recovery
          @errors << {
            type: :unexpected_token,
            expected: type,
            got: token ? token[:type] : :eof,
            position: token ? token[:position] : @position
          }
          nil
        end
      end

      def at_end?
        token = current_token
        token.nil? || token[:type] == :eof
      end

      # Synchronize after an error - find next safe point
      def synchronize
        advance until at_end? || current_token[:type] == :semicolon
        advance unless at_end?
      end
    end
  end
end
