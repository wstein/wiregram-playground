module Warp
  # Parser offers a convenient front-end to the lexer + IR parsing pipeline.
  #
  # Use `each_token` to iterate tokens with zero-copy slices into the
  # provided `Bytes`. Use `parse_document` to build an `IR::Document`.
  #
  # Parameters:
  # - `max_depth` limits nested object/array depth for `parse_document`.
  class Parser
    alias ErrorCode = Core::ErrorCode
    alias Token = Core::Token
    alias TokenType = Core::TokenType
    alias LexerBuffer = Core::LexerBuffer
    alias LexerResult = Core::LexerResult

    DEFAULT_MAX_DEPTH = 1024

    @max_depth : Int32

    # Create a new Parser.
    #
    # max_depth - maximum nesting depth allowed when parsing a document.
    def initialize(@max_depth : Int32 = DEFAULT_MAX_DEPTH)
    end

    def finalize
    end

    # Iterate tokens found in `bytes` in structural order.
    #
    # Yields `Token` objects to the provided block. Returns an `ErrorCode`.
    # The `bytes` argument should be a `Bytes` slice of the JSON input.
    # If `padded` is true the input is assumed to have additional padding
    # bytes at the end (used by some SIMD backends); currently unused by
    # the fallback lexer implementation.
    def each_token(bytes : Bytes, padded : Bool = false, &block : Token ->) : ErrorCode
      lexer = lexer_indexes(bytes, padded)
      return lexer.error unless lexer.error.success?

      iterate_tokens(bytes, lexer.buffer, &block)
    end

    # Parse the complete document and return an `IR::Result` with
    # either a `Document` and `ErrorCode::Success` or an error code.
    #
    # Options:
    # - `validate_literals` — when true, validate `true`, `false`, `null` tokens.
    # - `validate_numbers` — when true, validate number syntax strictly.
    def parse_document(
      bytes : Bytes,
      padded : Bool = false,
      validate_literals : Bool = false,
      validate_numbers : Bool = false
    ) : IR::Result
      lexer = lexer_indexes(bytes, padded)
      return IR::Result.new(nil, lexer.error) unless lexer.error.success?

      IR.parse(bytes, lexer.buffer, @max_depth, validate_literals, validate_numbers)
    end

    private def lexer_indexes(bytes : Bytes, _padded : Bool) : LexerResult
      lexer_fallback(bytes)
    end

    private def iterate_tokens(bytes : Bytes, buffer : LexerBuffer, &block : Token ->) : ErrorCode
      len = bytes.size
      idx_ptr = buffer.ptr
      count = buffer.count

      i = 0
      while i < count
        idx = idx_ptr[i].to_i
        next_idx = i + 1 < count ? idx_ptr[i + 1].to_i : -1
        c = bytes[idx]
        case c
        when '{'.ord
          yield Token.new(TokenType::StartObject, idx, 1)
        when '}'.ord
          yield Token.new(TokenType::EndObject, idx, 1)
        when '['.ord
          yield Token.new(TokenType::StartArray, idx, 1)
        when ']'.ord
          yield Token.new(TokenType::EndArray, idx, 1)
        when ':'.ord
          yield Token.new(TokenType::Colon, idx, 1)
        when ','.ord
          yield Token.new(TokenType::Comma, idx, 1)
        when '\n'.ord
          yield Token.new(TokenType::Newline, idx, 1)
        when '\r'.ord
          # Coalesce CRLF into a single newline token.
          if idx + 1 < len && bytes[idx + 1] == '\n'.ord
            yield Token.new(TokenType::Newline, idx, 2)
            i += 1 if next_idx == idx + 1
          else
            yield Token.new(TokenType::Newline, idx, 1)
          end
        when '"'.ord
          start = idx + 1
          end_idx = IR.scan_string_end(bytes, start, next_idx)
          return ErrorCode::UnclosedString if end_idx < 0
          yield Token.new(TokenType::String, start, end_idx - start)
        else
          start = idx
          end_idx = IR.scan_scalar_end(bytes, start, next_idx)
          tok_type = scalar_type(bytes[start])
          yield Token.new(tok_type, start, end_idx - start)
        end
        i += 1
      end

      ErrorCode::Success
    end

    private def lexer_fallback(bytes : Bytes) : LexerResult
      Lexer.index(bytes)
    end

    private def scalar_type(first_byte : UInt8) : TokenType
      case first_byte
      when 't'.ord
        TokenType::True
      when 'f'.ord
        TokenType::False
      when 'n'.ord
        TokenType::Null
      else
        TokenType::Number
      end
    end

  end
end
