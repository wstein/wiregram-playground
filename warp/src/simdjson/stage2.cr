# Stage 2: Tape builder and document representation
#
# Summary
#
# Converts the structural indices (from stage 1) into a compact "tape"
# representation that is efficient to traverse. The tape stores typed
# entries (strings, numbers, structural markers) and supports iteration
# and slicing into the original `Bytes` buffer.
#
# See `Stage2::Builder` for how the tape is constructed and `Document`
# / `TapeIterator` for traversal utilities.
module Simdjson
  module Stage2
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

    # Entry represents a single tape entry with a type and two integer
    # fields. For string/number/atom entries `a` and `b` encode slice
    # offsets/lengths; for containers they encode index links.
    struct Entry
      getter type : TapeType
      getter a : Int32
      getter b : Int32

      def initialize(@type : TapeType, @a : Int32, @b : Int32)
      end
    end

    # Document wraps the original bytes and the tape produced by the
    # parser. Use `Document#iterator` or `Document#each_entry` to walk
    # the tape. `TapeIterator#slice(entry)` returns a `Bytes` slice for
    # scalar entries.
    class Document
      getter bytes : Bytes
      getter tape : Array(Entry)

      def initialize(@bytes : Bytes, @tape : Array(Entry))
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
    # `Stage2.parse`.
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
    # `Stage2.parse` but documented here for completeness.
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
        end_index = Stage2.scan_scalar_end(@bytes, start_index, next_struct)
        length = end_index - start_index

        case first
        when 't'.ord
          if @validate_literals && !Stage2.valid_true?(@bytes, start_index, length)
            return ErrorCode::TAtomError
          end
          @tape << Entry.new(TapeType::True, start_index, length)
        when 'f'.ord
          if @validate_literals && !Stage2.valid_false?(@bytes, start_index, length)
            return ErrorCode::FAtomError
          end
          @tape << Entry.new(TapeType::False, start_index, length)
        when 'n'.ord
          if @validate_literals && !Stage2.valid_null?(@bytes, start_index, length)
            return ErrorCode::NAtomError
          end
          @tape << Entry.new(TapeType::Null, start_index, length)
        else
          if @validate_numbers && !Stage2.valid_number?(@bytes, start_index, length)
            return ErrorCode::NumberError
          end
          @tape << Entry.new(TapeType::Number, start_index, length)
        end

        ErrorCode::Success
      end

      def root_entry(root_index : Int32)
        @tape << Entry.new(TapeType::Root, root_index, 0)
      end

      private def string_entry(start_index : Int32, type : TapeType, next_struct : Int32) : ErrorCode
        end_index = Stage2.scan_string_end(@bytes, start_index + 1, next_struct)
        return ErrorCode::UnclosedString if end_index < 0
        @tape << Entry.new(type, start_index + 1, end_index - (start_index + 1))
        ErrorCode::Success
      end
    end

    # Iterator over structural indices returned by stage1.
    class Iterator
      def initialize(@bytes : Bytes, buffer : Stage1Buffer)
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

      @[NoInline]
      def remaining_structurals : Int32
        remaining = @count - @pos
        remaining
      end

      def last_structural_byte : UInt8
        return 0_u8 if @count == 0
        @bytes[@indices[@count - 1]]
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
      def slice(entry : Entry) : Bytes?
        case entry.type
        when TapeType::String, TapeType::Key, TapeType::Number, TapeType::True, TapeType::False, TapeType::Null
          @doc.bytes[entry.a, entry.b]
        else
          nil
        end
      end
    end

    # Parse a document from the structural indices produced by stage1.
    # Build a `Document` (tape) from structural indices.
    #
    # Summary
    #
    # Converts structural indices from `Stage1` into a compact tape representation.
    # Returns `Stage2::Result` with a `Document` on success or an `ErrorCode` on failure.
    def self.parse(
      bytes : Bytes,
      buffer : Stage1Buffer,
      max_depth : Int32,
      validate_literals : Bool = false,
      validate_numbers : Bool = false,
    ) : Result
      iter = Iterator.new(bytes, buffer)
      return Result.new(nil, ErrorCode::Empty) if iter.at_eof?

      builder = Builder.new(bytes, validate_literals, validate_numbers, buffer.count)
      stack = Array(Context).new(max_depth)

      root_index = iter.advance_index
      return Result.new(nil, ErrorCode::TapeError) if root_index < 0

      error = parse_value(bytes, root_index, iter, builder, stack, max_depth)
      return Result.new(nil, error) unless error.success?

      while stack.size > 0
        ctx_index = stack.size - 1
        ctx = stack[ctx_index]
        case ctx.kind
        when ContextKind::Object
          case ctx.state
          when ContextState::ObjectKey
            idx = iter.advance_index
            return Result.new(nil, ErrorCode::TapeError) if idx < 0
            if bytes[idx] != '"'.ord
              return Result.new(nil, ErrorCode::TapeError)
            end
            builder.increment_count
            error = builder.key(idx, iter.peek_index)
            return Result.new(nil, error) unless error.success?
            ctx = stack[ctx_index]
            ctx.state = ContextState::ObjectColon
            stack[ctx_index] = ctx
          when ContextState::ObjectColon
            idx = iter.advance_index
            return Result.new(nil, ErrorCode::TapeError) if idx < 0
            return Result.new(nil, ErrorCode::TapeError) if bytes[idx] != ':'.ord
            ctx = stack[ctx_index]
            ctx.state = ContextState::ObjectValue
            stack[ctx_index] = ctx
          when ContextState::ObjectValue
            idx = iter.advance_index
            return Result.new(nil, ErrorCode::TapeError) if idx < 0
            ctx = stack[ctx_index]
            ctx.state = ContextState::ObjectCommaOrEnd
            stack[ctx_index] = ctx
            error = parse_value(bytes, idx, iter, builder, stack, max_depth)
            return Result.new(nil, error) unless error.success?
            nxt = iter.peek_index
            if nxt >= 0
              b = bytes[nxt]
              if b == ','.ord
                iter.advance_index
                ctx = stack[ctx_index]
                ctx.state = ContextState::ObjectKey
                stack[ctx_index] = ctx
                next
              elsif b == '}'.ord
                iter.advance_index
                builder.end_object
                stack.pop
                next
              end
            end
          when ContextState::ObjectCommaOrEnd
            idx = iter.advance_index
            return Result.new(nil, ErrorCode::TapeError) if idx < 0
            case bytes[idx]
            when ','.ord
              ctx = stack[ctx_index]
              ctx.state = ContextState::ObjectKey
              stack[ctx_index] = ctx
            when '}'.ord
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
            idx = iter.advance_index
            return Result.new(nil, ErrorCode::TapeError) if idx < 0
            ctx = stack[ctx_index]
            ctx.state = ContextState::ArrayCommaOrEnd
            stack[ctx_index] = ctx
            error = parse_value(bytes, idx, iter, builder, stack, max_depth)
            return Result.new(nil, error) unless error.success?
            nxt = iter.peek_index
            if nxt >= 0
              b = bytes[nxt]
              if b == ','.ord
                iter.advance_index
                ctx = stack[ctx_index]
                ctx.state = ContextState::ArrayValue
                stack[ctx_index] = ctx
                next
              elsif b == ']'.ord
                iter.advance_index
                builder.end_array
                stack.pop
                next
              end
            end
          when ContextState::ArrayCommaOrEnd
            idx = iter.advance_index
            return Result.new(nil, ErrorCode::TapeError) if idx < 0
            case bytes[idx]
            when ','.ord
              ctx = stack[ctx_index]
              ctx.state = ContextState::ArrayValue
              stack[ctx_index] = ctx
            when ']'.ord
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

      if iter.remaining_structurals > 0
        return Result.new(nil, ErrorCode::TapeError)
      end

      builder.root_entry(0)
      Result.new(Document.new(bytes, builder.tape), ErrorCode::Success)
    end

    private def self.parse_value(
      bytes : Bytes,
      idx : Int32,
      iter : Iterator,
      builder : Builder,
      stack : Array(Context),
      max_depth : Int32,
    ) : ErrorCode
      next_struct = iter.peek_index
      case bytes[idx]
      when '{'.ord
        if iter.peek_byte == '}'.ord
          iter.advance_index
          builder.empty_object
          return ErrorCode::Success
        end
        return ErrorCode::DepthError if stack.size + 1 >= max_depth
        builder.start_object
        stack << Context.new(ContextKind::Object, ContextState::ObjectKey)
        ErrorCode::Success
      when '['.ord
        if iter.peek_byte == ']'.ord
          iter.advance_index
          builder.empty_array
          return ErrorCode::Success
        end
        return ErrorCode::DepthError if stack.size + 1 >= max_depth
        builder.start_array
        stack << Context.new(ContextKind::Array, ContextState::ArrayValue)
        ErrorCode::Success
      when '"'.ord
        builder.string(idx, next_struct)
      else
        builder.primitive(idx, next_struct)
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
