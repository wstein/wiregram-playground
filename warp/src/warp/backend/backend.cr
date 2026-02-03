module Warp
  module Backend
    abstract class Base
      abstract def build_masks(ptr : Pointer(UInt8), block_len : Int32) : Lexer::Masks
      abstract def all_digits16?(ptr : Pointer(UInt8)) : Bool
      abstract def newline_mask(ptr : Pointer(UInt8), block_len : Int32) : UInt64

      # State-aware mask builder. Defaults to root behavior when no state is provided.
      # This keeps SIMD/backends unchanged while allowing context-specific adjustments.
      def build_masks_with_state(ptr : Pointer(UInt8), block_len : Int32, state : Lexer::LexerState? = nil) : Lexer::Masks
        masks = build_masks(ptr, block_len)
        return masks unless state

        case state.current
        when Lexer::LexerState::State::String,
             Lexer::LexerState::State::StringEscape,
             Lexer::LexerState::State::Comment,
             Lexer::LexerState::State::Regex,
             Lexer::LexerState::State::Heredoc,
             Lexer::LexerState::State::Macro,
             Lexer::LexerState::State::Annotation
          # In string/comment-like contexts, structural operators are not meaningful.
          Lexer::Masks.new(masks.backslash, masks.quote, masks.whitespace, 0_u64, masks.control, masks.utf8_lead)
        else
          masks
        end
      end

      # Default scalar fallback for ASCII probe. Backends may override with SIMD.
      def ascii_block?(ptr : Pointer(UInt8)) : Bool
        i = 0
        while i < 16
          return false if ptr[i] > 0x7F_u8
          i += 1
        end
        true
      end

      # Optional alignment check - enabled via WARP_STRICT_ALIGNMENT=1. Returns
      # `ErrorCode::SimdAlignmentError` when the pointer is not aligned to the
      # expected SIMD width for strict backends.
      # Default alignment check by offset. Backends may override for architecture-specific widths.
      def check_alignment_offset(offset : Int32) : Warp::Core::ErrorCode
        if ENV["WARP_STRICT_ALIGNMENT"]? == "1"
          if (offset % 16) != 0
            return Warp::Core::ErrorCode::SimdAlignmentError
          end
        end
        Warp::Core::ErrorCode::Success
      end

      # Convenience shim preserving the (deprecated) pointer API for callers that
      # previously passed a pointer directly. This computes an offset of zero and
      # delegates to the offset-based check.
      def check_alignment(ptr : Pointer(UInt8)) : Warp::Core::ErrorCode
        check_alignment_offset(0)
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

      # Compute UTF-8 leading byte mask only
      # Whitespace and structural detection is primary; word/number boundaries are handled at lexer level
      protected def compute_utf8_mask(ptr : Pointer(UInt8), block_len : Int32) : UInt64
        utf8_lead = 0_u64

        i = 0
        while i < block_len
          b = ptr[i]
          bit = 1_u64 << i

          # UTF-8 leading bytes: 0x80-0xFF but not continuation bytes (0x80-0xBF)
          if b >= 0x80_u8 && (b & 0xC0_u8) != 0x80_u8
            utf8_lead |= bit
          end

          i += 1
        end

        utf8_lead
      end

      abstract def name : String
    end
  end
end
