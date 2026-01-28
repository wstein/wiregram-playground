# Stage 1: Structural index scanner
#
# Summary
#
# Locate structural JSON characters (quotes, braces, brackets, commas, colons)
# and compute masks used by stage 2. This module includes a fast NEON-backed
# path for aarch64 and a scalar fallback for other architectures. It also
# performs lightweight UTF-8 validation and string escape scanning.
#
# Details
# - Produces an `Array(UInt32)` of structural indices via `Stage1.index`.
# - Exposes utilities for scanning strings, escapes, and validating UTF-8.
module Simdjson
  module Stage1
    ODD_BITS = 0xAAAAAAAAAAAAAAAA_u64
    VERIFY_NEON = ENV["SIMDJSON_VERIFY_NEON"]? == "1"

    struct EscapeScanResult
      getter escaped : UInt64
      getter escape : UInt64

      def initialize(@escaped : UInt64, @escape : UInt64)
      end
    end

    class EscapeScanner
      @next_is_escaped : UInt64 = 0_u64

      def next(backslash : UInt64) : EscapeScanResult
        if backslash == 0
          escaped = @next_is_escaped
          @next_is_escaped = 0_u64
          return EscapeScanResult.new(escaped, 0_u64)
        end

        escape_and_terminal = self.class.next_escape_and_terminal_code(backslash & ~@next_is_escaped)
        escaped = escape_and_terminal ^ (backslash | @next_is_escaped)
        escape = escape_and_terminal & backslash
        @next_is_escaped = escape >> 63
        EscapeScanResult.new(escaped, escape)
      end

      def self.next_escape_and_terminal_code(potential_escape : UInt64) : UInt64
        maybe_escaped = potential_escape << 1
        maybe_escaped_and_odd_bits = maybe_escaped | ODD_BITS
        even_series_codes_and_odd_bits = maybe_escaped_and_odd_bits &- potential_escape
        even_series_codes_and_odd_bits ^ ODD_BITS
      end
    end

    struct StringBlock
      getter escaped : UInt64
      getter quote : UInt64
      getter in_string : UInt64

      def initialize(@escaped : UInt64, @quote : UInt64, @in_string : UInt64)
      end

      def string_tail : UInt64
        @in_string ^ @quote
      end

      def non_quote_inside_string(mask : UInt64) : UInt64
        mask & @in_string
      end

      def non_quote_outside_string(mask : UInt64) : UInt64
        mask & ~@in_string
      end
    end

    class StringScanner
      @escape_scanner = EscapeScanner.new
      @prev_in_string : UInt64 = 0_u64

      def next(backslash : UInt64, quote_mask : UInt64) : StringBlock
        escaped = @escape_scanner.next(backslash).escaped
        quote = quote_mask & ~escaped
        in_string = Stage1.prefix_xor(quote) ^ @prev_in_string
        @prev_in_string = (in_string & 0x8000000000000000_u64) == 0 ? 0_u64 : 0xFFFFFFFFFFFFFFFF_u64
        StringBlock.new(escaped, quote, in_string)
      end

      def finish : ErrorCode
        @prev_in_string == 0 ? ErrorCode::Success : ErrorCode::UnclosedString
      end
    end

    struct CharacterBlock
      getter whitespace : UInt64
      getter op : UInt64

      def initialize(@whitespace : UInt64, @op : UInt64)
      end

      def scalar : UInt64
        ~(@op | @whitespace)
      end
    end

    struct JsonBlock
      getter strings : StringBlock
      getter characters : CharacterBlock
      getter follows_nonquote_scalar : UInt64

      def initialize(@strings : StringBlock, @characters : CharacterBlock, @follows_nonquote_scalar : UInt64)
      end

      def structural_start : UInt64
        potential_structural_start & ~@strings.string_tail
      end

      def non_quote_inside_string(mask : UInt64) : UInt64
        @strings.non_quote_inside_string(mask)
      end

      private def potential_structural_start : UInt64
        @characters.op | potential_scalar_start
      end

      private def potential_scalar_start : UInt64
        @characters.scalar & ~@follows_nonquote_scalar
      end
    end

    class Scanner
      @string_scanner = StringScanner.new
      @prev_scalar : UInt64 = 0_u64

      def next(backslash : UInt64, quote_mask : UInt64, whitespace : UInt64, op : UInt64) : JsonBlock
        strings = @string_scanner.next(backslash, quote_mask)
        characters = CharacterBlock.new(whitespace, op)
        nonquote_scalar = characters.scalar & ~strings.quote
        follows_nonquote_scalar = follows(nonquote_scalar)
        JsonBlock.new(strings, characters, follows_nonquote_scalar)
      end

      def finish : ErrorCode
        @string_scanner.finish
      end

      private def follows(match : UInt64) : UInt64
        result = (match << 1) | (@prev_scalar & 1_u64)
        @prev_scalar = match >> 63
        result
      end
    end

    struct Result
      getter indices : Array(UInt32)
      getter error : ErrorCode

      def initialize(@indices : Array(UInt32), @error : ErrorCode)
      end
    end

    module Utf8
      module Neon
        def self.ascii_block?(ptr : Pointer(UInt8)) : Bool
          is_ascii = 0
          asm(
            %(
            ld1 {v0.16b}, [$1]
            umaxv b1, v0.16b
            umov w2, v1.b[0]
            cmp w2, #0x7F
            cset $0, le
            )
            : "=r"(is_ascii)
            : "r"(ptr)
            : "v0", "v1", "w2"
            : "volatile"
          )
          is_ascii != 0
        end

        def self.validate_block(ptr : Pointer(UInt8), state : UInt32*) : Bool
          val = state.value
          remaining = (val & 0xFF).to_i
          first_min = ((val >> 8) & 0xFF).to_u8
          first_max = ((val >> 16) & 0xFF).to_u8
          pending = ((val >> 24) & 0x01) == 1
          if remaining == 0 && !pending && ascii_block?(ptr)
            return true
          end
          i = 0
          while i < 16
            b = (ptr + i).value
            if remaining == 0
              case b
              when 0x00_u8..0x7F_u8
                # ASCII already filtered; still allow here.
              when 0xC2_u8..0xDF_u8
                remaining = 1
                pending = false
              when 0xE0_u8
                remaining = 2
                pending = true
                first_min = 0xA0_u8
                first_max = 0xBF_u8
              when 0xE1_u8..0xEC_u8, 0xEE_u8..0xEF_u8
                remaining = 2
                pending = false
              when 0xED_u8
                remaining = 2
                pending = true
                first_min = 0x80_u8
                first_max = 0x9F_u8
              when 0xF0_u8
                remaining = 3
                pending = true
                first_min = 0x90_u8
                first_max = 0xBF_u8
              when 0xF1_u8..0xF3_u8
                remaining = 3
                pending = false
              when 0xF4_u8
                remaining = 3
                pending = true
                first_min = 0x80_u8
                first_max = 0x8F_u8
              else
                return false
              end
            else
              if pending
                return false if b < first_min || b > first_max
                pending = false
                remaining -= 1
              else
                return false unless b >= 0x80 && b <= 0xBF
                remaining -= 1
              end
            end
            i += 1
          end
          if remaining == 0 && !pending
            first_min = 0_u8
            first_max = 0_u8
          end
          out = remaining.to_u32 | (first_min.to_u32 << 8) | (first_max.to_u32 << 16) | (pending ? 1_u32 << 24 : 0_u32)
          state.value = out
          true
        end
      end
    end

    # Lightweight UTF-8 validator that keeps state across blocks.
    class Utf8Validator
      @remaining : Int32 = 0
      @first_min : UInt8 = 0_u8
      @first_max : UInt8 = 0_u8
      @first_pending : Bool = false

      def consume(ptr : Pointer(UInt8), len : Int32) : Bool
        offset = 0
        {% if flag?(:aarch64) %}
          state = pack_state
          while offset + 15 < len
            unless Utf8::Neon.validate_block(ptr + offset, pointerof(state))
              unpack_state(state)
              return false
            end
            offset += 16
          end
          unpack_state(state)
        {% end %}
        return true if offset >= len
        validate_scalar(ptr + offset, len - offset)
      end

      def validate_scalar(ptr : Pointer(UInt8), len : Int32) : Bool
        i = 0
        while i < len
          b = ptr[i]
          if @remaining == 0
            case b
            when 0x00_u8..0x7F_u8
              # ASCII fast path
            when 0xC2_u8..0xDF_u8
              start_sequence(1, 0x80_u8, 0xBF_u8)
            when 0xE0_u8
              start_sequence(2, 0xA0_u8, 0xBF_u8) # prevent overlong 3-byte
            when 0xE1_u8..0xEC_u8, 0xEE_u8..0xEF_u8
              start_sequence(2, 0x80_u8, 0xBF_u8)
            when 0xED_u8
              start_sequence(2, 0x80_u8, 0x9F_u8) # block UTF-16 surrogates
            when 0xF0_u8
              start_sequence(3, 0x90_u8, 0xBF_u8) # prevent overlong 4-byte
            when 0xF1_u8..0xF3_u8
              start_sequence(3, 0x80_u8, 0xBF_u8)
            when 0xF4_u8
              start_sequence(3, 0x80_u8, 0x8F_u8) # <= U+10FFFF
            else
              return false
            end
          else
            min = @first_pending ? @first_min : 0x80_u8
            max = @first_pending ? @first_max : 0xBF_u8
            return false if b < min || b > max
            @remaining -= 1
            @first_pending = false
          end
          i += 1
        end
        true
      end

      def finish? : Bool
        @remaining == 0
      end

      private def start_sequence(remaining : Int32, first_min : UInt8, first_max : UInt8)
        @remaining = remaining
        @first_min = first_min
        @first_max = first_max
        @first_pending = true
      end

      private def pack_state : UInt32
        pending = @first_pending ? 1_u32 : 0_u32
        if @remaining == 0 && pending == 0
          return 0_u32
        end
        @remaining.to_u32 | (@first_min.to_u32 << 8) | (@first_max.to_u32 << 16) | (pending << 24)
      end

      private def unpack_state(state : UInt32)
        @remaining = (state & 0xFF).to_i
        @first_min = ((state >> 8) & 0xFF).to_u8
        @first_max = ((state >> 16) & 0xFF).to_u8
        @first_pending = ((state >> 24) & 0x01) == 1
      end
    end

    struct Masks
      getter backslash : UInt64
      getter quote : UInt64
      getter whitespace : UInt64
      getter op : UInt64
      getter control : UInt64

      def initialize(@backslash : UInt64, @quote : UInt64, @whitespace : UInt64, @op : UInt64, @control : UInt64)
      end
    end

    def self.index(bytes : Bytes) : Result
      ptr = bytes.to_unsafe
      len = bytes.size
      indices = Array(UInt32).new
      scanner = Scanner.new
      unescaped_error = 0_u64
      utf8 = Utf8Validator.new

      offset = 0
      while offset < len
        block_len = len - offset
        block_len = 64 if block_len > 64
        unless utf8.consume(ptr + offset, block_len)
          return Result.new(indices, ErrorCode::Utf8Error)
        end

        masks = build_masks(ptr + offset, block_len)
        block = scanner.next(masks.backslash, masks.quote, masks.whitespace, masks.op)

        structural = block.structural_start
        if block_len < 64
          structural &= (1_u64 << block_len) - 1_u64
        end

        bits = structural
        while bits != 0
          tz = bits.trailing_zeros_count
          indices << (offset + tz).to_u32
          bits &= bits - 1_u64
        end

        unescaped_error |= block.non_quote_inside_string(masks.control)
        offset += 64
      end

      error = scanner.finish
      if error == ErrorCode::Success && !utf8.finish?
        error = ErrorCode::Utf8Error
      end
      if error == ErrorCode::Success && unescaped_error != 0
        error = ErrorCode::UnescapedChars
      end
      if error == ErrorCode::Success && indices.empty?
        error = ErrorCode::Empty
      end

      Result.new(indices, error)
    end

    private def self.build_masks(ptr : Pointer(UInt8), block_len : Int32) : Masks
      backslash = 0_u64
      quote = 0_u64
      whitespace = 0_u64
      op = 0_u64
      control = 0_u64

      i = 0
      {% if flag?(:aarch64) %}
        while i + 7 < block_len
          m = Neon.scan8(ptr + i)
          if VERIFY_NEON
            scalar = scalar_masks(ptr + i, 8)
            if (scalar.backslash & 0xff_u16).to_u8 != m.backslash ||
               (scalar.quote & 0xff_u16).to_u8 != m.quote ||
               (scalar.whitespace & 0xff_u16).to_u8 != m.whitespace ||
               (scalar.op & 0xff_u16).to_u8 != m.op ||
               (scalar.control & 0xff_u16).to_u8 != m.control
              m = Neon::Masks8.new(
                (scalar.backslash & 0xff_u16).to_u8,
                (scalar.quote & 0xff_u16).to_u8,
                (scalar.whitespace & 0xff_u16).to_u8,
                (scalar.op & 0xff_u16).to_u8,
                (scalar.control & 0xff_u16).to_u8
              )
            end
          end
          shift = i
          backslash |= m.backslash.to_u64 << shift
          quote |= m.quote.to_u64 << shift
          whitespace |= m.whitespace.to_u64 << shift
          op |= m.op.to_u64 << shift
          control |= m.control.to_u64 << shift
          i += 8
        end
      {% end %}
      while i < block_len
        c = ptr[i]
        bit = 1_u64 << i

        if c <= 0x1f_u8
          control |= bit
        end

        case c
        when 0x20_u8, 0x09_u8, 0x0d_u8
          whitespace |= bit
        when 0x0a_u8
          op |= bit
        when '['.ord, ']'.ord, '{'.ord, '}'.ord, ':'.ord, ','.ord
          op |= bit
        end

        if c == '\\'.ord
          backslash |= bit
        elsif c == '"'.ord
          quote |= bit
        end

        i += 1
      end

      # TODO optimize! Partial blocks should be not be possible, as padded buffers are used.
      if block_len < 64
        whitespace |= ~0_u64 << block_len
      end

      Masks.new(backslash, quote, whitespace, op, control)
    end

    private def self.scalar_masks(ptr : Pointer(UInt8), len : Int32) : Neon::Masks16
      backslash = 0_u16
      quote = 0_u16
      whitespace = 0_u16
      op = 0_u16
      control = 0_u16

      i = 0
      while i < len
        b = ptr[i]
        bit = 1_u16 << i
        control |= bit if b <= 0x1f
        case b
        when 0x20, 0x09, 0x0d
          whitespace |= bit
        when 0x0a
          op |= bit
        when '{'.ord, '}'.ord, '['.ord, ']'.ord, ':'.ord, ','.ord
          op |= bit
        end
        backslash |= bit if b == '\\'.ord
        quote |= bit if b == '"'.ord
        i += 1
      end

      Neon::Masks16.new(backslash, quote, whitespace, op, control)
    end

    # Why padding may be required for NEON
    #
    # Some NEON helpers load 16 bytes at a time (e.g. ld1 {v0.16b}, [ptr]).
    # Stage1 avoids overreads by only invoking those helpers on full blocks.
    # If you plan to call the NEON helpers on arbitrary buffers without
    # bounds checks, pad the input with 16 zero bytes to keep the loads safe.
    #
    # We provide utility helpers below that allocate a padded buffer, read a
    # file into it, and zero the trailing bytes. Callers are responsible for
    # freeing the returned buffer with `free_padded_buffer`.

    {% if flag?(:aarch64) %}
    lib LibC_Read
      fun malloc(size : UInt64) : Pointer(Void)
      fun free(ptr : Pointer(Void)) : Nil
      fun memcpy(dest : Pointer(Void), src : Pointer(Void), n : UInt64) : Pointer(Void)
      fun memset(dest : Pointer(Void), c : Int32, n : UInt64) : Pointer(Void)
    end

    # read_file_padded(path) -> (ptr, len)
    #
    # Allocates a buffer of file_size + 16, reads the file content into it and
    # zeroes the trailing 16 bytes. Returns a pointer to the buffer (Pointer(UInt8))
    # and the original file length as Int32. On error the function returns
    # Pointer(UInt8).null and length 0.
    def self.read_file_padded(path : String) : Tuple(Pointer(UInt8), Int32)
      o_rdonly = 0
      seek_set = 0
      seek_end = 2

      fd = LibC.open(path.to_unsafe, o_rdonly, 0)
      if fd < 0
        return {Pointer(UInt8).null, 0}
      end

      size = LibC.lseek(fd, 0, seek_end)
      if size < 0
        LibC.close(fd)
        return {Pointer(UInt8).null, 0}
      end
      LibC.lseek(fd, 0, seek_set)

      total = size.to_u64 + 16_u64
      allocated = LibC_Read.malloc(total)
      if allocated.null?
        LibC.close(fd)
        return {Pointer(UInt8).null, 0}
      end

      read_total = 0_i64
      while read_total < size
        r = LibC.read(fd, allocated + read_total, (size - read_total).to_u64)
        if r <= 0
          LibC_Read.free(allocated)
          LibC.close(fd)
          return {Pointer(UInt8).null, 0}
        end
        read_total += r
      end

      LibC_Read.memset(allocated + size, 0, 16_u64)
      LibC.close(fd)

      {allocated.as(Pointer(UInt8)), size.to_i}
    end

    # free_padded_buffer(ptr)
    #
    # Free a buffer previously returned by `read_file_padded`.
    def self.free_padded_buffer(ptr : Pointer(UInt8))
      return if ptr.null?
      LibC_Read.free(ptr.as(Pointer(Void)))
    end

    # read_file_padded_bytes(path) -> Bytes
    #
    # Convenience wrapper that returns a GC-managed `Bytes` slice backed by an
    # `Array(UInt8)` containing the file contents plus 16 zero bytes. This is
    # the recommended high-level API in Crystal code since it avoids manual
    # malloc/free and is safe to pass to NEON-backed functions.
    def self.read_file_padded_bytes(path : String) : Bytes
      # Try to read directly into a Crystal-managed Array(UInt8) to avoid
      # an extra copy. This is done using low-level libc syscalls to get the
      # file size and perform direct reads into the array's memory.
      begin
        o_rdonly = 0
        seek_end = 2
        seek_set = 0

        fd = LibC.open(path.to_unsafe, o_rdonly, 0)
        return Bytes.new(0) if fd < 0

        size = LibC.lseek(fd, 0, seek_end)
        if size < 0
          LibC.close(fd)
          return Bytes.new(0)
        end
        LibC.lseek(fd, 0, seek_set)

        buf = Bytes.new(size.to_i + 16)
        read_total = 0_i64
        while read_total < size
          r = LibC.read(fd, buf.to_unsafe + read_total, (size - read_total).to_u64)
          if r <= 0
            LibC.close(fd)
            return Bytes.new(0)
          end
          read_total += r
        end

        LibC.close(fd)
        # trailing bytes are zero-initialized by Bytes.new
        buf
      rescue ex
        Bytes.new(0)
      end
    end
    {% end %}

    def self.prefix_xor(bitmask : UInt64) : UInt64
      bitmask ^= bitmask << 1
      bitmask ^= bitmask << 2
      bitmask ^= bitmask << 4
      bitmask ^= bitmask << 8
      bitmask ^= bitmask << 16
      bitmask ^= bitmask << 32
      bitmask
    end
  end
end
