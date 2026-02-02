module Warp
  module Backend
    class NeonBackend < Base
      VERIFY_BACKEND = (ENV["WARP_VERIFY_BACKEND"]? == "1") ||
                       (ENV["WARP_VERIFY_NEON"]? == "1")

      def name : String
        "neon"
      end

      def build_masks(ptr : Pointer(UInt8), block_len : Int32) : Lexer::Masks
        backslash = 0_u64
        quote = 0_u64
        whitespace = 0_u64
        op = 0_u64
        control = 0_u64

        i = 0
        {% if flag?(:aarch64) %}
          while i + 15 < block_len
            m = NeonMasks.scan16(ptr + i)
            if VERIFY_BACKEND
              scalar = scalar_masks(ptr + i, 16)
              if scalar.backslash != m.backslash ||
                 scalar.quote != m.quote ||
                 scalar.whitespace != m.whitespace ||
                 scalar.op != m.op ||
                 scalar.control != m.control
                m = scalar
              end
            end
            shift = i
            backslash |= m.backslash.to_u64 << shift
            quote |= m.quote.to_u64 << shift
            whitespace |= m.whitespace.to_u64 << shift
            op |= m.op.to_u64 << shift
            control |= m.control.to_u64 << shift
            i += 16
          end
          while i + 7 < block_len
            m = NeonMasks.scan8(ptr + i)
            if VERIFY_BACKEND
              scalar = scalar_masks(ptr + i, 8)
              if (scalar.backslash & 0xff_u16).to_u8 != m.backslash ||
                 (scalar.quote & 0xff_u16).to_u8 != m.quote ||
                 (scalar.whitespace & 0xff_u16).to_u8 != m.whitespace ||
                 (scalar.op & 0xff_u16).to_u8 != m.op ||
                 (scalar.control & 0xff_u16).to_u8 != m.control
                m = NeonMasks::Masks8.new(
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
          when 0x20_u8, 0x09_u8
            whitespace |= bit
          when 0x0a_u8, 0x0d_u8
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

        if block_len < 64
          whitespace |= ~0_u64 << block_len
        end

        Lexer::Masks.new(backslash, quote, whitespace, op, control)
      end

      def all_digits16?(ptr : Pointer(UInt8)) : Bool
        {% if flag?(:aarch64) %}
          any_invalid = 0_u32
          asm(
            %(
            ld1 {v0.16b}, [$1]
            movi v1.16b, 48
            movi v2.16b, 57
            cmhs v3.16b, v0.16b, v1.16b
            cmhs v4.16b, v2.16b, v0.16b
            and v5.16b, v3.16b, v4.16b
            mvn v6.16b, v5.16b
            umaxv b7, v6.16b
            umov w8, v7.b[0]
            uxtw x9, w8
            mov $0, x9
            )
                  : "=r"(any_invalid)
                  : "r"(ptr)
                  : "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7", "w8", "x9"
                  : "volatile"
          )
          any_invalid == 0_u32
        {% else %}
          16.times do |i|
            b = ptr[i]
            return false unless b >= '0'.ord && b <= '9'.ord
          end
          true
        {% end %}
      end

      def newline_mask(ptr : Pointer(UInt8), block_len : Int32) : UInt64
        mask = 0_u64
        i = 0
        {% if flag?(:aarch64) %}
          while i + 15 < block_len
            block_mask = NeonMasks.newline_mask16(ptr + i)
            mask |= block_mask.to_u64 << i
            i += 16
          end
          while i + 7 < block_len
            block_mask = NeonMasks.newline_mask8(ptr + i)
            mask |= block_mask.to_u64 << i
            i += 8
          end
        {% end %}
        while i < block_len
          b = ptr[i]
          mask |= (1_u64 << i) if b == 0x0a_u8 || b == 0x0d_u8
          i += 1
        end
        mask
      end

      def ascii_block?(ptr : Pointer(UInt8)) : Bool
        is_ascii = 0
        {% if flag?(:aarch64) %}
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
        {% else %}
          i = 0
          while i < 16
            return false if ptr[i] > 0x7F_u8
            i += 1
          end
        {% end %}
        is_ascii != 0
      end

      def validate_block(ptr : Pointer(UInt8), state : UInt32*) : Bool
        # Mirror the previous Utf8::Neon.validate_block implementation
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

      private def scalar_masks(ptr : Pointer(UInt8), len : Int32) : NeonMasks::Masks16
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
          when 0x20, 0x09
            whitespace |= bit
          when 0x0a, 0x0d
            op |= bit
          when '{'.ord, '}'.ord, '['.ord, ']'.ord, ':'.ord, ','.ord
            op |= bit
          end
          backslash |= bit if b == '\\'.ord
          quote |= bit if b == '"'.ord
          i += 1
        end

        NeonMasks::Masks16.new(backslash, quote, whitespace, op, control)
      end
    end
  end
end
