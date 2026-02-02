module Warp
  module Lang
    module Common
      module CommentSimd
        def self.line_comment_mask(ptr : Pointer(UInt8), block_len : Int32, marker : UInt8) : UInt64
          mask = 0_u64
          i = 0
          while i < block_len
            mask |= (1_u64 << i) if ptr[i] == marker
            i += 1
          end
          mask
        end

        def self.block_comment_start_mask(ptr : Pointer(UInt8), block_len : Int32, a : UInt8, b : UInt8) : UInt64
          mask = 0_u64
          i = 0
          while i + 1 < block_len
            if ptr[i] == a && ptr[i + 1] == b
              mask |= (1_u64 << i)
              mask |= (1_u64 << (i + 1))
            end
            i += 1
          end
          mask
        end
      end
    end
  end
end
