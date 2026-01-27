# frozen_string_literal: true

require "./token"

module WireGram
  module Core
    # TokenStream provides lazy access to tokens produced by a lexer
    # It requests tokens from the lexer on demand and caches them.
    class TokenStream
      @lexer : BaseLexer
      @cache : Array(Token)
      @eof_produced : Bool

      def initialize(lexer : BaseLexer)
        @lexer = lexer
        @cache = [] of Token
        @eof_produced = false
      end

      # Array-like access for parser compatibility
      def [](index : Int32)
        ensure_filled(index)
        @cache[index]?
      end

      def length : Int32
        ensure_all
        @cache.size
      end

      # Returns all tokens (forces complete tokenization)
      def tokens : Array(Token)
        ensure_all
        @cache
      end

      private def ensure_filled(index : Int32)
        while @cache.size <= index && !@eof_produced
          token = @lexer.next_token
          @cache << token
          @eof_produced = true if token.type == WireGram::Core::TokenType::Eof
        end
      end

      def ensure_all
        ensure_filled(0) unless @cache.any?
        until @eof_produced
          token = @lexer.next_token
          @cache << token
          @eof_produced = true if token.type == WireGram::Core::TokenType::Eof
        end
      end
    end

    # StreamingTokenStream is a lightweight token source for streaming parsers.
    # It avoids accumulating all tokens in memory by keeping a small sliding window
    # buffer and driving the lexer directly.
    class StreamingTokenStream
      @lexer : BaseLexer
      @base : Int32
      @buffer : Array(Token)
      @eof : Bool
      @buffer_size : Int32

      def initialize(@lexer : BaseLexer, @buffer_size : Int32 = 8)
        @base = 0
        @buffer = [] of Token
        @eof = false
      end

      # Array-like access (absolute index). Only supports forward access.
      def [](index : Int32)
        return nil if index < @base

        rel = index - @base
        while !@eof && @buffer.size <= rel
          token = @lexer.next_token
          # Defensive: if lexer unexpectedly returns nil, treat it as EOF
          token = Token.new(TokenType::Eof, nil, @base + @buffer.size) if token.nil?
          @buffer << token
          @eof = true if token.type == TokenType::Eof
        end
        @buffer[rel]?
      end

      # Safe access (returns nil if out of bounds)
      def []?(index : Int32)
        self[index]
      end

      # Allow parser to inform the stream to drop consumed tokens
      def consume_to(position : Int32)
        return if position <= @base

        drop = position - @base
        return unless drop.positive?

        @buffer.shift(drop)
        @base += drop
      end

      # Convenience: fetch next token and advance base
      def next
        token = self[@base]
        consume_to(@base + 1)
        token
      end
    end
  end
end
