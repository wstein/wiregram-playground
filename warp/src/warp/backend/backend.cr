module Warp
  module Backend
    abstract class Base
      abstract def build_masks(ptr : Pointer(UInt8), block_len : Int32) : Lexer::Masks
      abstract def all_digits16?(ptr : Pointer(UInt8)) : Bool
      abstract def newline_mask(ptr : Pointer(UInt8), block_len : Int32) : UInt64

      # Default scalar fallback for ASCII probe. Backends may override with SIMD.
      def ascii_block?(ptr : Pointer(UInt8)) : Bool
        i = 0
        while i < 16
          return false if ptr[i] > 0x7F_u8
          i += 1
        end
        true
      end

      # Default scalar fallback for 16-byte UTF-8 validation. Backends may override.
      def validate_block(ptr : Pointer(UInt8), state : UInt32*) : Bool
        val = state.value
        remaining = (val & 0xFF).to_i
        first_min = ((val >> 8) & 0xFF).to_u8
        first_max = ((val >> 16) & 0xFF).to_u8
        pending = ((val >> 24) & 0x01) == 1

        if remaining == 0 && !pending && ascii_block?(ptr)
          return true
        end

        i = 0
        while i < 16
          b = (ptr + i).value
          if remaining == 0
            case b
            when 0x00_u8..0x7F_u8
              # ASCII already filtered; still allow here.
            when 0xC2_u8..0xDF_u8
              remaining = 1
              pending = false
            when 0xE0_u8
              remaining = 2
              pending = true
              first_min = 0xA0_u8
              first_max = 0xBF_u8
            when 0xE1_u8..0xEC_u8, 0xEE_u8..0xEF_u8
              remaining = 2
              pending = false
            when 0xED_u8
              remaining = 2
              pending = true
              first_min = 0x80_u8
              first_max = 0x9F_u8
            when 0xF0_u8
              remaining = 3
              pending = true
              first_min = 0x90_u8
              first_max = 0xBF_u8
            when 0xF1_u8..0xF3_u8
              remaining = 3
              pending = false
            when 0xF4_u8
              remaining = 3
              pending = true
              first_min = 0x80_u8
              first_max = 0x8F_u8
            else
              return false
            end
          else
            if pending
              return false if b < first_min || b > first_max
              pending = false
              remaining -= 1
            else
              return false unless b >= 0x80 && b <= 0xBF
              remaining -= 1
            end
          end
          i += 1
        end

        if remaining == 0 && !pending
          first_min = 0_u8
          first_max = 0_u8
        end
        out = remaining.to_u32 | (first_min.to_u32 << 8) | (first_max.to_u32 << 16) | (pending ? 1_u32 << 24 : 0_u32)
        state.value = out
        true
      end

      protected def compute_extra_masks(ptr : Pointer(UInt8), block_len : Int32) : Tuple(UInt64, UInt64, UInt64)
        number = 0_u64
        identifier = 0_u64
        unicode_letter = 0_u64

        i = 0
        while i < block_len
          b = ptr[i]
          bit = 1_u64 << i

          if (b >= '0'.ord.to_u8 && b <= '9'.ord.to_u8) || b == '.'.ord.to_u8 || b == 'e'.ord.to_u8 || b == 'E'.ord.to_u8
            number |= bit
          end

          if (b >= 'a'.ord.to_u8 && b <= 'z'.ord.to_u8) || (b >= 'A'.ord.to_u8 && b <= 'Z'.ord.to_u8) || b == '_'.ord.to_u8
            identifier |= bit
          end

          if b >= 0x80_u8 && (b & 0xC0_u8) != 0x80_u8
            unicode_letter |= bit
          end

          i += 1
        end

        {number, identifier, unicode_letter}
      end

      abstract def name : String
    end
  end
end
