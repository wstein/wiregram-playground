# frozen_string_literal: true
# typed: false

begin
  require 'sorbet-runtime'
rescue LoadError
end

module WireGram
  module Core
    # TokenStream provides lazy access to tokens produced by a lexer
    # It requests tokens from the lexer on demand and caches them.
    class TokenStream
      extend T::Sig

      sig { params(lexer: BaseLexer).void }
      def initialize(lexer)
        @lexer = lexer
        @cache = []
        @eof_produced = false
      end

      # Array-like access for parser compatibility
      sig { params(index: Integer).returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
      def [](index)
        ensure_filled(index)
        @cache[index]
      end

      sig { returns(Integer) }
      def length
        ensure_all
        @cache.length
      end

      # Returns all tokens (forces complete tokenization)
      sig { returns(T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]]) }
      def tokens
        ensure_all
        @cache
      end

      private

      sig { params(index: Integer).void }
      def ensure_filled(index)
        while @cache.length <= index && !@eof_produced
          token = @lexer.next_token
          @cache << token
          @eof_produced = true if token[:type] == :eof
        end
      end

      sig { void }
      def ensure_all
        ensure_filled(0) unless @cache.any?
        until @eof_produced
          token = @lexer.next_token
          @cache << token
          @eof_produced = true if token[:type] == :eof
        end
      end
    end

    # StreamingTokenStream is a lightweight token source for streaming parsers.
    # It avoids accumulating all tokens in memory by keeping a small sliding window
    # buffer and driving the lexer directly.
    class StreamingTokenStream
      extend T::Sig

      sig { params(lexer: BaseLexer, buffer_size: T.nilable(Integer)).void }
      def initialize(lexer, buffer_size = 8)
        @lexer = lexer
        @base = 0
        @buffer = []
        @eof = false
        @buffer_size = buffer_size
      end

      # Array-like access (absolute index). Only supports forward access.
      sig { params(index: Integer).returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
      def [](index)
        return nil if index < @base

        rel = index - @base
        while !@eof && @buffer.length <= rel
          token = @lexer.next_token
          # Defensive: if lexer unexpectedly returns nil, treat it as EOF
          token = { type: :eof, value: nil, position: @base + @buffer.length } if token.nil?
          @buffer << token
          @eof = true if token[:type] == :eof
        end
        @buffer[rel]
      end

      # Allow parser to inform the stream to drop consumed tokens
      sig { params(position: Integer).void }
      def consume_to(position)
        return if position <= @base

        drop = position - @base
        return unless drop.positive?

        @buffer.shift(drop)
        @base += drop
      end

      # Convenience: fetch next token and advance base
      sig { returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
      def next
        token = self[@base]
        consume_to(@base + 1)
        token
      end
    end
  end
end
