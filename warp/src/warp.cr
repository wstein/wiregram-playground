# Warp: a small, high-performance JSON parser exposed as a Crystal module.
#
# This module provides a staged JSON parser that first locates structural
# characters (stage1) and then builds a compact "tape" representation
# (stage2). The API is intentionally low-level and focuses on zero-copy
# slicing of the input `Bytes` together with fast validation options.
#
# Usage notes:
# - Use `Warp::Parser` to iterate tokens (`each_token`) or parse a
#   complete document (`parse_document`).
# - Error handling is via `Warp::Core::ErrorCode` values.
#
module Warp
  alias ErrorCode = Core::ErrorCode
  alias TokenType = Core::TokenType
  alias Token = Core::Token
end

require "./warp/core/types"
require "./warp/backend/backend"
require "./warp/backend/x86_masks"
require "./warp/backend/neon_masks"
require "./warp/backend/sse2_backend"
require "./warp/backend/avx_backend"
require "./warp/backend/avx2_backend"
require "./warp/backend/avx512_backend"
require "./warp/backend/neon_backend"
require "./warp/backend/scalar_backend"
require "./warp/backend/selector"
require "./warp/input/padded_buffer"
require "./warp/lexer/structural_scan"
require "./warp/ir/tape_builder"
require "./warp/parser"
