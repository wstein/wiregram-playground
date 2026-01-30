module Warp
  module Backend
    # Scalar-only X86Masks replacement used by the Ruby transpiler phase.
    module X86Masks
      struct Masks16
        getter backslash : UInt16
        getter quote : UInt16
        getter whitespace : UInt16
        getter op : UInt16
        getter control : UInt16

        def initialize(@backslash : UInt16, @quote : UInt16, @whitespace : UInt16, @op : UInt16, @control : UInt16)
        end
      end

      struct Masks32
        getter backslash : UInt32
        getter quote : UInt32
        getter whitespace : UInt32
        getter op : UInt32
        getter control : UInt32

        def initialize(@backslash : UInt32, @quote : UInt32, @whitespace : UInt32, @op : UInt32, @control : UInt32)
        end
      end

      struct Masks64
        getter backslash : UInt64
        getter quote : UInt64
        getter whitespace : UInt64
        getter op : UInt64
        getter control : UInt64

        def initialize(@backslash : UInt64, @quote : UInt64, @whitespace : UInt64, @op : UInt64, @control : UInt64)
        end
      end

      def self.scan16(ptr : Pointer(UInt8)) : Masks16
        backslash = 0_u16
        quote = 0_u16
        whitespace = 0_u16
        op = 0_u16
        control = 0_u16
        16.times do |i|
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
        end
        Masks16.new(backslash, quote, whitespace, op, control)
      end

      def self.scan32(ptr : Pointer(UInt8)) : Masks32
        backslash = 0_u32
        quote = 0_u32
        whitespace = 0_u32
        op = 0_u32
        control = 0_u32
        32.times do |i|
          b = ptr[i]
          bit = 1_u32 << i
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
        end
        Masks32.new(backslash, quote, whitespace, op, control)
      end

      def self.scan32_combined(ptr : Pointer(UInt8)) : Masks32
        low = scan16(ptr)
        high = scan16(ptr + 16)
        backslash = low.backslash.to_u32 | (high.backslash.to_u32 << 16)
        quote = low.quote.to_u32 | (high.quote.to_u32 << 16)
        whitespace = low.whitespace.to_u32 | (high.whitespace.to_u32 << 16)
        op = low.op.to_u32 | (high.op.to_u32 << 16)
        control = low.control.to_u32 | (high.control.to_u32 << 16)
        Masks32.new(backslash, quote, whitespace, op, control)
      end

      def self.scan64(ptr : Pointer(UInt8)) : Masks64
        backslash = 0_u64
        quote = 0_u64
        whitespace = 0_u64
        op = 0_u64
        control = 0_u64
        64.times do |i|
          b = ptr[i]
          bit = 1_u64 << i
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
        end
        Masks64.new(backslash, quote, whitespace, op, control)
      end

      def self.all_digits16?(ptr : Pointer(UInt8)) : Bool
        16.times do |i|
          b = ptr[i]
          return false unless b >= '0'.ord && b <= '9'.ord
        end
        true
      end

      def self.newline_mask16(ptr : Pointer(UInt8)) : UInt16
        mask = 0_u16
        16.times do |i|
          b = ptr[i]
          mask |= (1_u16 << i) if b == 0x0a_u8 || b == 0x0d_u8
        end
        mask
      end
    end
  end
end
