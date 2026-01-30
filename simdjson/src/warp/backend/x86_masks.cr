module Warp
  module Backend
    # X86 SIMD helpers for building lexer masks on x86_64 targets.
    module X86Masks
      struct Masks16
        getter backslash : UInt16
        getter quote : UInt16
        getter whitespace : UInt16
        getter op : UInt16
        getter control : UInt16

        def initialize(@backslash : UInt16, @quote : UInt16, @whitespace : UInt16, @op : UInt16, @control : UInt16)
        end
      end

      struct Masks32
        getter backslash : UInt32
        getter quote : UInt32
        getter whitespace : UInt32
        getter op : UInt32
        getter control : UInt32

        def initialize(@backslash : UInt32, @quote : UInt32, @whitespace : UInt32, @op : UInt32, @control : UInt32)
        end
      end

      struct Masks64
        getter backslash : UInt64
        getter quote : UInt64
        getter whitespace : UInt64
        getter op : UInt64
        getter control : UInt64

        def initialize(@backslash : UInt64, @quote : UInt64, @whitespace : UInt64, @op : UInt64, @control : UInt64)
        end
      end

      private BACKSLASH_16 = StaticArray(UInt8, 16).new('\\'.ord.to_u8)
      private QUOTE_16 = StaticArray(UInt8, 16).new('"'.ord.to_u8)
      private SPACE_16 = StaticArray(UInt8, 16).new(0x20_u8)
      private TAB_16 = StaticArray(UInt8, 16).new(0x09_u8)
      private LF_16 = StaticArray(UInt8, 16).new(0x0a_u8)
      private CR_16 = StaticArray(UInt8, 16).new(0x0d_u8)
      private LBRACE_16 = StaticArray(UInt8, 16).new('{'.ord.to_u8)
      private RBRACE_16 = StaticArray(UInt8, 16).new('}'.ord.to_u8)
      private LBRACKET_16 = StaticArray(UInt8, 16).new('['.ord.to_u8)
      private RBRACKET_16 = StaticArray(UInt8, 16).new(']'.ord.to_u8)
      private COLON_16 = StaticArray(UInt8, 16).new(':'.ord.to_u8)
      private COMMA_16 = StaticArray(UInt8, 16).new(','.ord.to_u8)
      private XOR80_16 = StaticArray(UInt8, 16).new(0x80_u8)
      private THRESH_16 = StaticArray(UInt8, 16).new(0x9f_u8)

      private BACKSLASH_1 = StaticArray(UInt8, 1).new('\\'.ord.to_u8)
      private QUOTE_1 = StaticArray(UInt8, 1).new('"'.ord.to_u8)
      private SPACE_1 = StaticArray(UInt8, 1).new(0x20_u8)
      private TAB_1 = StaticArray(UInt8, 1).new(0x09_u8)
      private LF_1 = StaticArray(UInt8, 1).new(0x0a_u8)
      private CR_1 = StaticArray(UInt8, 1).new(0x0d_u8)
      private LBRACE_1 = StaticArray(UInt8, 1).new('{'.ord.to_u8)
      private RBRACE_1 = StaticArray(UInt8, 1).new('}'.ord.to_u8)
      private LBRACKET_1 = StaticArray(UInt8, 1).new('['.ord.to_u8)
      private RBRACKET_1 = StaticArray(UInt8, 1).new(']'.ord.to_u8)
      private COLON_1 = StaticArray(UInt8, 1).new(':'.ord.to_u8)
      private COMMA_1 = StaticArray(UInt8, 1).new(','.ord.to_u8)
      private XOR80_1 = StaticArray(UInt8, 1).new(0x80_u8)
      private THRESH_1 = StaticArray(UInt8, 1).new(0x9f_u8)

      private ZERO_XOR80_16 = StaticArray(UInt8, 16).new(('0'.ord ^ 0x80).to_u8)
      private NINE_XOR80_16 = StaticArray(UInt8, 16).new(('9'.ord ^ 0x80).to_u8)

      def self.scan16(ptr : Pointer(UInt8)) : Masks16
        {% if flag?(:x86_64) && flag?(:sse2) %}
          backslash32 = 0_u32
          quote32 = 0_u32
          whitespace32 = 0_u32
          op32 = 0_u32
          control32 = 0_u32
          asm(
            %(
            movdqu ($5), %xmm0

            movdqa %xmm0, %xmm1
            pcmpeqb ($6), %xmm1
            pmovmskb %xmm1, $0

            movdqa %xmm0, %xmm1
            pcmpeqb ($7), %xmm1
            pmovmskb %xmm1, $1

            movdqa %xmm0, %xmm1
            pcmpeqb ($8), %xmm1
            movdqa %xmm0, %xmm2
            pcmpeqb ($9), %xmm2
            por %xmm2, %xmm1
            pmovmskb %xmm1, $2

            movdqa %xmm0, %xmm1
            pcmpeqb ($12), %xmm1
            movdqa %xmm0, %xmm2
            pcmpeqb ($13), %xmm2
            por %xmm2, %xmm1
            movdqa %xmm0, %xmm2
            pcmpeqb ($14), %xmm2
            por %xmm2, %xmm1
            movdqa %xmm0, %xmm2
            pcmpeqb ($15), %xmm2
            por %xmm2, %xmm1
            movdqa %xmm0, %xmm2
            pcmpeqb ($16), %xmm2
            por %xmm2, %xmm1
            movdqa %xmm0, %xmm2
            pcmpeqb ($17), %xmm2
            por %xmm2, %xmm1
            movdqa %xmm0, %xmm2
            pcmpeqb ($10), %xmm2
            por %xmm2, %xmm1
            movdqa %xmm0, %xmm2
            pcmpeqb ($11), %xmm2
            por %xmm2, %xmm1
            pmovmskb %xmm1, $3

            movdqa %xmm0, %xmm1
            pxor ($18), %xmm1
            movdqu ($19), %xmm2
            pcmpgtb %xmm2, %xmm1
            pcmpeqb %xmm3, %xmm3
            pxor %xmm3, %xmm1
            pmovmskb %xmm1, $4
            )
            : "=r"(backslash32), "=r"(quote32), "=r"(whitespace32), "=r"(op32), "=r"(control32)
            : "r"(ptr),
              "r"(BACKSLASH_16.to_unsafe), "r"(QUOTE_16.to_unsafe), "r"(SPACE_16.to_unsafe), "r"(TAB_16.to_unsafe),
              "r"(LF_16.to_unsafe), "r"(CR_16.to_unsafe), "r"(LBRACE_16.to_unsafe), "r"(RBRACE_16.to_unsafe),
              "r"(LBRACKET_16.to_unsafe), "r"(RBRACKET_16.to_unsafe), "r"(COLON_16.to_unsafe), "r"(COMMA_16.to_unsafe),
              "r"(XOR80_16.to_unsafe), "r"(THRESH_16.to_unsafe)
            : "xmm0", "xmm1", "xmm2", "xmm3", "memory"
            : "volatile"
          )
          Masks16.new(
            backslash32.to_u16,
            quote32.to_u16,
            whitespace32.to_u16,
            op32.to_u16,
            control32.to_u16
          )
        {% else %}
          backslash = 0_u16
          quote = 0_u16
          whitespace = 0_u16
          op = 0_u16
          control = 0_u16
          16.times do |i|
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
          end
          Masks16.new(backslash, quote, whitespace, op, control)
        {% end %}
      end

      def self.scan32(ptr : Pointer(UInt8)) : Masks32
        {% if flag?(:x86_64) && flag?(:avx2) %}
          backslash32 = 0_u32
          quote32 = 0_u32
          whitespace32 = 0_u32
          op32 = 0_u32
          control32 = 0_u32
          asm(
            %(
            vmovdqu ($5), %ymm0

            vpbroadcastb ($6), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm2
            vpmovmskb %ymm2, $0

            vpbroadcastb ($7), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm2
            vpmovmskb %ymm2, $1

            vpbroadcastb ($8), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm2
            vpbroadcastb ($9), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm3
            vpor %ymm3, %ymm2, %ymm2
            vpmovmskb %ymm2, $2

            vpbroadcastb ($12), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm2
            vpbroadcastb ($13), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm3
            vpor %ymm3, %ymm2, %ymm2
            vpbroadcastb ($14), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm3
            vpor %ymm3, %ymm2, %ymm2
            vpbroadcastb ($15), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm3
            vpor %ymm3, %ymm2, %ymm2
            vpbroadcastb ($16), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm3
            vpor %ymm3, %ymm2, %ymm2
            vpbroadcastb ($17), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm3
            vpor %ymm3, %ymm2, %ymm2
            vpbroadcastb ($10), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm3
            vpor %ymm3, %ymm2, %ymm2
            vpbroadcastb ($11), %ymm1
            vpcmpeqb %ymm1, %ymm0, %ymm3
            vpor %ymm3, %ymm2, %ymm2
            vpmovmskb %ymm2, $3

            vpbroadcastb ($18), %ymm1
            vpxor %ymm1, %ymm0, %ymm2
            vpbroadcastb ($19), %ymm1
            vpcmpgtb %ymm1, %ymm2, %ymm2
            vpxor %ymm3, %ymm3, %ymm3
            vpcmpeqb %ymm3, %ymm3, %ymm3
            vpxor %ymm3, %ymm2, %ymm2
            vpmovmskb %ymm2, $4
            vzeroupper
            )
            : "=r"(backslash32), "=r"(quote32), "=r"(whitespace32), "=r"(op32), "=r"(control32)
            : "r"(ptr),
              "r"(BACKSLASH_1.to_unsafe), "r"(QUOTE_1.to_unsafe), "r"(SPACE_1.to_unsafe), "r"(TAB_1.to_unsafe),
              "r"(LF_1.to_unsafe), "r"(CR_1.to_unsafe), "r"(LBRACE_1.to_unsafe), "r"(RBRACE_1.to_unsafe),
              "r"(LBRACKET_1.to_unsafe), "r"(RBRACKET_1.to_unsafe), "r"(COLON_1.to_unsafe), "r"(COMMA_1.to_unsafe),
              "r"(XOR80_1.to_unsafe), "r"(THRESH_1.to_unsafe)
            : "ymm0", "ymm1", "ymm2", "ymm3", "memory"
            : "volatile"
          )
          Masks32.new(backslash32, quote32, whitespace32, op32, control32)
        {% else %}
          backslash = 0_u32
          quote = 0_u32
          whitespace = 0_u32
          op = 0_u32
          control = 0_u32
          32.times do |i|
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
          end
          Masks32.new(backslash, quote, whitespace, op, control)
        {% end %}
      end

      def self.scan32_combined(ptr : Pointer(UInt8)) : Masks32
        low = scan16(ptr)
        high = scan16(ptr + 16)
        Masks32.new(
          low.backslash.to_u32 | (high.backslash.to_u32 << 16),
          low.quote.to_u32 | (high.quote.to_u32 << 16),
          low.whitespace.to_u32 | (high.whitespace.to_u32 << 16),
          low.op.to_u32 | (high.op.to_u32 << 16),
          low.control.to_u32 | (high.control.to_u32 << 16)
        )
      end

      def self.scan64(ptr : Pointer(UInt8)) : Masks64
        {% if flag?(:x86_64) && flag?(:avx512bw) %}
          backslash = 0_u64
          quote = 0_u64
          whitespace = 0_u64
          op = 0_u64
          control = 0_u64
          asm(
            %(
            vmovdqu8 ($5), %zmm0

            vpbroadcastb ($6), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k1
            kmovq %k1, $0

            vpbroadcastb ($7), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k2
            kmovq %k2, $1

            vpbroadcastb ($8), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k3
            vpbroadcastb ($9), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k4
            korq %k4, %k3, %k3
            kmovq %k3, $2

            vpbroadcastb ($12), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k5
            vpbroadcastb ($13), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k6
            korq %k6, %k5, %k5
            vpbroadcastb ($14), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k6
            korq %k6, %k5, %k5
            vpbroadcastb ($15), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k6
            korq %k6, %k5, %k5
            vpbroadcastb ($16), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k6
            korq %k6, %k5, %k5
            vpbroadcastb ($17), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k6
            korq %k6, %k5, %k5
            vpbroadcastb ($10), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k6
            korq %k6, %k5, %k5
            vpbroadcastb ($11), %zmm1
            vpcmpeqb %zmm1, %zmm0, %k6
            korq %k6, %k5, %k5
            kmovq %k5, $3

            vpbroadcastb ($18), %zmm1
            vpxord %zmm1, %zmm0, %zmm2
            vpbroadcastb ($19), %zmm1
            vpcmpgtb %zmm1, %zmm2, %k1
            knotq %k1, %k1
            kmovq %k1, $4
            )
            : "=r"(backslash), "=r"(quote), "=r"(whitespace), "=r"(op), "=r"(control)
            : "r"(ptr),
              "r"(BACKSLASH_1.to_unsafe), "r"(QUOTE_1.to_unsafe), "r"(SPACE_1.to_unsafe), "r"(TAB_1.to_unsafe),
              "r"(LF_1.to_unsafe), "r"(CR_1.to_unsafe), "r"(LBRACE_1.to_unsafe), "r"(RBRACE_1.to_unsafe),
              "r"(LBRACKET_1.to_unsafe), "r"(RBRACKET_1.to_unsafe), "r"(COLON_1.to_unsafe), "r"(COMMA_1.to_unsafe),
              "r"(XOR80_1.to_unsafe), "r"(THRESH_1.to_unsafe)
            : "zmm0", "zmm1", "zmm2", "k1", "k2", "k3", "k4", "k5", "k6", "memory"
            : "volatile"
          )
          Masks64.new(backslash, quote, whitespace, op, control)
        {% else %}
          backslash = 0_u64
          quote = 0_u64
          whitespace = 0_u64
          op = 0_u64
          control = 0_u64
          64.times do |i|
            b = ptr[i]
            bit = 1_u64 << i
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
          end
          Masks64.new(backslash, quote, whitespace, op, control)
        {% end %}
      end

      def self.all_digits16?(ptr : Pointer(UInt8)) : Bool
        {% if flag?(:x86_64) && flag?(:sse2) %}
          mask = 0_u32
          asm(
            %(
            movdqu ($1), %xmm0
            movdqa %xmm0, %xmm1
            pxor ($2), %xmm1

            movdqa %xmm1, %xmm2
            pcmpgtb ($3), %xmm2

            movdqa ($4), %xmm3
            pcmpgtb %xmm1, %xmm3

            por %xmm3, %xmm2
            pmovmskb %xmm2, $0
            )
            : "=r"(mask)
            : "r"(ptr),
              "r"(XOR80_16.to_unsafe),
              "r"(NINE_XOR80_16.to_unsafe),
              "r"(ZERO_XOR80_16.to_unsafe)
            : "xmm0", "xmm1", "xmm2", "xmm3", "memory"
            : "volatile"
          )
          mask == 0_u32
        {% else %}
          16.times do |i|
            b = ptr[i]
            return false unless b >= '0'.ord && b <= '9'.ord
          end
          true
        {% end %}
      end
    end
  end
end
