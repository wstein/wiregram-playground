# Simdjson: a small, high-performance JSON parser exposed as a Crystal module.
#
# This module provides a staged JSON parser that first locates structural
# characters (stage1) and then builds a compact "tape" representation
# (stage2). The API is intentionally low-level and focuses on zero-copy
# slicing of the input `Bytes` together with fast validation options.
#
# Usage notes:
# - Use `Simdjson::Parser` to iterate tokens (`each_token`) or parse a
#   complete document (`parse_document`).
# - Error handling is via `Simdjson::ErrorCode` values.
#
module Simdjson
end

require "./simdjson/types"
require "./simdjson/neon"
require "./simdjson/stage1"
require "./simdjson/stage2"
require "./simdjson/parser"
