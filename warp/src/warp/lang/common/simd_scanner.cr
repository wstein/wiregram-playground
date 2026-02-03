# Common SIMD Scanner Interface
#
# Provides a unified interface for structural scanning across languages.
# Each language implements its own character detection logic while leveraging
# the common backend infrastructure for SIMD operations.

module Warp
  module Lang
    module Common
      # Base interface for language-specific structural character scanning
      abstract class StructuralScanner
        # Scan bytes and return structural character indices
        # Must be implemented by language-specific scanners
        abstract def scan : Array(UInt32)

        # Error code from the scan operation
        abstract def error : Warp::Core::ErrorCode

        # Get the name of the language being scanned
        abstract def language_name : String

        protected def backend
          Warp::Backend.current
        end

        # Optional reset hook for reusing scanner instances.
        def reset
        end

        protected def compute_common_structural(
          masks : Warp::Lexer::Masks,
          block_len : Int32,
          ptr : Pointer(UInt8),
        ) : UInt64
          structural = masks.quote | masks.control | masks.op
          if block_len < 64
            structural &= (1_u64 << block_len) - 1_u64
          end
          structural
        end
      end

      # Result of a structural scan operation
      struct ScanResult
        getter indices : Array(UInt32)
        getter error : Warp::Core::ErrorCode
        getter language : String

        def initialize(@indices : Array(UInt32), @error : Warp::Core::ErrorCode, @language : String)
        end
      end
    end
  end
end
