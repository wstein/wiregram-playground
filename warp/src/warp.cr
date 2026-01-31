# Warp: a high-performance language pipeline with JSON, Ruby, and Crystal support.
#
# This module provides a staged language parser that:
# 1. Lexes input into tokens (language-specific)
# 2. Builds a Green/Red CST for lossless source preservation
# 3. Generates a compact Tape IR for high-throughput formatting
# 4. Optionally builds a semantic AST for linting/transpilation
#
# Currently supported languages:
# - JSON (fully implemented)
# - Ruby (prototype/WIP - see papers/ruby-crystal-language-pipeline.adoc)
# - Crystal (planned)
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

require "./warp/ast/types"
require "./warp/backend/avx_backend"
require "./warp/backend/avx2_backend"
require "./warp/backend/avx512_backend"
require "./warp/backend/backend"
require "./warp/backend/neon_backend"
require "./warp/backend/neon_masks"
require "./warp/backend/scalar_backend"
require "./warp/backend/selector"
require "./warp/backend/sse2_backend"
require "./warp/backend/x86_masks_scalar"
require "./warp/core/types"
require "./warp/cst/parser"
require "./warp/cst/types"
require "./warp/dom/builder"
require "./warp/dom/value"
require "./warp/format/formatter"
require "./warp/input/padded_buffer"
require "./warp/ir/soa_view"
require "./warp/ir/tape_builder"
require "./warp/lexer/structural_scan"
require "./warp/lexer/token_assembler"
require "./warp/lexer/token_scanner"
require "./warp/parser"

# Language support modules (for future extensibility)
require "./warp/lang/json/types"
require "./warp/lang/ruby/types"
require "./warp/lang/ruby/lexer"
require "./warp/lang/ruby/ast"
require "./warp/lang/ruby/parser"
require "./warp/lang/ruby/ir"
require "./warp/lang/ruby/transpile_context"
require "./warp/lang/ruby/semantic_analyzer"
require "./warp/lang/ruby/tape_prototype"
require "./warp/lang/ruby/cst"
require "./warp/lang/ruby/rewriter"
require "./warp/lang/ruby/sorbet_parser"
require "./warp/lang/ruby/sorbet_construct_parser"
require "./warp/lang/ruby/annotations/annotation_store"
require "./warp/lang/ruby/annotations/rbs_file_parser"
require "./warp/lang/ruby/annotations/rbi_file_parser"
require "./warp/lang/ruby/annotations/inline_rbs_parser"
require "./warp/lang/ruby/transpiler_config"
require "./warp/lang/ruby/analyzer"
require "./warp/lang/crystal/types"
require "./warp/lang/crystal/lexer"
require "./warp/lang/crystal/type_mapping"
require "./warp/lang/crystal/cst"
require "./warp/lang/crystal/cst_builder"
require "./warp/lang/crystal/serializer"
require "./warp/lang/crystal/semantic_analyzer"
require "./warp/lang/crystal/crystal_to_ruby_transpiler"
require "./warp/lang/ruby/cst_to_cst_transpiler"
require "./warp/lang/ruby/annotations/annotation_extractor"
require "./warp/lang/ruby/annotations/sorbet_rbs_parser"
require "./warp/lang/ruby/annotations/rbs_generator"
require "./warp/lang/ruby/annotations/sorbet_rbi_generator"
require "./warp/lang/ruby/annotations/inline_rbs_injector"
require "./warp/lang/ruby/annotations/crystal_sig_builder"
require "./warp/testing/bidirectional_validator"
