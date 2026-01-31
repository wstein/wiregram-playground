# frozen_string_literal: true
# typed: false

# Ensure Sorbet runtime is available at load time to provide `T` and `T::Sig`.
begin
  require 'sorbet-runtime'
rescue LoadError
  # no-op: runtime not installed; runtime-only annotations will be no-ops
end

module WireGram
  module Core
    # Base Lexer - Foundation for tokenization
    # Provides error recovery and resilient tokenization
    class BaseLexer
      extend T::Sig

      attr_reader :source, :position, :tokens, :errors

      sig { params(source: String).void }
      def initialize(source)
        @source = T.let(source, String)
        @position = T.let(0, Integer)
        @tokens = T.let([], T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]])
        @errors = T.let([], T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Array[String])]])
        @streaming = T.let(false, T::Boolean)
        @last_token = T.let(nil, T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]))
      end

      # Public API to enable/disable streaming mode. When enabled, tokens are
      # returned directly and not stored in @tokens which avoids large memory
      # allocations during token streaming.
      def enable_streaming!
        @streaming = true
      end

      sig { void }
      def disable_streaming!
        @streaming = false
      end

      # Tokenize the source code eagerly (compatibility)
      sig { returns(T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]]) }
      def tokenize
        @tokens = []
        @errors = []
        @position = 0
        @streaming = false

        loop do
          token = next_token
          break if token && token[:type] == :eof
        end

        @tokens
      end

      # Produce the next token from the source on demand.
      # This enables lazy tokenization for parsers that request tokens incrementally.
      sig { returns(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]) }
      def next_token
        skip_whitespace

        # If at end, return EOF token
        if @position >= @source.length
          token = { type: :eof, value: nil, position: @position }
          if @streaming
            @last_token = token
          else
            @tokens << token unless @tokens.last && @tokens.last[:type] == :eof
          end
          return token
        end

        prev_len = @tokens.length
        @last_token = nil if @streaming

        # Keep trying until a token has been added (skip_comment may not add tokens)
        loop do
          if try_tokenize_next
            if @streaming
              return @last_token if @last_token
              # else loop and try again (e.g., comments were skipped)
            elsif @tokens.length > prev_len
              return @tokens.last
              # else loop and try again (e.g., comments were skipped)
            end
          else
            # Error recovery: skip character and report unknown
            @errors << {
              type: :unknown_character,
              char: current_char,
              position: @position
            }
            token = { type: :unknown, value: current_char, position: @position }
            advance
            if @streaming
              @last_token = token
            else
              @tokens << token
            end
            return token
          end

          # If we advanced to EOF while skipping, return EOF
          next unless @position >= @source.length

          token = { type: :eof, value: nil, position: @position }
          if @streaming
            @last_token = token
          else
            @tokens << token unless @tokens.last && @tokens.last[:type] == :eof
          end
          return token
        end
      end

      protected

      # To be implemented by subclasses
      sig { returns(T::Boolean) }
      def try_tokenize_next
        raise NotImplementedError, 'Subclasses must implement try_tokenize_next'
      end

      sig { returns(T.nilable(String)) }
      def current_char
        @source[@position]
      end

      sig { params(offset: T.nilable(Integer)).returns(T.nilable(String)) }
      def peek_char(offset = 1)
        @source[@position + offset]
      end

      sig { void }
      def advance
        @position += 1
      end

      sig { void }
      def skip_whitespace
        advance while current_char&.match?(/\s/)
      end

      sig { params(type: Symbol, value: T.untyped, extras: T.nilable(T::Hash[Symbol, T.untyped])).returns(T.untyped) }
      def add_token(type, value = nil, extras = {})
        token = { type: type, value: value, position: @position }
        token.merge!(extras) if extras && !extras.empty?
        if @streaming
          @last_token = token
        else
          @tokens << token
        end
        token
      end
    end
  end
end
