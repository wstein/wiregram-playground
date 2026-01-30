require "../backend"

module Warp
  module Backend
    class AvxBackend < Base
      def name : String
        "avx"
      end

      def build_masks(ptr : Pointer(UInt8), block_len : Int32) : Lexer::Masks
        backslash = 0_u64
        quote = 0_u64
        whitespace = 0_u64
        op = 0_u64
        control = 0_u64

        i = 0
        {% if flag?(:x86_64) && flag?(:avx2) %}
          while i + 31 < block_len
            m = X86Masks.scan32(ptr + i)
            shift = i
            backslash |= m.backslash.to_u64 << shift
            quote |= m.quote.to_u64 << shift
            whitespace |= m.whitespace.to_u64 << shift
            op |= m.op.to_u64 << shift
            control |= m.control.to_u64 << shift
            i += 32
          end
        {% elsif flag?(:x86_64) && flag?(:avx) %}
          while i + 31 < block_len
            m = X86Masks.scan32_combined(ptr + i)
            shift = i
            backslash |= m.backslash.to_u64 << shift
            quote |= m.quote.to_u64 << shift
            whitespace |= m.whitespace.to_u64 << shift
            op |= m.op.to_u64 << shift
            control |= m.control.to_u64 << shift
            i += 32
          end
        {% end %}

        while i < block_len
          c = ptr[i]
          bit = 1_u64 << i
          control |= bit if c <= 0x1f_u8
          case c
          when 0x20_u8, 0x09_u8
            whitespace |= bit
          when 0x0a_u8, 0x0d_u8
            op |= bit
          when '['.ord, ']'.ord, '{'.ord, '}'.ord, ':'.ord, ','.ord
            op |= bit
          end
          backslash |= bit if c == '\\'.ord
          quote |= bit if c == '"'.ord
          i += 1
        end

        if block_len < 64
          whitespace |= ~0_u64 << block_len
        end

        Lexer::Masks.new(backslash, quote, whitespace, op, control)
      end

      def all_digits16?(ptr : Pointer(UInt8)) : Bool
        X86Masks.all_digits16?(ptr)
      end

      def newline_mask(ptr : Pointer(UInt8), block_len : Int32) : UInt64
        mask = 0_u64
        i = 0
        {% if flag?(:x86_64) && (flag?(:avx2) || flag?(:avx)) %}
          while i + 15 < block_len
            block_mask = X86Masks.newline_mask16(ptr + i)
            mask |= block_mask.to_u64 << i
            i += 16
          end
        {% end %}
        while i < block_len
          b = ptr[i]
          mask |= (1_u64 << i) if b == 0x0a_u8 || b == 0x0d_u8
          i += 1
        end
        mask
      end
    end
  end
end
