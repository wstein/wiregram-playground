module Simdjson
  module Stage1
    # Neon provides an optional aarch64 (ARM NEON) accelerated implementation
    # of the 16-byte mask builder used by `Stage1` to detect quotes,
    # backslashes, whitespace, structural characters and control characters.
    #
    # On non-aarch64 targets this module falls back to a scalar implementation
    # that computes the same masks. The `scan16` method returns a `Masks16`
    # struct containing bitmasks for the 16 input bytes.
    module Neon
      # Masks16 holds 16-bit masks for a 16-byte block produced by `scan16`.
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

      # scan16(ptr) -> Masks16
      #
      # Scans 16 bytes at `ptr` and returns a `Masks16` with the following
      # masks set:
      # - `backslash`: bits for backslash characters (`\`).
      # - `quote`: bits for double-quote characters (`\"`).
      # - `whitespace`: bits for ASCII whitespace (space, tab, LF, CR).
      # - `op`: bits for JSON structural operators ({ } [ ] : ,).
      # - `control`: bits for control characters (<= 0x1F).
      #
      # On aarch64 the implementation uses inline NEON assembly for speed.
      # On other platforms a scalar loop computes the same masks.
      def self.scan16(ptr : Pointer(UInt8)) : Masks16
        {% if flag?(:aarch64) %}
          backslash = 0_u16
          quote = 0_u16
          whitespace = 0_u16
          op = 0_u16
          control = 0_u16
          asm(
            %(
            ld1 {v0.16b}, [$5]
            movi v31.16b, 1
            mov w9, 0x0201
            mov v30.h[0], w9
            mov w9, 0x0804
            mov v30.h[1], w9
            mov w9, 0x2010
            mov v30.h[2], w9
            mov w9, 0x8040
            mov v30.h[3], w9
            mov w9, 0x0201
            mov v30.h[4], w9
            mov w9, 0x0804
            mov v30.h[5], w9
            mov w9, 0x2010
            mov v30.h[6], w9
            mov w9, 0x8040
            mov v30.h[7], w9

            movi v1.16b, 92
            cmeq v2.16b, v0.16b, v1.16b
            movi v1.16b, 34
            cmeq v3.16b, v0.16b, v1.16b

            movi v1.16b, 32
            cmeq v4.16b, v0.16b, v1.16b
            movi v1.16b, 9
            cmeq v5.16b, v0.16b, v1.16b
            orr v4.16b, v4.16b, v5.16b
            movi v1.16b, 10
            cmeq v5.16b, v0.16b, v1.16b
            orr v4.16b, v4.16b, v5.16b
            movi v1.16b, 13
            cmeq v5.16b, v0.16b, v1.16b
            orr v4.16b, v4.16b, v5.16b

            movi v1.16b, 123
            cmeq v6.16b, v0.16b, v1.16b
            movi v1.16b, 125
            cmeq v5.16b, v0.16b, v1.16b
            orr v6.16b, v6.16b, v5.16b
            movi v1.16b, 91
            cmeq v5.16b, v0.16b, v1.16b
            orr v6.16b, v6.16b, v5.16b
            movi v1.16b, 93
            cmeq v5.16b, v0.16b, v1.16b
            orr v6.16b, v6.16b, v5.16b
            movi v1.16b, 58
            cmeq v5.16b, v0.16b, v1.16b
            orr v6.16b, v6.16b, v5.16b
            movi v1.16b, 44
            cmeq v5.16b, v0.16b, v1.16b
            orr v6.16b, v6.16b, v5.16b

            movi v1.16b, 31
            cmhs v7.16b, v1.16b, v0.16b

            ushr v2.16b, v2.16b, 7
            and v2.16b, v2.16b, v31.16b
            mul v2.16b, v2.16b, v30.16b
            ext v8.16b, v2.16b, v2.16b, 8
            addv b10, v2.8b
            addv b11, v8.8b
            umov w10, v10.b[0]
            umov w11, v11.b[0]
            orr w10, w10, w11, lsl 8
            mov $0, x10

            ushr v3.16b, v3.16b, 7
            and v3.16b, v3.16b, v31.16b
            mul v3.16b, v3.16b, v30.16b
            ext v8.16b, v3.16b, v3.16b, 8
            addv b10, v3.8b
            addv b11, v8.8b
            umov w10, v10.b[0]
            umov w11, v11.b[0]
            orr w10, w10, w11, lsl 8
            mov $1, x10

            ushr v4.16b, v4.16b, 7
            and v4.16b, v4.16b, v31.16b
            mul v4.16b, v4.16b, v30.16b
            ext v8.16b, v4.16b, v4.16b, 8
            addv b10, v4.8b
            addv b11, v8.8b
            umov w10, v10.b[0]
            umov w11, v11.b[0]
            orr w10, w10, w11, lsl 8
            mov $2, x10

            ushr v6.16b, v6.16b, 7
            and v6.16b, v6.16b, v31.16b
            mul v6.16b, v6.16b, v30.16b
            ext v8.16b, v6.16b, v6.16b, 8
            addv b10, v6.8b
            addv b11, v8.8b
            umov w10, v10.b[0]
            umov w11, v11.b[0]
            orr w10, w10, w11, lsl 8
            mov $3, x10

            ushr v7.16b, v7.16b, 7
            and v7.16b, v7.16b, v31.16b
            mul v7.16b, v7.16b, v30.16b
            ext v8.16b, v7.16b, v7.16b, 8
            addv b10, v7.8b
            addv b11, v8.8b
            umov w10, v10.b[0]
            umov w11, v11.b[0]
            orr w10, w10, w11, lsl 8
            mov $4, x10
            )
            : "=r"(backslash), "=r"(quote), "=r"(whitespace), "=r"(op), "=r"(control)
            : "r"(ptr)
            : "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8", "v10", "v11", "v30", "v31", "w9", "w10", "w11"
            : "volatile"
          )
          Masks16.new(backslash, quote, whitespace, op, control)
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
            when 0x20, 0x09, 0x0a, 0x0d
              whitespace |= bit
            when '{'.ord, '}'.ord, '['.ord, ']'.ord, ':'.ord, ','.ord
              op |= bit
            end
            backslash |= bit if b == '\\'.ord
            quote |= bit if b == '"'.ord
          end
          Masks16.new(backslash, quote, whitespace, op, control)
        {% end %}
      end
    end
  end
end
