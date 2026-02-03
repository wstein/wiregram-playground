# Crystal parser partial implementation - 2026-02-03

## Summary

Implemented a minimal Crystal CST parser for Phase 1 to eliminate silent RawText-only outputs.

This first step recognizes and builds CST nodes for:

- top-level `require "..."` statements
- simple `ENV["NAME"] = "value"` assignments

## Why

The lexer was producing correct tokens but the CST contained only a `RawText` node because the parser didn't recognize common top-level constructs. This caused the pipeline to silently fail on parsing and hide issues.

## What changed

- Added `NodeKind::Require` and `NodeKind::Assignment` to `src/warp/lang/crystal/cst.cr`.
- Implemented `parse_require` and `parse_assignment` helpers which consume tokens and create CST nodes.
- The parser now respects strict mode and will return an error instead of silently converting to `RawText`.
- Added `spec/unit/crystal_cst_parser_spec.cr` to assert the new behavior.

## Next steps

- Expand the parser to handle additional top-level constructs: method/class/module definitions, constant assignments, and `require_relative` variations.
- Implement the Crystal Tape and SoA builders to enable downstream stages for Crystal.
- Add comprehensive integration tests covering more Crystal corpus samples.

## Notes

This change is intentionally small and conservative: it removes silent failures for common top-level patterns and gives us a safe base to extend the Crystal parser incrementally.
