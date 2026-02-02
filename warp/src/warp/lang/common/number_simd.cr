module Warp
  module Lang
    module Common
      module NumberSimd
        def self.number_mask(ptr : Pointer(UInt8), block_len : Int32) : UInt64
          mask = 0_u64
          i = 0
          while i < block_len
            b = ptr[i]
            if (b >= '0'.ord.to_u8 && b <= '9'.ord.to_u8) || b == '.'.ord.to_u8 || b == 'e'.ord.to_u8 || b == 'E'.ord.to_u8
              mask |= (1_u64 << i)
            end
            i += 1
          end
          mask
        end

        def self.start_mask(number_mask : UInt64, prev_tail : UInt64) : Tuple(UInt64, UInt64)
          start = number_mask & ~((number_mask << 1) | prev_tail)
          {start, number_mask >> 63}
        end
      end
    end
  end
end
