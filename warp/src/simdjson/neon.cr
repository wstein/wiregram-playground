module Simdjson
  module Stage1
    # Neon provides an optional aarch64 (ARM NEON) accelerated implementation
    # of the 8-byte mask builder used by `Stage1` to detect quotes,
    # backslashes, whitespace, structural characters and control characters.
    #
    # On non-aarch64 targets this module falls back to a scalar implementation
    # that computes the same masks. The `scan8` method returns a `Masks8`
    # struct containing bitmasks for the 8 input bytes.
    module Neon
      # Masks16 holds 16-bit masks for scalar verification paths.
      #
      # Each bit corresponds to a byte in the input block (bit 0 => first
      # byte) and indicates the presence of the corresponding category.
      struct Masks16
        getter backslash : UInt16
        getter quote : UInt16
        getter whitespace : UInt16
        getter op : UInt16
        getter control : UInt16

        def initialize(@backslash : UInt16, @quote : UInt16, @whitespace : UInt16, @op : UInt16, @control : UInt16)
        end
      end

      # Masks8 holds 8-bit masks for an 8-byte block produced by `scan8`.
      struct Masks8
        getter backslash : UInt8
        getter quote : UInt8
        getter whitespace : UInt8
        getter op : UInt8
        getter control : UInt8

        def initialize(@backslash : UInt8, @quote : UInt8, @whitespace : UInt8, @op : UInt8, @control : UInt8)
        end
      end

      # scan8(ptr) -> Masks8
      #
      # Scans 8 bytes at `ptr` and returns a `Masks8` with the same category
      # masks as the scalar verifier, but for a single 8-byte chunk.
      def self.scan8(ptr : Pointer(UInt8)) : Masks8
        {% if flag?(:aarch64) %}
          backslash = 0_u8
          quote = 0_u8
          whitespace = 0_u8
          op = 0_u8
          control = 0_u8
          asm(
            %(
            ld1 {v0.8b}, [$5]
            mov w9, 0x0201
            mov v30.h[0], w9
            mov w9, 0x0804
            mov v30.h[1], w9
            mov w9, 0x2010
            mov v30.h[2], w9
            mov w9, 0x8040
            mov v30.h[3], w9

            movi v1.8b, 92
            cmeq v2.8b, v0.8b, v1.8b
            movi v1.8b, 34
            cmeq v3.8b, v0.8b, v1.8b

            movi v1.8b, 32
            cmeq v4.8b, v0.8b, v1.8b
            movi v1.8b, 9
            cmeq v5.8b, v0.8b, v1.8b
            orr v4.8b, v4.8b, v5.8b
            movi v1.8b, 10
            cmeq v5.8b, v0.8b, v1.8b
            orr v4.8b, v4.8b, v5.8b
            movi v1.8b, 13
            cmeq v5.8b, v0.8b, v1.8b
            orr v4.8b, v4.8b, v5.8b

            movi v1.8b, 123
            cmeq v6.8b, v0.8b, v1.8b
            movi v1.8b, 125
            cmeq v5.8b, v0.8b, v1.8b
            orr v6.8b, v6.8b, v5.8b
            movi v1.8b, 91
            cmeq v5.8b, v0.8b, v1.8b
            orr v6.8b, v6.8b, v5.8b
            movi v1.8b, 93
            cmeq v5.8b, v0.8b, v1.8b
            orr v6.8b, v6.8b, v5.8b
            movi v1.8b, 58
            cmeq v5.8b, v0.8b, v1.8b
            orr v6.8b, v6.8b, v5.8b
            movi v1.8b, 44
            cmeq v5.8b, v0.8b, v1.8b
            orr v6.8b, v6.8b, v5.8b

            movi v1.8b, 31
            cmhs v7.8b, v1.8b, v0.8b

            and v2.8b, v2.8b, v30.8b
            uaddlv h10, v2.8b
            umov w10, v10.h[0]
            uxtb x10, w10
            mov $0, x10

            and v3.8b, v3.8b, v30.8b
            uaddlv h10, v3.8b
            umov w10, v10.h[0]
            uxtb x10, w10
            mov $1, x10

            and v4.8b, v4.8b, v30.8b
            uaddlv h10, v4.8b
            umov w10, v10.h[0]
            uxtb x10, w10
            mov $2, x10

            and v6.8b, v6.8b, v30.8b
            uaddlv h10, v6.8b
            umov w10, v10.h[0]
            uxtb x10, w10
            mov $3, x10

            and v7.8b, v7.8b, v30.8b
            uaddlv h10, v7.8b
            umov w10, v10.h[0]
            uxtb x10, w10
            mov $4, x10
            )
            : "=r"(backslash), "=r"(quote), "=r"(whitespace), "=r"(op), "=r"(control)
            : "r"(ptr)
            : "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7", "v10", "v30", "w9", "w10"
            : "volatile"
          )
          Masks8.new(backslash, quote, whitespace, op, control)
        {% else %}
          backslash = 0_u8
          quote = 0_u8
          whitespace = 0_u8
          op = 0_u8
          control = 0_u8
          8.times do |i|
            b = ptr[i]
            bit = 1_u8 << i
            control |= bit if b <= 0x1f
            case b
            when 0x20, 0x09, 0x0a, 0x0d
              whitespace |= bit
            when '{'.ord, '}'.ord, '['.ord, ']'.ord, ':'.ord, ','.ord
              op |= bit
            end
            backslash |= bit if b == '\\'.ord
            quote |= bit if b == '"'.ord
          end
          Masks8.new(backslash, quote, whitespace, op, control)
        {% end %}
      end

    end
  end
end
