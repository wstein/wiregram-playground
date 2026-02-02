# Crystal SIMD Scanner
#
# Implements SIMD-optimized structural character scanning for Crystal source code.
# Detects structural elements: strings (single/double quoted), string interpolation,
# symbols, annotations, macros, braces, brackets, parentheses, and other delimiters.
#
# The scanner processes input in 64-byte blocks using SIMD backend optimizations.

module Warp
  module Lang
    module Crystal
      class SimdScanner < Common::StructuralScanner
        @bytes : Bytes
        @indices : Array(UInt32)
        @error : Warp::Core::ErrorCode
        @string_scanner : Warp::Lexer::StringScanner
        @prev_scalar : UInt64 = 0_u64

        def initialize(@bytes : Bytes)
          @indices = Array(UInt32).new
          @error = Warp::Core::ErrorCode::Success
          @string_scanner = Warp::Lexer::StringScanner.new
        end

        def scan : Array(UInt32)
          return @indices if @error != Warp::Core::ErrorCode::Success

          utf8 = Warp::Lexer::Utf8Validator.new
          backend = self.backend
          ptr = @bytes.to_unsafe
          len = @bytes.size
          offset = 0

          while offset < len
            block_len = len - offset
            block_len = 64 if block_len > 64

            # Validate UTF-8 encoding
            unless utf8.consume(ptr + offset, block_len)
              @error = Warp::Core::ErrorCode::Utf8Error
              break
            end

            # Get SIMD masks for structural characters
            masks = backend.build_masks(ptr + offset, block_len)

            # Build structural block based on Crystal-specific patterns
            structural = compute_crystal_structural(masks, block_len, ptr + offset)

            # Extract individual positions from the bitmask
            bits = structural
            while bits != 0
              tz = bits.trailing_zeros_count
              @indices << (offset + tz).to_u32
              bits &= bits - 1_u64
            end

            offset += 64
          end

          # Final validation
          if @error == Warp::Core::ErrorCode::Success
            @error = @string_scanner.finish
            if @error == Warp::Core::ErrorCode::Success && !utf8.finish?
              @error = Warp::Core::ErrorCode::Utf8Error
            end
            if @error == Warp::Core::ErrorCode::Success && @indices.empty?
              @error = Warp::Core::ErrorCode::Empty
            end
          end

          @indices
        end

        def error : Warp::Core::ErrorCode
          @error
        end

        def language_name : String
          "crystal"
        end

        private def compute_crystal_structural(masks : Warp::Lexer::Masks, block_len : Int32, ptr : Pointer(UInt8)) : UInt64
          # Crystal structural characters include:
          # - Quotes (single, double) for strings
          # - String interpolation (#{ })
          # - Symbols (:name)
          # - Annotations (@[...])
          # - Macros ({% %})
          # - Braces/brackets/parens for structure
          # - Operators (=, +, -, etc.)
          # - Comments (# and /* */)

          # Start with quotes and operators
          structural = masks.quote

          # Also include control characters which may include structural chars
          structural |= masks.control

          # We'll need to manually add braces, brackets, parentheses, colons
          # by scanning the byte block directly
          (0...block_len).each do |i|
            byte = ptr[i]
            # Check for Crystal structural characters
            if byte == '{'.ord.to_u8 || byte == '}'.ord.to_u8 ||
               byte == '['.ord.to_u8 || byte == ']'.ord.to_u8 ||
               byte == '('.ord.to_u8 || byte == ')'.ord.to_u8 ||
               byte == ':'.ord.to_u8 || byte == ','.ord.to_u8 ||
               byte == ';'.ord.to_u8 || byte == '='.ord.to_u8 ||
               byte == '@'.ord.to_u8 || byte == '%'.ord.to_u8
              structural |= (1_u64 << i)
            end
          end

          # Mask to block size
          if block_len < 64
            structural &= (1_u64 << block_len) - 1_u64
          end

          structural
        end
      end

      # Convenience function for scanning Crystal source with SIMD
      def self.simd_scan(bytes : Bytes) : Common::ScanResult
        scanner = SimdScanner.new(bytes)
        indices = scanner.scan
        Common::ScanResult.new(indices, scanner.error, scanner.language_name)
      end
    end
  end
end
