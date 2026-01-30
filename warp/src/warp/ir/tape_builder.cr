# IR: Tape builder and document representation
#
# Summary
#
# Converts the structural indices (from the lexer) into a compact "tape"
# representation that is efficient to traverse. The tape stores typed
# entries (strings, numbers, structural markers) and supports iteration
# and slicing into the original `Bytes` buffer.
#
# See `IR::Builder` for how the tape is constructed and `Document`
# / `TapeIterator` for traversal utilities.
module Warp
  module IR
    alias ErrorCode = Core::ErrorCode
    alias LexerBuffer = Core::LexerBuffer
    alias Token = Core::Token
    alias TokenType = Core::TokenType
    # TapeType enumerates kinds of entries stored on the tape.
    enum TapeType
      Root
      StartObject
      EndObject
      StartArray
      EndArray
      Key
      String
      Number
      True
      False
      Null
    end

    # Entry represents a single tape record with a type and two integer
    # fields. For string/number/atom entries `a` and `b` encode slice
    # offsets/lengths; for containers they encode index links.
    struct Entry
      getter type : TapeType
      getter a : Int32
      getter b : Int32

      def initialize(@type : TapeType, @a : Int32, @b : Int32)
      end
    end

    alias Record = Entry
    alias Tape = Array(Entry)

    # Document wraps the original bytes and the tape produced by the
    # parser. Use `Document#iterator` or `Document#each_entry` to walk
    # the tape. `TapeIterator#slice(entry)` returns a `Bytes` slice for
    # scalar entries.
    class Document
      getter bytes : Bytes
      getter tape : Tape

      def initialize(@bytes : Bytes, @tape : Tape)
      end

      def iterator : TapeIterator
        TapeIterator.new(self)
      end

      def each_entry(&block : Entry ->) : Nil
        iterator.each do |entry|
          yield entry
        end
      end
    end

    # Result wraps an optional `Document` and an `ErrorCode` returned by
    # `IR.parse`.
    struct Result
      getter doc : Document?
      getter error : ErrorCode

      def initialize(@doc : Document?, @error : ErrorCode)
      end
    end

    # Parsing context for nested structures.
    enum ContextKind
      Object
      Array
    end

    enum ContextState
      ObjectKey
      ObjectColon
      ObjectValue
      ObjectCommaOrEnd
      ArrayValue
      ArrayCommaOrEnd
    end

    struct Context
      property kind : ContextKind
      property state : ContextState

      def initialize(@kind : ContextKind, @state : ContextState)
      end
    end

    struct OpenContainer
      property tape_index : Int32
      property count : Int32
      property is_array : Bool

      def initialize(@tape_index : Int32, @count : Int32, @is_array : Bool)
      end
    end

    # Builder incrementally constructs the tape. It is used internally by
    # `IR.parse` but documented here for completeness.
    class Builder
      getter tape : Array(Entry)

      def initialize(@bytes : Bytes, @validate_literals : Bool, @validate_numbers : Bool, expected_structurals : Int32)
        # Preallocate tape near structural count to reduce growth checks.
        @tape = Array(Entry).new(expected_structurals + 4)
        @open = Array(OpenContainer).new
      end

      def start_object
        @open << OpenContainer.new(@tape.size, 0, false)
        @tape << Entry.new(TapeType::StartObject, 0, 0)
      end

      def start_array
        @open << OpenContainer.new(@tape.size, 0, true)
        @tape << Entry.new(TapeType::StartArray, 0, 0)
      end

      def empty_object
        start_index = @tape.size
        @tape << Entry.new(TapeType::StartObject, 0, start_index + 1)
        @tape << Entry.new(TapeType::EndObject, start_index, 0)
      end

      def empty_array
        start_index = @tape.size
        @tape << Entry.new(TapeType::StartArray, 0, start_index + 1)
        @tape << Entry.new(TapeType::EndArray, start_index, 0)
      end

      def end_object
        container = @open.pop
        start_index = container.tape_index
        end_index = @tape.size
        @tape[start_index] = Entry.new(TapeType::StartObject, container.count, end_index)
        @tape << Entry.new(TapeType::EndObject, start_index, 0)
      end

      def end_array
        container = @open.pop
        start_index = container.tape_index
        end_index = @tape.size
        @tape[start_index] = Entry.new(TapeType::StartArray, container.count, end_index)
        @tape << Entry.new(TapeType::EndArray, start_index, 0)
      end

      def increment_count
        if @open.size > 0
          @open[@open.size - 1].count += 1
        end
      end

      def key(start_index : Int32, next_struct : Int32) : ErrorCode
        string_entry(start_index, TapeType::Key, next_struct)
      end

      def string(start_index : Int32, next_struct : Int32) : ErrorCode
        string_entry(start_index, TapeType::String, next_struct)
      end

      def primitive(start_index : Int32, next_struct : Int32) : ErrorCode
        first = @bytes[start_index]
        end_index = IR.scan_scalar_end(@bytes, start_index, next_struct)
        length = end_index - start_index

        case first
        when 't'.ord
          if @validate_literals && !IR.valid_true?(@bytes, start_index, length)
            return ErrorCode::TAtomError
          end
          @tape << Entry.new(TapeType::True, start_index, length)
        when 'f'.ord
          if @validate_literals && !IR.valid_false?(@bytes, start_index, length)
            return ErrorCode::FAtomError
          end
          @tape << Entry.new(TapeType::False, start_index, length)
        when 'n'.ord
          if @validate_literals && !IR.valid_null?(@bytes, start_index, length)
            return ErrorCode::NAtomError
          end
          @tape << Entry.new(TapeType::Null, start_index, length)
        else
          if @validate_numbers && !IR.valid_number?(@bytes, start_index, length)
            return ErrorCode::NumberError
          end
          @tape << Entry.new(TapeType::Number, start_index, length)
        end

        ErrorCode::Success
      end

      def key_token(token : Token) : ErrorCode
        @tape << Entry.new(TapeType::Key, token.start, token.length)
        ErrorCode::Success
      end

      def string_token(token : Token) : ErrorCode
        @tape << Entry.new(TapeType::String, token.start, token.length)
        ErrorCode::Success
      end

      def primitive_token(token : Token) : ErrorCode
        case token.type
        when TokenType::True
          if @validate_literals && !IR.valid_true?(@bytes, token.start, token.length)
            return ErrorCode::TAtomError
          end
          @tape << Entry.new(TapeType::True, token.start, token.length)
        when TokenType::False
          if @validate_literals && !IR.valid_false?(@bytes, token.start, token.length)
            return ErrorCode::FAtomError
          end
          @tape << Entry.new(TapeType::False, token.start, token.length)
        when TokenType::Null
          if @validate_literals && !IR.valid_null?(@bytes, token.start, token.length)
            return ErrorCode::NAtomError
          end
          @tape << Entry.new(TapeType::Null, token.start, token.length)
        when TokenType::Number
          if @validate_numbers && !IR.valid_number?(@bytes, token.start, token.length)
            return ErrorCode::NumberError
          end
          @tape << Entry.new(TapeType::Number, token.start, token.length)
        else
          return ErrorCode::TapeError
        end

        ErrorCode::Success
      end

      def root_entry(root_index : Int32)
        @tape << Entry.new(TapeType::Root, root_index, 0)
      end

      private def string_entry(start_index : Int32, type : TapeType, next_struct : Int32) : ErrorCode
        end_index = IR.scan_string_end(@bytes, start_index + 1, next_struct)
        return ErrorCode::UnclosedString if end_index < 0
        @tape << Entry.new(type, start_index + 1, end_index - (start_index + 1))
        ErrorCode::Success
      end
    end

    # Iterator over tokens returned by Stage1b.
    class TokenIterator
      def initialize(@tokens : Array(Token))
        @pos = 0
      end

      def at_eof? : Bool
        @pos >= @tokens.size
      end

      def peek_significant : Token?
        i = @pos
        while i < @tokens.size
          tok = @tokens[i]
          return tok unless tok.type == TokenType::Newline
          i += 1
        end
        nil
      end

      def advance_significant : Token?
        while @pos < @tokens.size
          tok = @tokens[@pos]
          @pos += 1
          return tok unless tok.type == TokenType::Newline
        end
        nil
      end

      def remaining_significant : Int32
        count = 0
        i = @pos
        while i < @tokens.size
          count += 1 unless @tokens[i].type == TokenType::Newline
          i += 1
        end
        count
      end
    end

    # Iterator over structural indices returned by the lexer.
    class Iterator
      def initialize(@bytes : Bytes, buffer : LexerBuffer)
        @indices = buffer.ptr
        @count = buffer.count
        @pos = 0
      end

      def at_eof? : Bool
        @pos >= @count
      end

      def peek_byte : UInt8
        return 0_u8 if at_eof?
        @bytes[@indices[@pos]]
      end

      def peek_index : Int32
        return -1 if at_eof?
        @indices[@pos].to_i
      end

      def advance_index : Int32
        return -1 if at_eof?
        idx = @indices[@pos].to_i
        @pos += 1
        idx
      end

      def peek_significant_byte : UInt8
        idx = peek_significant_index
        return 0_u8 if idx < 0
        @bytes[idx]
      end

      def peek_significant_index : Int32
        i = @pos
        while i < @count
          idx = @indices[i].to_i
          b = @bytes[idx]
          return idx unless b == '\n'.ord || b == '\r'.ord
          i += 1
        end
        -1
      end

      def advance_significant_index : Int32
        skip_newlines
        return -1 if at_eof?
        idx = @indices[@pos].to_i
        @pos += 1
        idx
      end

      @[NoInline]
      def remaining_structurals : Int32
        remaining = @count - @pos
        remaining
      end

      def remaining_significant_structurals : Int32
        count = 0
        i = @pos
        while i < @count
          idx = @indices[i].to_i
          b = @bytes[idx]
          count += 1 unless b == '\n'.ord || b == '\r'.ord
          i += 1
        end
        count
      end

      def last_structural_byte : UInt8
        return 0_u8 if @count == 0
        @bytes[@indices[@count - 1]]
      end

      private def skip_newlines
        while @pos < @count
          b = @bytes[@indices[@pos]]
          break unless b == '\n'.ord || b == '\r'.ord
          @pos += 1
        end
      end
    end

    # TapeIterator provides sequential access over the built tape and a
    # helper to extract slices for scalar entries.
    class TapeIterator
      def initialize(@doc : Document)
        @index = 0
      end

      def next_entry : Entry?
        tape = @doc.tape
        return nil if @index >= tape.size
        entry = tape[@index]
        @index += 1
        entry
      end

      def reset
        @index = 0
      end

      def each(&block : Entry ->) : Nil
        while (entry = next_entry)
          yield entry
        end
      end

      # Return a `Bytes` slice for scalar entries, or `nil` for container entries.
      #
      # Summary
      #
      # Works for `String`, `Key`, `Number`, and literal atom entries.
      def slice(entry : Entry) : Slice(UInt8)?
        case entry.type
        when TapeType::String, TapeType::Key, TapeType::Number, TapeType::True, TapeType::False, TapeType::Null
          @doc.bytes[entry.a, entry.b]
        else
          nil
        end
      end
    end

    # Parse a document from the structural indices produced by the lexer.
    # Build a `Document` (tape) via the Stage1b token assembly.
    #
    # Summary
    #
    # Converts structural indices from the lexer into a compact tape representation.
    # Returns `IR::Result` with a `Document` on success or an `ErrorCode` on failure.
    def self.parse(
      bytes : Bytes,
      buffer : LexerBuffer,
      max_depth : Int32,
      validate_literals : Bool = false,
      validate_numbers : Bool = false,
    ) : Result
      tokens = [] of Token
      token_error = Lexer::TokenAssembler.each_token(bytes, buffer) do |tok|
        tokens << tok
      end
      return Result.new(nil, token_error) unless token_error.success?

      parse_tokens(bytes, tokens, max_depth, validate_literals, validate_numbers)
    end

    def self.parse_tokens(
      bytes : Bytes,
      tokens : Array(Token),
      max_depth : Int32,
      validate_literals : Bool = false,
      validate_numbers : Bool = false
    ) : Result
      iter = TokenIterator.new(tokens)
      return Result.new(nil, ErrorCode::Empty) if iter.at_eof?

      builder = Builder.new(bytes, validate_literals, validate_numbers, tokens.size)
      stack = Array(Context).new(max_depth)

      root_token = iter.advance_significant
      return Result.new(nil, ErrorCode::TapeError) unless root_token

      error = parse_value_token(root_token, iter, builder, stack, max_depth)
      return Result.new(nil, error) unless error.success?

      while stack.size > 0
        ctx_index = stack.size - 1
        ctx = stack[ctx_index]
        case ctx.kind
        when ContextKind::Object
          case ctx.state
          when ContextState::ObjectKey
            tok = iter.advance_significant
            return Result.new(nil, ErrorCode::TapeError) unless tok
            return Result.new(nil, ErrorCode::TapeError) unless tok.type == TokenType::String
            builder.increment_count
            error = builder.key_token(tok)
            return Result.new(nil, error) unless error.success?
            ctx = stack[ctx_index]
            ctx.state = ContextState::ObjectColon
            stack[ctx_index] = ctx
          when ContextState::ObjectColon
            tok = iter.advance_significant
            return Result.new(nil, ErrorCode::TapeError) unless tok
            return Result.new(nil, ErrorCode::TapeError) unless tok.type == TokenType::Colon
            ctx = stack[ctx_index]
            ctx.state = ContextState::ObjectValue
            stack[ctx_index] = ctx
          when ContextState::ObjectValue
            tok = iter.advance_significant
            return Result.new(nil, ErrorCode::TapeError) unless tok
            ctx = stack[ctx_index]
            ctx.state = ContextState::ObjectCommaOrEnd
            stack[ctx_index] = ctx
            error = parse_value_token(tok, iter, builder, stack, max_depth)
            return Result.new(nil, error) unless error.success?
            nxt = iter.peek_significant
            if nxt
              case nxt.type
              when TokenType::Comma
                iter.advance_significant
                ctx = stack[ctx_index]
                ctx.state = ContextState::ObjectKey
                stack[ctx_index] = ctx
                next
              when TokenType::EndObject
                iter.advance_significant
                builder.end_object
                stack.pop
                next
              end
            end
          when ContextState::ObjectCommaOrEnd
            tok = iter.advance_significant
            return Result.new(nil, ErrorCode::TapeError) unless tok
            case tok.type
            when TokenType::Comma
              ctx = stack[ctx_index]
              ctx.state = ContextState::ObjectKey
              stack[ctx_index] = ctx
            when TokenType::EndObject
              builder.end_object
              stack.pop
            else
              return Result.new(nil, ErrorCode::TapeError)
            end
          else
            return Result.new(nil, ErrorCode::TapeError)
          end
        when ContextKind::Array
          case ctx.state
          when ContextState::ArrayValue
            builder.increment_count
            tok = iter.advance_significant
            return Result.new(nil, ErrorCode::TapeError) unless tok
            ctx = stack[ctx_index]
            ctx.state = ContextState::ArrayCommaOrEnd
            stack[ctx_index] = ctx
            error = parse_value_token(tok, iter, builder, stack, max_depth)
            return Result.new(nil, error) unless error.success?
            nxt = iter.peek_significant
            if nxt
              case nxt.type
              when TokenType::Comma
                iter.advance_significant
                ctx = stack[ctx_index]
                ctx.state = ContextState::ArrayValue
                stack[ctx_index] = ctx
                next
              when TokenType::EndArray
                iter.advance_significant
                builder.end_array
                stack.pop
                next
              end
            end
          when ContextState::ArrayCommaOrEnd
            tok = iter.advance_significant
            return Result.new(nil, ErrorCode::TapeError) unless tok
            case tok.type
            when TokenType::Comma
              ctx = stack[ctx_index]
              ctx.state = ContextState::ArrayValue
              stack[ctx_index] = ctx
            when TokenType::EndArray
              builder.end_array
              stack.pop
            else
              return Result.new(nil, ErrorCode::TapeError)
            end
          else
            return Result.new(nil, ErrorCode::TapeError)
          end
        end
      end

      if iter.remaining_significant > 0
        return Result.new(nil, ErrorCode::TapeError)
      end

      builder.root_entry(0)
      Result.new(Document.new(bytes, builder.tape), ErrorCode::Success)
    end

    private def self.parse_value_token(
      token : Token,
      iter : TokenIterator,
      builder : Builder,
      stack : Array(Context),
      max_depth : Int32
    ) : ErrorCode
      case token.type
      when TokenType::StartObject
        nxt = iter.peek_significant
        if nxt && nxt.type == TokenType::EndObject
          iter.advance_significant
          builder.empty_object
          return ErrorCode::Success
        end
        return ErrorCode::DepthError if stack.size + 1 >= max_depth
        builder.start_object
        stack << Context.new(ContextKind::Object, ContextState::ObjectKey)
        ErrorCode::Success
      when TokenType::StartArray
        nxt = iter.peek_significant
        if nxt && nxt.type == TokenType::EndArray
          iter.advance_significant
          builder.empty_array
          return ErrorCode::Success
        end
        return ErrorCode::DepthError if stack.size + 1 >= max_depth
        builder.start_array
        stack << Context.new(ContextKind::Array, ContextState::ArrayValue)
        ErrorCode::Success
      when TokenType::String
        builder.string_token(token)
      when TokenType::Number, TokenType::True, TokenType::False, TokenType::Null
        builder.primitive_token(token)
      else
        ErrorCode::TapeError
      end
    end

    def self.scan_string_end(bytes : Bytes, start : Int32, next_struct : Int32) : Int32
      if next_struct > start
        end_idx = next_struct - 1
        return end_idx if bytes[end_idx] == '"'.ord
      end
      i = start
      escaped = false
      len = next_struct >= 0 ? next_struct : bytes.size

      while i < len
        c = bytes[i]
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

    def self.scan_scalar_end(bytes : Bytes, start : Int32, next_struct : Int32) : Int32
      limit = next_struct >= 0 ? next_struct : bytes.size
      # Trim trailing whitespace before the next structural.
      i = limit
      while i > start + 1
        c = bytes[i - 1]
        break unless c == ' '.ord || c == '\t'.ord || c == '\n'.ord || c == '\r'.ord
        i -= 1
      end
      i
    end

    def self.valid_true?(bytes : Bytes, start : Int32, length : Int32) : Bool
      return false unless length == 4
      bytes[start] == 't'.ord && bytes[start + 1] == 'r'.ord && bytes[start + 2] == 'u'.ord && bytes[start + 3] == 'e'.ord
    end

    def self.valid_false?(bytes : Bytes, start : Int32, length : Int32) : Bool
      return false unless length == 5
      bytes[start] == 'f'.ord && bytes[start + 1] == 'a'.ord && bytes[start + 2] == 'l'.ord &&
        bytes[start + 3] == 's'.ord && bytes[start + 4] == 'e'.ord
    end

    def self.valid_null?(bytes : Bytes, start : Int32, length : Int32) : Bool
      return false unless length == 4
      bytes[start] == 'n'.ord && bytes[start + 1] == 'u'.ord && bytes[start + 2] == 'l'.ord && bytes[start + 3] == 'l'.ord
    end

    def self.valid_number?(bytes : Bytes, start : Int32, length : Int32) : Bool
      return false if length <= 0
      i = start
      finish = start + length

      if bytes[i] == '-'.ord
        i += 1
        return false if i == finish
      end

      if bytes[i] == '0'.ord
        i += 1
      elsif bytes[i] >= '1'.ord && bytes[i] <= '9'.ord
        i += 1
        while i < finish && bytes[i] >= '0'.ord && bytes[i] <= '9'.ord
          i += 1
        end
      else
        return false
      end

      if i < finish && bytes[i] == '.'.ord
        i += 1
        return false if i == finish
        return false unless bytes[i] >= '0'.ord && bytes[i] <= '9'.ord
        while i < finish && bytes[i] >= '0'.ord && bytes[i] <= '9'.ord
          i += 1
        end
      end

      if i < finish && (bytes[i] == 'e'.ord || bytes[i] == 'E'.ord)
        i += 1
        return false if i == finish
        if bytes[i] == '+'.ord || bytes[i] == '-'.ord
          i += 1
          return false if i == finish
        end
        return false unless bytes[i] >= '0'.ord && bytes[i] <= '9'.ord
        while i < finish && bytes[i] >= '0'.ord && bytes[i] <= '9'.ord
          i += 1
        end
      end

      i == finish
    end
  end
end
