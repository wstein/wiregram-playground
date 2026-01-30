module Warp
  module Backend
    abstract class Base
      abstract def build_masks(ptr : Pointer(UInt8), block_len : Int32) : Lexer::Masks
      abstract def all_digits16?(ptr : Pointer(UInt8)) : Bool
      abstract def name : String
    end
  end
end
