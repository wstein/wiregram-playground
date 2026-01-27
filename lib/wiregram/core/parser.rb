# frozen_string_literal: true
# typed: false

module WireGram
  module Core
    # Base Parser - Foundation for parsing
    # Provides error recovery and resilient parsing
    class BaseParser
      extend T::Sig

      attr_reader :tokens, :position, :errors

      sig { params(tokens: T.any(TokenStream, T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]])).void }
      def initialize(tokens)
        @tokens = tokens
        @position = 0
        @errors = []
      end

      # Parse the tokens into an AST
      sig { returns(T.nilable(Node)) }
      def parse
        raise NotImplementedError, 'Subclasses must implement parse'
      end

      protected

      sig { returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
      def current_token
        @tokens[@position]
      end

      sig { params(offset: T.nilable(Integer)).returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
      def peek_token(offset = 1)
        @tokens[@position + offset]
      end

      sig { void }
      def advance
        @position += 1
        # Notify token source (if it's a streaming source) so it can drop consumed tokens
        @tokens.consume_to(@position) if @tokens.respond_to?(:consume_to)
      end

      sig { params(type: Symbol).returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
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

      sig { returns(T::Boolean) }
      def at_end?
        token = current_token
        token.nil? || token[:type] == :eof
      end

      # Synchronize after an error - find next safe point
      sig { void }
      def synchronize
        advance until at_end? || current_token[:type] == :semicolon
        advance unless at_end?
      end
    end
  end
end
