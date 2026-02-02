module Warp
  module Backend
    class Avx512Backend < Base
      def name : String
        "avx512"
      end

      def build_masks(ptr : Pointer(UInt8), block_len : Int32) : Lexer::Masks
        backslash = 0_u64
        quote = 0_u64
        whitespace = 0_u64
        op = 0_u64
        control = 0_u64

        i = 0
        {% if flag?(:x86_64) && flag?(:avx512bw) %}
          while i + 63 < block_len
            m = X86Masks.scan64(ptr + i)
            shift = i
            backslash |= m.backslash << shift
            quote |= m.quote << shift
            whitespace |= m.whitespace << shift
            op |= m.op << shift
            control |= m.control << shift
            i += 64
          end
        {% elsif flag?(:x86_64) && flag?(:avx2) %}
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
        {% if flag?(:x86_64) && flag?(:avx512bw) %}
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

      def ascii_block?(ptr : Pointer(UInt8)) : Bool
        {% if flag?(:x86_64) && flag?(:avx512bw) %}
          is_ascii = 0_u32
          asm(
            %(
            vmovdqu64 (%%rsi), %%zmm0
            vpxor %%zmm1, %%zmm1, %%zmm1
            vpmaxub %%zmm0, %%zmm1, %%zmm2
            vextracti64x4 $0x1, %%zmm2, %%ymm3
            vpmaxub %%ymm3, %%ymm2, %%ymm4
            vextracti128 $0x1, %%ymm4, %%xmm5
            vpmaxub %%xmm5, %%xmm4, %%xmm6
            vmovd %%xmm6, %%eax
            cmp $0x7F, %%al
            setle %%dl
            movzbl %%dl, $0
            )
            : "=r"(is_ascii)
            : "S"(ptr)
            : "zmm0", "zmm1", "zmm2", "ymm3", "ymm4", "xmm5", "xmm6", "rax", "rdx"
            : "volatile"
          )
          is_ascii != 0
        {% elsif flag?(:x86_64) && flag?(:avx2) %}
          i = 0
          while i < 16
            return false if ptr[i] > 0x7F_u8
            i += 1
          end
          true
        {% else %}
          i = 0
          while i < 16
            return false if ptr[i] > 0x7F_u8
            i += 1
          end
          true
        {% end %}
      end
    end
  end
end
