module Warp
  module Backend
    class ScalarBackend < Base
      def name : String
        "scalar"
      end

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

          if c <= 0x1f_u8
            control |= bit
          end

          case c
          when 0x20_u8, 0x09_u8
            whitespace |= bit
          when 0x0a_u8, 0x0d_u8
            op |= bit
          when '['.ord, ']'.ord, '{'.ord, '}'.ord, ':'.ord, ','.ord
            op |= bit
          end

          if c == '\\'.ord
            backslash |= bit
          elsif c == '"'.ord
            quote |= bit
          end

          i += 1
        end

        # TODO optimize: partial blocks should be rare with padded inputs.
        if block_len < 64
          whitespace |= ~0_u64 << block_len
        end

        Lexer::Masks.new(backslash, quote, whitespace, op, control)
      end
    end
  end
end
