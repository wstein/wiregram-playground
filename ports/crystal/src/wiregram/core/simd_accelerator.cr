# frozen_string_literal: true

module WireGram
  module Core
    # SIMD Accelerator for Apple M4 (NEON / AdvSIMD)
    # Uses inline assembly for maximum performance.
    module SimdAccelerator
      # Scans a 16-byte block for structural characters: { } [ ] : , " \ = ; # / and whitespace.
      # Returns a bitmask where each bit corresponds to a match in the block.
      #
      # Structural characters:
      # { (0x7b), } (0x7d), [ (0x5b), ] (0x5d), : (0x3a), , (0x2c), " (0x22), \ (0x5c)
      # = (0x3d), ; (0x3b), # (0x23), / (0x2f)
      # Whitespace:
      # ' ' (0x20), \t (0x09), \n (0x0a), \r (0x0d)
      def self.find_structural_bits(ptr : Pointer(UInt8)) : {UInt16, Bool}
        {% if flag?(:aarch64) %}
          # On AArch64 (Apple M4), we use NEON intrinsics via inline assembly.
          # We load 16 bytes into a v-register.
          # We compare with multiple target characters.

          mask = 0_u16
          max_byte = 0_u8
          asm("
            ld1 {v0.16b}, [$2]
            orr v5.16b, v0.16b, v0.16b
            # match whitespace (<= 0x20)
            movi v1.16b, 32
            cmhs v2.16b, v1.16b, v0.16b
            # match characters \" (34), \\ (92), { (123), } (125), [ (91), ] (93), : (58), , (44), = (61), ; (59), # (35), / (47)
            movi v3.16b, 34
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b
            movi v3.16b, 92
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b
            movi v3.16b, 123
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b
            movi v3.16b, 125
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b
            movi v3.16b, 91
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b
            movi v3.16b, 93
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b
            movi v3.16b, 58
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b
            movi v3.16b, 44
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b
            movi v3.16b, 61
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b
            movi v3.16b, 59
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b
            movi v3.16b, 35
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b
            movi v3.16b, 47
            cmeq v4.16b, v0.16b, v3.16b
            orr v2.16b, v2.16b, v4.16b

            # Extract bitmask from comparison results
            ushr v0.16b, v2.16b, 7
            movi v1.16b, 1
            and v0.16b, v0.16b, v1.16b

            # Prepare power-of-2 weights for each byte in the 16-byte block
            # This constant can be moved out of the loop in a more advanced implementation,
            # but for now, we keep it here for simplicity and to stay within a single asm block.
            mov w2, 0x0201
            mov v1.h[0], w2
            mov w2, 0x0804
            mov v1.h[1], w2
            mov w2, 0x2010
            mov v1.h[2], w2
            mov w2, 0x8040
            mov v1.h[3], w2
            mov w2, 0x0201
            mov v1.h[4], w2
            mov w2, 0x0804
            mov v1.h[5], w2
            mov w2, 0x2010
            mov v1.h[6], w2
            mov w2, 0x8040
            mov v1.h[7], w2

            mul v0.16b, v0.16b, v1.16b

            # Sum up the bits to get a single 16-bit mask
            # Lower 8 bits in v0[0..7], Upper 8 bits in v1[0..7]
            # We use addv to sum across the 8-byte lanes.
            ext v1.16b, v0.16b, v0.16b, 8
            addv b2, v0.8b
            addv b3, v1.8b
            umov w2, v2.b[0]
            umov w3, v3.b[0]
            orr w2, w2, w3, lsl 8
            mov $0, x2

            # ASCII check: find max byte in preserved v5
            umaxv b2, v5.16b
            umov w3, v2.b[0]
            mov $1, x3"
            : "=r"(mask), "=r"(max_byte) : "r"(ptr) : "v0", "v1", "v2", "v3", "v4", "v5", "w2", "w3"
            : "volatile"
          )
          {mask, (max_byte & 0xFF) < 0x80}
        {% else %}
          # Fallback for non-ARM64 (development/testing on other archs)
          mask = 0_u16
          is_ascii = true
          16.times do |i|
            b = ptr[i]
            is_ascii = false if b >= 0x80
            if b <= 0x20 || b == 0x7b || b == 0x7d || b == 0x5b || b == 0x5d || b == 0x3a || b == 0x2c || b == 0x22 || b == 0x5c || b == 0x3d || b == 0x3b || b == 0x23 || b == 0x2f
              mask |= (1_u16 << i)
            end
          end
          {mask, is_ascii}
        {% end %}
      end

      # Validates a 16-byte block for UTF-8 and checks for non-ASCII characters.
      # Returns true if all bytes are ASCII (0x00-0x7F).
      def self.is_ascii_16?(ptr : Pointer(UInt8)) : Bool
        {% if flag?(:aarch64) %}
          res = 0_u64
          asm(
            "ld1 {v0.16b}, [$1]      \n\t"
            "umaxv b0, v0.16b         \n\t" # Find max byte in 16 bytes
            "mov $0, v0.d[0]          \n\t"
            : "=r"(res) : "r"(ptr) : "v0"
          )
          (res & 0xFF) < 0x80
        {% else %}
          16.times do |i|
            return false if ptr[i] >= 0x80
          end
          true
        {% end %}
      end
    end
  end
end
