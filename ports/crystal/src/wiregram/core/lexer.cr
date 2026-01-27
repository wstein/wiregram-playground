# frozen_string_literal: true

require "./token"

module WireGram
  module Core
    # Base Lexer - Foundation for tokenization
    # Provides error recovery and resilient tokenization
    class BaseLexer
      getter source : String
      getter position : Int32
      getter tokens : Array(Token)
      getter errors : Array(Hash(Symbol, String | Int32 | TokenType | Symbol | Nil))
      getter last_token : Token | Nil

      def initialize(@source : String)
        @bytes = @source.to_slice
        @position = 0
        @tokens = [] of Token
        @errors = [] of Hash(Symbol, String | Int32 | TokenType | Symbol | Nil)
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
      def tokenize : Array(Token)
        @tokens = [] of Token
        @errors = [] of Hash(Symbol, String | Int32 | TokenType | Symbol | Nil)
        @position = 0
        @streaming = false

        loop do
          token = next_token
          break if token.type == TokenType::Eof
        end

        @tokens
      end

      # Produce the next token from the source on demand.
      # This enables lazy tokenization for parsers that request tokens incrementally.
      def next_token : Token
        skip_whitespace

        # If at end, return EOF token
        if @position >= @bytes.size
          token = Token.new(TokenType::Eof, nil, @position)
          if @streaming
            @last_token = token
          else
            @tokens << token unless @tokens.last? && @tokens.last.type == TokenType::Eof
          end
          return token
        end

        prev_len = @tokens.size
        @last_token = nil if @streaming

        # Keep trying until a token has been added (skip_comment may not add tokens)
        loop do
          if try_tokenize_next
            if @streaming
              return @last_token.not_nil! if @last_token
            elsif @tokens.size > prev_len
              return @tokens.last
            end
          else
            # Error recovery: skip character and report unknown
            error = {} of Symbol => String | Int32 | TokenType | Symbol | Nil
            error[:type] = "unknown_character"
            error[:char] = current_char
            error[:position] = @position
            @errors << error
            token = Token.new(TokenType::Unknown, current_char, @position)
            advance
            if @streaming
              @last_token = token
            else
              @tokens << token
            end
            return token
          end

          # If we advanced to EOF while skipping, return EOF
          next unless @position >= @bytes.size

          token = Token.new(TokenType::Eof, nil, @position)
          if @streaming
            @last_token = token
          else
            @tokens << token unless @tokens.last? && @tokens.last.type == TokenType::Eof
          end
          return token
        end
      end

      # To be implemented by subclasses
      private def try_tokenize_next : Bool
        raise "Subclasses must implement try_tokenize_next"
      end

      def current_char : String?
        return nil if @position >= @bytes.size
        @source.byte_slice(@position, 1)
      end

      def peek_char(offset = 1) : String?
        pos = @position + offset
        return nil if pos >= @bytes.size
        @source.byte_slice(pos, 1)
      end

      def current_byte : UInt8?
        return nil if @position >= @bytes.size
        @bytes[@position]
      end

      def peek_byte(offset = 1) : UInt8?
        pos = @position + offset
        return nil if pos >= @bytes.size
        @bytes[pos]
      end

      def advance
        @position += 1
      end

      def skip_whitespace
        while (byte = current_byte)
          case byte
          when 0x20, 0x09, 0x0a, 0x0d, 0x0b, 0x0c
            advance
          else
            break
          end
        end
      end

      def add_token(type : TokenType, value : TokenValue = nil, extras : Hash(Symbol, TokenExtraValue)? = nil, position : Int32? = nil) : Token
        token_pos = position || @position
        token = Token.new(type, value, token_pos, extras)
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
