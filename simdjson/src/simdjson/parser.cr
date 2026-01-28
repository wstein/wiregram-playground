module Simdjson
  # Parser offers a convenient front-end to the two-stage parsing pipeline.
  #
  # Use `each_token` to iterate tokens with zero-copy slices into the
  # provided `Bytes`. Use `parse_document` to build a `Stage2::Document`.
  #
  # Parameters:
  # - `max_depth` limits nested object/array depth for `parse_document`.
  class Parser
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
    # the fallback stage1 implementation.
    def each_token(bytes : Bytes, padded : Bool = false, &block : Token ->) : ErrorCode
      stage1 = stage1_indexes(bytes, padded)
      return stage1.error unless stage1.error.success?

      iterate_tokens(bytes, stage1.buffer, &block)
    end

    # Parse the complete document and return a `Stage2::Result` with
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
    ) : Stage2::Result
      stage1 = stage1_indexes(bytes, padded)
      return Stage2::Result.new(nil, stage1.error) unless stage1.error.success?

      Stage2.parse(bytes, stage1.buffer, @max_depth, validate_literals, validate_numbers)
    end

    private def stage1_indexes(bytes : Bytes, _padded : Bool) : Stage1Result
      stage1_fallback(bytes)
    end

    private def iterate_tokens(bytes : Bytes, buffer : Stage1Buffer, &block : Token ->) : ErrorCode
      ptr = bytes.to_unsafe
      len = bytes.size
      idx_ptr = buffer.ptr
      count = buffer.count

      i = 0
      while i < count
        idx = idx_ptr[i].to_i
        c = ptr[idx]
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
        when '"'.ord
          start = idx + 1
          end_idx = scan_string_end(ptr, len, start)
          return ErrorCode::UnclosedString if end_idx < 0
          yield Token.new(TokenType::String, start, end_idx - start)
        else
          start = idx
          end_idx = scan_scalar_end(ptr, len, start)
          tok_type = scalar_type(ptr[start])
          yield Token.new(tok_type, start, end_idx - start)
        end
        i += 1
      end

      ErrorCode::Success
    end

    private def stage1_fallback(bytes : Bytes) : Stage1Result
      result = Stage1.index(bytes)
      buffer = Stage1Buffer.new(result.indices.to_unsafe, result.indices.size, result.indices)
      Stage1Result.new(buffer, result.error)
    end

    private def scan_string_end(ptr : Pointer(UInt8), len : Int32, start : Int32) : Int32
      i = start
      escaped = false
      while i < len
        c = ptr[i]
        if escaped
          escaped = false
        elsif c == '\\'.ord
          escaped = true
        elsif c == '"'.ord
          return i
        end
        i += 1
      end
      -1
    end

    private def scan_scalar_end(ptr : Pointer(UInt8), len : Int32, start : Int32) : Int32
      i = start + 1
      while i < len
        c = ptr[i]
        break if c == ' '.ord || c == '\t'.ord || c == '\n'.ord || c == '\r'.ord ||
                 c == ','.ord || c == ']'.ord || c == '}'.ord || c == ':'.ord
        i += 1
      end
      i
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
