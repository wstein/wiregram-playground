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

# Tokenize the source code eagerly (compatibility)
  def tokenize
    @tokens = []
    @errors = []
    @position = 0

    loop do
      token = next_token
      break if token && token[:type] == :eof
    end

    @tokens
  end

  # Produce the next token from the source on demand.
  # This enables lazy tokenization for parsers that request tokens incrementally.
  def next_token
    skip_whitespace

    # If at end, return EOF token
    if @position >= @source.length
      token = { type: :eof, value: nil, position: @position }
      unless @tokens.last && @tokens.last[:type] == :eof
        @tokens << token
      end
      return token
    end

    prev_len = @tokens.length

    # Keep trying until a token has been added (skip_comment may not add tokens)
    loop do
      if try_tokenize_next
        # If a token was added, return it
        return @tokens.last if @tokens.length > prev_len
        # else loop and try again (e.g., comments were skipped)
      else
        # Error recovery: skip character and report unknown
        @errors << {
          type: :unknown_character,
          char: current_char,
          position: @position
        }
        token = { type: :unknown, value: current_char, position: @position }
        advance
        @tokens << token
        return token
      end

      # If we advanced to EOF while skipping, return EOF
      if @position >= @source.length
        token = { type: :eof, value: nil, position: @position }
        unless @tokens.last && @tokens.last[:type] == :eof
          @tokens << token
        end
        return token
      end
    end
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

  def add_token(type, value = nil, extras = {})
    token = { type: type, value: value, position: @position }
    token.merge!(extras) if extras && !extras.empty?
    @tokens << token
  end
end
  end
end
