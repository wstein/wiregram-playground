# Whitespace-Focused SIMD Scanner for JSON
#
# Simplified structural scanning that focuses on whitespace boundaries
# and language-agnostic patterns. Number/word detection is handled at
# lexer level where language context is available.

module Warp
  module Lexer
    class EnhancedSimdScan
      def self.index(bytes : Bytes) : LexerResult
        ptr = bytes.to_unsafe
        len = bytes.size
        indices = Array(UInt32).new
        scanner = Scanner.new
        unescaped_error = 0_u64
        utf8 = Utf8Validator.new
        backend = Backend.current
        error = ErrorCode::Success

        offset = 0
        while offset < len
          block_len = len - offset
          block_len = 64 if block_len > 64

          unless utf8.consume(ptr + offset, block_len)
            error = ErrorCode::Utf8Error
            break
          end

          masks = backend.build_masks(ptr + offset, block_len)
          block = scanner.next(masks.backslash, masks.quote, masks.whitespace, masks.op)

          # Whitespace-focused: extract structural elements only
          # Number/word boundary detection handled at lexer level with full language context
          outside_string = ~block.strings.in_string
          structural = block.structural_start & outside_string

          if block_len < 64
            structural &= (1_u64 << block_len) - 1_u64
          end

          bits = structural
          while bits != 0
            tz = bits.trailing_zeros_count
            indices << (offset + tz).to_u32
            bits &= bits - 1_u64
          end

          unescaped_error |= block.non_quote_inside_string(masks.control)
          offset += 64
        end

        if error == ErrorCode::Success
          error = scanner.finish
          if error == ErrorCode::Success && !utf8.finish?
            error = ErrorCode::Utf8Error
          end
          if error == ErrorCode::Success && unescaped_error != 0
            error = ErrorCode::UnescapedChars
          end
          if error == ErrorCode::Success && indices.empty?
            error = ErrorCode::Empty
          end
        end

        buffer = LexerBuffer.new(indices.to_unsafe, indices.size, indices)
        LexerResult.new(buffer, error)
      end
    end
  end
end
