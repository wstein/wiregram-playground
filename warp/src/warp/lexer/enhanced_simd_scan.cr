# Enhanced SIMD Scanner for JSON
#
# Extends structural scanning with number/identifier/unicode detection while
# preserving the existing JSON structural behavior.

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

        prev_number = 0_u64
        prev_word = 0_u64

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

          number_mask = masks.number
          word_mask = masks.word

          number_start = number_mask & ~((number_mask << 1) | prev_number)
          word_start = word_mask & ~((word_mask << 1) | prev_word)

          prev_number = number_mask >> 63
          prev_word = word_mask >> 63

          outside_string = ~block.strings.in_string

          structural = block.structural_start
          structural |= number_start & outside_string
          structural |= word_start & outside_string

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
