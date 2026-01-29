module Warp
  module Backend
    class NeonBackend < Base
      VERIFY_BACKEND = (ENV["WARP_VERIFY_BACKEND"]? == "1") ||
        (ENV["SIMDJSON_VERIFY_BACKEND"]? == "1") ||
        (ENV["SIMDJSON_VERIFY_NEON"]? == "1")

      def name : String
        "neon"
      end

      def build_masks(ptr : Pointer(UInt8), block_len : Int32) : Lexer::Masks
        backslash = 0_u64
        quote = 0_u64
        whitespace = 0_u64
        op = 0_u64
        control = 0_u64

        i = 0
        {% if flag?(:aarch64) %}
          while i + 15 < block_len
            m = NeonMasks.scan16(ptr + i)
            if VERIFY_BACKEND
              scalar = scalar_masks(ptr + i, 16)
              if scalar.backslash != m.backslash ||
                 scalar.quote != m.quote ||
                 scalar.whitespace != m.whitespace ||
                 scalar.op != m.op ||
                 scalar.control != m.control
                m = scalar
              end
            end
            shift = i
            backslash |= m.backslash.to_u64 << shift
            quote |= m.quote.to_u64 << shift
            whitespace |= m.whitespace.to_u64 << shift
            op |= m.op.to_u64 << shift
            control |= m.control.to_u64 << shift
            i += 16
          end
          while i + 7 < block_len
            m = NeonMasks.scan8(ptr + i)
            if VERIFY_BACKEND
              scalar = scalar_masks(ptr + i, 8)
              if (scalar.backslash & 0xff_u16).to_u8 != m.backslash ||
                 (scalar.quote & 0xff_u16).to_u8 != m.quote ||
                 (scalar.whitespace & 0xff_u16).to_u8 != m.whitespace ||
                 (scalar.op & 0xff_u16).to_u8 != m.op ||
                 (scalar.control & 0xff_u16).to_u8 != m.control
                m = NeonMasks::Masks8.new(
                  (scalar.backslash & 0xff_u16).to_u8,
                  (scalar.quote & 0xff_u16).to_u8,
                  (scalar.whitespace & 0xff_u16).to_u8,
                  (scalar.op & 0xff_u16).to_u8,
                  (scalar.control & 0xff_u16).to_u8
                )
              end
            end
            shift = i
            backslash |= m.backslash.to_u64 << shift
            quote |= m.quote.to_u64 << shift
            whitespace |= m.whitespace.to_u64 << shift
            op |= m.op.to_u64 << shift
            control |= m.control.to_u64 << shift
            i += 8
          end
        {% end %}

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

        if block_len < 64
          whitespace |= ~0_u64 << block_len
        end

        Lexer::Masks.new(backslash, quote, whitespace, op, control)
      end

      private def scalar_masks(ptr : Pointer(UInt8), len : Int32) : NeonMasks::Masks16
        backslash = 0_u16
        quote = 0_u16
        whitespace = 0_u16
        op = 0_u16
        control = 0_u16

        i = 0
        while i < len
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
          i += 1
        end

        NeonMasks::Masks16.new(backslash, quote, whitespace, op, control)
      end
    end
  end
end
