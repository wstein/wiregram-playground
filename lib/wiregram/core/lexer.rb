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
        @streaming = false
        @last_token = nil
      end

      # Public API to enable/disable streaming mode. When enabled, tokens are
      # returned directly and not stored in @tokens which avoids large memory
      # allocations during token streaming.
      def enable_streaming!
        @streaming = true
      end

      def disable_streaming!
        @streaming = false
      end

# Tokenize the source code eagerly (compatibility)
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
  def next_token
    skip_whitespace

    # If at end, return EOF token
    if @position >= @source.length
      token = { type: :eof, value: nil, position: @position }
      if @streaming
        @last_token = token
      else
        unless @tokens.last && @tokens.last[:type] == :eof
          @tokens << token
        end
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
        else
          return @tokens.last if @tokens.length > prev_len
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
      if @position >= @source.length
        token = { type: :eof, value: nil, position: @position }
        if @streaming
          @last_token = token
        else
          unless @tokens.last && @tokens.last[:type] == :eof
            @tokens << token
          end
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
    # Choose position semantics: value-like tokens point at their end (scanner.pos if available),
    # punctuation tokens point at their start (@position).
    if [:identifier, :keyword, :string, :number, :hex_number, :invalid_hex, :boolean, :null].include?(type)
      pos = defined?(@scanner) ? @scanner.pos : (@position + (value.is_a?(String) ? value.length : 1))
    else
      pos = @position
    end

    token = { type: type, value: value, position: pos }
    token.merge!(extras) if extras && !extras.empty?

    if ENV['DEBUG_LEXER']
      scanner_pos = defined?(@scanner) ? @scanner.pos : 'n/a'
      STDERR.puts "ADD_TOKEN: type=#{type} value=#{value.inspect} position=#{pos} scanner_pos=#{scanner_pos}"
    end

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
