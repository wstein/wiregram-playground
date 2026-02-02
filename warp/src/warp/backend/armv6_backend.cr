module Warp
  module Backend
    # ARMv6-optimized backend for Raspberry Pi 1/Zero compatibility
    # ARMv6 lacks NEON SIMD support, so uses scalar approach with
    # ARMv6-compatible instruction sequences.
    #
    # Performance Characteristics:
    # - Single-threaded: ~50-80 MB/s on Pi 1/Zero
    # - Limited memory bandwidth (450 MB/s max)
    # - Small cache sizes (128KB L2 typical)
    # - Suitable for embedded/IoT applications
    #
    # Optimization Strategy:
    # 1. Minimize memory traffic through efficient loops
    # 2. Avoid NEON/SIMD instructions entirely
    # 3. Use lightweight string scanning
    # 4. Consider parallelization disabled for Pi 1 (single core)
    class ARMv6Backend < Base
      def name : String
        "armv6"
      end

      # Build character classification masks using ARMv6-compatible operations
      # This implementation prioritizes memory efficiency and simplicity
      # over parallelism since ARMv6 systems are typically single-core
      def build_masks(ptr : Pointer(UInt8), block_len : Int32) : Lexer::Masks
        backslash = 0_u64
        quote = 0_u64
        whitespace = 0_u64
        op = 0_u64
        control = 0_u64

        i = 0
        while i < block_len
          c = ptr[i]
          bit = 1_u64 << i

          # Control characters (0x00-0x1f)
          if c <= 0x1f_u8
            control |= bit
          end

          # Character classification
          case c
          when 0x20_u8, 0x09_u8 # Space, tab
            whitespace |= bit
          when 0x0a_u8, 0x0d_u8 # Newline, carriage return
            op |= bit
          when '['.ord, ']'.ord, '{'.ord, '}'.ord, ':'.ord, ','.ord
            op |= bit
          end

          # Backslash and quote detection
          if c == '\\'.ord
            backslash |= bit
          elsif c == '"'.ord
            quote |= bit
          end

          i += 1
        end

        # Pad mask for partial blocks
        if block_len < 64
          whitespace |= ~0_u64 << block_len
        end

        number, identifier, unicode_letter = compute_extra_masks(ptr, block_len)
        Lexer::Masks.new(backslash, quote, whitespace, op, control, number, identifier, unicode_letter)
      end

      # Check if 16 bytes are all ASCII digits
      # Optimized for ARMv6 with minimal branching
      def all_digits16?(ptr : Pointer(UInt8)) : Bool
        16.times do |i|
          b = ptr[i]
          return false unless b >= '0'.ord && b <= '9'.ord
        end
        true
      end

      # Create newline mask using simple byte-by-byte scan
      # ARMv6 doesn't have efficient parallel newline detection
      def newline_mask(ptr : Pointer(UInt8), block_len : Int32) : UInt64
        mask = 0_u64
        i = 0
        while i < block_len
          b = ptr[i]
          mask |= (1_u64 << i) if b == 0x0a_u8 || b == 0x0d_u8
          i += 1
        end
        mask
      end

      # ARMv6 scalar implementation for ASCII block detection
      # ARMv6 lacks NEON support, so pure scalar byte-by-byte comparison
      def ascii_block?(ptr : Pointer(UInt8)) : Bool
        i = 0
        while i < 16
          return false if ptr[i] > 0x7F_u8
          i += 1
        end
        true
      end
    end
  end
end
