module Warp
  module Backend
    class Avx2Backend < Base
      VERIFY_BACKEND = (ENV["WARP_VERIFY_BACKEND"]? == "1") ||
                       (ENV["WARP_VERIFY_AVX2"]? == "1")

      def name : String
        "avx2"
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
            if VERIFY_BACKEND
              scalar = scalar_masks(ptr + i, 32)
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

        number, identifier, unicode_letter = compute_extra_masks(ptr, block_len)
        Lexer::Masks.new(backslash, quote, whitespace, op, control, number, identifier, unicode_letter)
      end

      def all_digits16?(ptr : Pointer(UInt8)) : Bool
        X86Masks.all_digits16?(ptr)
      end

      def ascii_block?(ptr : Pointer(UInt8)) : Bool
        {% if flag?(:x86_64) && flag?(:avx2) %}
          is_ascii = 0_u32
          asm(
            %(
            vmovdqu (%%rsi), %%xmm0
            vpxor %%xmm1, %%xmm1, %%xmm1
            vpmaxub %%xmm0, %%xmm1, %%xmm2
            vmovd %%xmm2, %%eax
            cmp $0x7F, %%al
            setle %%dl
            movzbl %%dl, $0
            )
                  : "=r"(is_ascii)
                  : "S"(ptr)
                  : "xmm0", "xmm1", "xmm2", "rax", "rdx"
                  : "volatile"
          )
          is_ascii != 0
        {% else %}
          i = 0
          while i < 16
            return false if ptr[i] > 0x7F_u8
            i += 1
          end
          true
        {% end %}
      end

      def newline_mask(ptr : Pointer(UInt8), block_len : Int32) : UInt64
        mask = 0_u64
        i = 0
        {% if flag?(:x86_64) && flag?(:avx2) %}
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

      private def scalar_masks(ptr : Pointer(UInt8), len : Int32) : X86Masks::Masks32
        backslash = 0_u32
        quote = 0_u32
        whitespace = 0_u32
        op = 0_u32
        control = 0_u32

        i = 0
        while i < len
          b = ptr[i]
          bit = 1_u32 << i
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

        X86Masks::Masks32.new(backslash, quote, whitespace, op, control)
      end
    end
  end
end
