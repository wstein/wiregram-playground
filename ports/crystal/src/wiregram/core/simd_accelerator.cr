# frozen_string_literal: true

module WireGram
  module Core
    # SIMD Accelerator for Apple M4 (NEON / AdvSIMD)
    # Uses inline assembly for maximum performance.
    module SimdAccelerator
      # Scans a 16-byte block for structural characters: { } [ ] : , " \ and whitespace.
      # Returns a bitmask where each bit corresponds to a match in the block.
      #
      # Structural characters:
      # { (0x7b), } (0x7d), [ (0x5b), ] (0x5d), : (0x3a), , (0x2c), " (0x22), \ (0x5c)
      # Whitespace:
      # ' ' (0x20), \t (0x09), \n (0x0a), \r (0x0d)
      def self.find_structural_bits(ptr : Pointer(UInt8)) : {UInt16, Bool}
        {% if flag?(:aarch64) %}
          # On AArch64 (Apple M4), we use NEON intrinsics via inline assembly.
          # We load 16 bytes into a v-register.
          # We compare with multiple target characters.

          # Optimization: We can use bitwise OR to combine matches.
          # A more advanced approach (simdjson style) uses range-based classification,
          # but for simplicity and clarity in Crystal's inline asm, we'll start with
          # identifying the most common structural delimiters.

          mask = 0_u16
          max_byte = 0_u8
          asm("
            ld1 {v0.16b}, [$2]
            orr v5.16b, v0.16b, v0.16b
            movi v1.16b, 32
            cmhs v2.16b, v1.16b, v0.16b
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
            ushr v0.16b, v2.16b, 7
            movi v1.16b, 1
            and v0.16b, v0.16b, v1.16b
            mov w2, 1
            mov v1.b[0], w2
            mov w2, 2
            mov v1.b[1], w2
            mov w2, 4
            mov v1.b[2], w2
            mov w2, 8
            mov v1.b[3], w2
            mov w2, 16
            mov v1.b[4], w2
            mov w2, 32
            mov v1.b[5], w2
            mov w2, 64
            mov v1.b[6], w2
            mov w2, 128
            mov v1.b[7], w2
            mov w2, 1
            mov v1.b[8], w2
            mov w2, 2
            mov v1.b[9], w2
            mov w2, 4
            mov v1.b[10], w2
            mov w2, 8
            mov v1.b[11], w2
            mov w2, 16
            mov v1.b[12], w2
            mov w2, 32
            mov v1.b[13], w2
            mov w2, 64
            mov v1.b[14], w2
            mov w2, 128
            mov v1.b[15], w2
            mul v0.16b, v0.16b, v1.16b
            ext v1.16b, v0.16b, v0.16b, 8
            addv b2, v0.8b
            addv b3, v1.8b
            umov w2, v2.b[0]
            umov w3, v3.b[0]
            orr w2, w2, w3, lsl 8
            mov $0, x2
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
            if b <= 0x20 || b == 0x7b || b == 0x7d || b == 0x5b || b == 0x5d || b == 0x3a || b == 0x2c || b == 0x22 || b == 0x5c
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
