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
  end
end
