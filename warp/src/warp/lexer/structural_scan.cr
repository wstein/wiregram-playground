# Lexer: Structural index scanner
#
# Summary
#
# Locate structural JSON characters (quotes, braces, brackets, commas, colons)
# and compute masks used by stage 2. This module includes a fast NEON-backed
# path for aarch64 and a scalar fallback for other architectures. It also
# performs lightweight UTF-8 validation and string escape scanning.
#
# Details
# - Produces a `LexerBuffer` of structural indices via `StructuralScan.index`.
# - Exposes utilities for scanning strings, escapes, and validating UTF-8.
module Warp
  module Lexer
    alias ErrorCode = Core::ErrorCode
    alias LexerBuffer = Core::LexerBuffer
    alias LexerResult = Core::LexerResult

    ODD_BITS = 0xAAAAAAAAAAAAAAAA_u64

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
        in_string = Lexer.prefix_xor(quote) ^ @prev_in_string
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

    def self.index(bytes : Bytes) : LexerResult
      ptr = bytes.to_unsafe
      len = bytes.size
      indices = Array(UInt32).new
      scanner = Scanner.new
      unescaped_error = 0_u64
      utf8 = Utf8Validator.new
      backend = Backend.current
      error = ErrorCode::Success

      offset = 0
      while offset < len
        block_len = len - offset
        block_len = 64 if block_len > 64
        unless utf8.consume(ptr + offset, block_len)
          error = ErrorCode::Utf8Error
          break
        end

        masks = backend.build_masks(ptr + offset, block_len)
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

      if error == ErrorCode::Success
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
      end

      buffer = LexerBuffer.new(indices.to_unsafe, indices.size, indices)
      LexerResult.new(buffer, error)
    end

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
