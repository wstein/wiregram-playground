# frozen_string_literal: true

module WireGram
  module Core
    # TokenStream provides lazy access to tokens produced by a lexer
    # It requests tokens from the lexer on demand and caches them.
    class TokenStream
      def initialize(lexer)
        @lexer = lexer
        @cache = []
        @eof_produced = false
      end

      # Array-like access for parser compatibility
      def [](index)
        ensure_filled(index)
        @cache[index]
      end

      def length
        ensure_all
        @cache.length
      end

      # Returns all tokens (forces complete tokenization)
      def tokens
        ensure_all
        @cache
      end

      private

      def ensure_filled(index)
        while @cache.length <= index && !@eof_produced
          token = @lexer.next_token
          @cache << token
          @eof_produced = true if token[:type] == :eof
        end
      end

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
      def initialize(lexer, buffer_size = 8)
        @lexer = lexer
        @base = 0
        @buffer = []
        @eof = false
        @buffer_size = buffer_size
      end

      # Array-like access (absolute index). Only supports forward access.
      def [](index)
        return nil if index < @base
        rel = index - @base
        while !@eof && @buffer.length <= rel
          token = @lexer.next_token
          @buffer << token
          @eof = true if token[:type] == :eof
        end
        @buffer[rel]
      end

      # Allow parser to inform the stream to drop consumed tokens
      def consume_to(position)
        return if position <= @base
        drop = position - @base
        if drop > 0
          @buffer.shift(drop)
          @base += drop
        end
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
