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

      Lexer::TokenAssembler.each_token(bytes, lexer.buffer, &block)
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

    # Parse the complete document and return a DOM value.
    #
    # This builds a bare DOM from the tape representation.
    def parse_dom(bytes : Bytes, padded : Bool = false) : DOM::Result
      result = parse_document(bytes, padded, validate_literals: true, validate_numbers: true)
      return DOM::Result.new(nil, result.error) unless result.error.success?
      DOM::Builder.build(result.doc.not_nil!)
    end

    private def lexer_indexes(bytes : Bytes, _padded : Bool) : LexerResult
      lexer_fallback(bytes)
    end

    private def lexer_fallback(bytes : Bytes) : LexerResult
      Lexer.index(bytes)
    end

  end
end
