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
    @lexer_state : Lexer::LexerState

    # Create a new Parser.
    #
    # max_depth - maximum nesting depth allowed when parsing a document.
    def initialize(@max_depth : Int32 = DEFAULT_MAX_DEPTH)
      @lexer_state = Lexer::LexerState.new
    end

    def finalize
    end

    # Expose parser-controlled lexer state for coordinated transitions.
    def lexer_state : Lexer::LexerState
      @lexer_state
    end

    def push_state(state : Lexer::LexerState::State)
      @lexer_state.push(state)
    end

    def pop_state : Lexer::LexerState::State?
      @lexer_state.pop
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

      Lexer::TokenAssembler.each_token(bytes, lexer.buffer, @lexer_state, &block)
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
      validate_numbers : Bool = false,
      jsonc : Bool = false,
    ) : IR::Result
      if jsonc
        tokens, error = Lexer::TokenScanner.scan(bytes, true)
        return IR::Result.new(nil, error) unless error.success?

        core_tokens = jsonc_core_tokens(tokens)
        return IR::Result.new(nil, ErrorCode::TapeError) unless core_tokens

        return IR.parse_tokens(bytes, core_tokens, @max_depth, validate_literals, validate_numbers)
      end

      lexer = lexer_indexes(bytes, padded)
      return IR::Result.new(nil, lexer.error) unless lexer.error.success?

      IR.parse(bytes, lexer.buffer, @max_depth, validate_literals, validate_numbers)
    end

    # Parse the complete document and return a DOM value.
    #
    # This builds a bare DOM from the tape representation.
    def parse_dom(bytes : Bytes, padded : Bool = false, jsonc : Bool = false) : DOM::Result
      result = parse_document(bytes, padded, validate_literals: true, validate_numbers: true, jsonc: jsonc)
      return DOM::Result.new(nil, result.error) unless result.error.success?
      DOM::Builder.build(result.doc.not_nil!)
    end

    # Parse the complete document into a CST (supports JSONC when enabled).
    def parse_cst(bytes : Bytes, jsonc : Bool = false) : CST::Result
      CST::Parser.parse(bytes, jsonc)
    end

    # Parse the complete document into an AST derived from the CST.
    def parse_ast(bytes : Bytes, jsonc : Bool = false) : AST::Result
      cst_result = parse_cst(bytes, jsonc)
      return AST::Result.new(nil, cst_result.error) unless cst_result.error.success?
      AST::Result.new(AST::Builder.from_cst(cst_result.doc.not_nil!), ErrorCode::Success)
    end

    private def jsonc_core_tokens(tokens : Array(CST::Token)) : Array(Token)?
      core = [] of Token
      i = 0
      while i < tokens.size
        tok = tokens[i]
        case tok.kind
        when CST::TokenKind::LBrace
          core << Token.new(TokenType::StartObject, tok.start, tok.length)
        when CST::TokenKind::RBrace
          core << Token.new(TokenType::EndObject, tok.start, tok.length)
        when CST::TokenKind::LBracket
          core << Token.new(TokenType::StartArray, tok.start, tok.length)
        when CST::TokenKind::RBracket
          core << Token.new(TokenType::EndArray, tok.start, tok.length)
        when CST::TokenKind::Colon
          core << Token.new(TokenType::Colon, tok.start, tok.length)
        when CST::TokenKind::Comma
          j = i + 1
          while j < tokens.size
            next_kind = tokens[j].kind
            break unless [CST::TokenKind::Whitespace, CST::TokenKind::Newline, CST::TokenKind::CommentLine, CST::TokenKind::CommentBlock].includes?(next_kind)
            j += 1
          end
          if j < tokens.size && (tokens[j].kind == CST::TokenKind::RBrace || tokens[j].kind == CST::TokenKind::RBracket)
            # Skip trailing comma in JSONC.
          else
            core << Token.new(TokenType::Comma, tok.start, tok.length)
          end
        when CST::TokenKind::Newline
          core << Token.new(TokenType::Newline, tok.start, tok.length)
        when CST::TokenKind::String
          core << Token.new(TokenType::String, tok.start, tok.length)
        when CST::TokenKind::Number
          core << Token.new(TokenType::Number, tok.start, tok.length)
        when CST::TokenKind::True
          core << Token.new(TokenType::True, tok.start, tok.length)
        when CST::TokenKind::False
          core << Token.new(TokenType::False, tok.start, tok.length)
        when CST::TokenKind::Null
          core << Token.new(TokenType::Null, tok.start, tok.length)
        when CST::TokenKind::Whitespace, CST::TokenKind::CommentLine, CST::TokenKind::CommentBlock, CST::TokenKind::Eof
          # skip
        else
          return nil
        end
        i += 1
      end
      core
    end

    private def lexer_indexes(bytes : Bytes, _padded : Bool) : LexerResult
      lexer_fallback(bytes)
    end

    private def lexer_fallback(bytes : Bytes) : LexerResult
      @lexer_state.reset
      Lexer.index(bytes, @lexer_state)
    end
  end
end
