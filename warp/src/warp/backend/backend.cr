module Warp
  module Backend
    abstract class Base
      abstract def build_masks(ptr : Pointer(UInt8), block_len : Int32) : Lexer::Masks
      abstract def name : String
    end
  end
end
