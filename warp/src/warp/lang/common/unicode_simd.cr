module Warp
  module Lang
    module Common
      module UnicodeSimd
        def self.utf8_lead_mask(ptr : Pointer(UInt8), block_len : Int32) : UInt64
          mask = 0_u64
          i = 0
          while i < block_len
            b = ptr[i]
            if b >= 0x80_u8 && (b & 0xC0_u8) != 0x80_u8
              mask |= (1_u64 << i)
            end
            i += 1
          end
          mask
        end
      end
    end
  end
end
