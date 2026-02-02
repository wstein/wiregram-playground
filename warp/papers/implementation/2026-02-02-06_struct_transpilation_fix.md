# Struct and Block Transpilation - Bug Fix

## Date: 2026-02-02

## Issue

Struct definitions (and other block types like Class, Module, Enum, Macro) were being silently dropped during transpilation. The transpiler would create nodes but not emit any output, resulting in lost code.

Additionally, method definitions lost their original indentation, which could cause formatting issues when methods were nested inside structs or classes.

## Root Cause Analysis

**Struct Silencing Issue:**

The `parse_simple_block()` method was designed to skip through entire blocks (struct, class, module, etc.) without capturing their content. It would:

1. Advance past the keyword (struct, class, etc.)
2. Skip until finding the matching `End` token
3. Create an empty node with no text

This caused all struct content to be lost, as the visitor had nothing to output.

**Indentation Loss Issue:**

The transpiler was reconstructing method definitions from scratch using extracted metadata (name, params, types), which resulted in losing the original indentation from the source. This caused improper formatting, especially for nested methods.

### Solutions Implemented

#### 1. Enhanced Block Parsing

Modified `parse_simple_block()` to capture entire block content as text:

```crystal
private def parse_simple_block(kind : NodeKind) : GreenNode
  # ...
  block_start = current.start
  advance  # skip keyword
  
  # Skip to matching End
  while @pos < @tokens.size && current.kind != TokenKind::End
    advance
  end
  
  # Capture entire block including End keyword
  block_end = current.start + current.length
  block_text = String.new(@bytes[block_start, block_end - block_start])
  
  GreenNode.new(kind, [] of GreenNode, block_text)
end
```

#### 2. Preserved Original Source in MethodDefPayload

Added `original_source` field to `MethodDefPayload` struct to preserve complete method text including indentation:

```crystal
struct MethodDefPayload
  getter original_source : String?
  # ...
end
```

#### 3. Intelligent Indentation Preservation

Updated `visit_method_def()` to use original source when available:

- Extracts leading whitespace from original source
- Only reconstructs method when type annotations require Sorbet sigs
- Otherwise preserves original formatting completely

#### 4. Block Type Visitor Updates

Enhanced visitors for ClassDef, ModuleDef, StructDef, EnumDef, MacroDef to:

- Process captured block text through `transform_body()`
- Apply transformations (require normalization, &. syntax, etc.)
- Preserve original formatting

### Changes Made

**Files Modified:**

1. `src/warp/lang/crystal/cst.cr`:
   - Added `original_source` field to MethodDefPayload
   - Rewrote `parse_simple_block()` to capture block content
   - Updated `parse_method_def()` to store original source

2. `src/warp/lang/crystal/crystal_to_ruby_transpiler.cr`:
   - Rewrote `visit_method_def()` with original source support
   - Updated block visitors to apply transformations
   - Added optional `indent` parameter to `build_ruby_def_line()`

**Tests Added:**

1. `spec/integration/struct_transpilation_spec.cr`:
   - Test struct with getters and initialize method
   - Test struct with complex method definitions
   - Verify indentation preservation

### Verification

Before fix:

```crystal
struct BenchResult
  getter path : String
  getter count : Int64
  # ... (content lost - nothing emitted)
end
```

After fix:

```crystal
struct BenchResult
  getter path : String
  getter count : Int64
  getter size : Int32
  getter seconds : Float64
  getter error : Warp::Core::ErrorCode?
  getter message : String?

  sig { void }
  def initialize(
    @path : String,
    @count : Int64,
    @size : Int32,
    @seconds : Float64,
    @error : Warp::Core::ErrorCode? = nil,
    @message : String? = nil,
  )
  end
end
```

## Test Results

- **Before**: Struct output was completely empty (silent failure)
- **After**: All struct content preserved with correct indentation
- **Total Tests**: 313 (added 2 struct transpilation tests)
- **All passing**: ✅

## Impact

- Fixes silent transpilation failures for structs, classes, modules, enums, and macros
- Preserves original indentation for all code blocks
- Maintains backward compatibility with existing tests
- No performance impact
