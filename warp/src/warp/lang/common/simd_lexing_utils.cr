module Warp
  module Lang
    module Common
      module SimdLexingUtils
        def self.build_byte_mask(ptr : Pointer(UInt8), block_len : Int32, target : UInt8) : UInt64
          mask = 0_u64
          i = 0
          while i < block_len
            mask |= (1_u64 << i) if ptr[i] == target
            i += 1
          end
          mask
        end

        def self.scan_to_line_end(bytes : Bytes, start : Int32, backend : Warp::Backend::Base) : Int32
          len = bytes.size
          return len if start >= len
          ptr = bytes.to_unsafe
          i = start
          while i < len
            block_len = len - i
            block_len = 64 if block_len > 64
            mask = backend.newline_mask(ptr + i, block_len)
            if mask != 0
              return i + mask.trailing_zeros_count
            end
            i += 64
          end
          len
        end

        def self.scan_delimited(
          bytes : Bytes,
          start : Int32,
          delimiter : UInt8,
          allow_modifiers : Bool,
          backend : Warp::Backend::Base,
          &modifier_predicate : UInt8 -> Bool
        ) : Int32
          len = bytes.size
          i = start + 1
          return -1 if i >= len

          if delimiter == '"'.ord.to_u8 || delimiter == '\''.ord.to_u8
            indices = StateAwareSimdHelpers.scan_string_interior(bytes, i.to_u32, delimiter, backend)
            idx = indices.find { |pos| bytes[pos.to_i] == delimiter }
            return idx.to_i + 1 if idx
          elsif delimiter == '/'.ord.to_u8 && allow_modifiers
            indices = StateAwareSimdHelpers.scan_regex_interior(bytes, i.to_u32, backend)
            idx = indices.find { |pos| bytes[pos.to_i] == '/'.ord.to_u8 }
            if idx
              end_idx = idx.to_i + 1
              while end_idx < len && modifier_predicate.call(bytes[end_idx])
                end_idx += 1
              end
              return end_idx
            end
          end

          escape_scanner = Warp::Lexer::EscapeScanner.new
          ptr = bytes.to_unsafe

          while i < len
            block_len = len - i
            block_len = 64 if block_len > 64

            masks = backend.build_masks(ptr + i, block_len)
            backslash = masks.backslash
            delim_mask = build_byte_mask(ptr + i, block_len, delimiter)
            escaped = escape_scanner.next(backslash).escaped
            unescaped = delim_mask & ~escaped

            if unescaped != 0
              end_idx = i + unescaped.trailing_zeros_count + 1
              if allow_modifiers
                while end_idx < len && modifier_predicate.call(bytes[end_idx])
                  end_idx += 1
                end
              end
              return end_idx
            end

            i += 64
          end

          -1
        end
      end
    end
  end
end
