# Newline Preservation Fix

## Issue

Transpiled code was being output without newlines in some cases, causing all output to appear as a single concatenated line.

## Root Cause Analysis

The issue manifested in two places:

1. **Crystal → Ruby transpilation (primary concern)**: The current implementation uses **text-based regex transforms**, not a CST-based rewrite. Newlines are preserved because we iterate with `each_line(chomp: false)` and avoid joining lines without delimiters, but the transformation itself is still string substitution.

2. **ports/ruby submodule files**: These auto-generated Ruby port files had pre-existing formatting issues where comments and code were concatenated without proper line breaks. This was a consequence of how the port generator originally created them.

## Solution Implemented

### 1. Verified Transpiler Correctness

- Confirmed the Ruby lexer creates `Newline` tokens correctly
- Verified CSTBuilder preserves bytes including newlines in `RawText` nodes
- Validated Serializer emits trivia from GreenNode.text without modification
- Confirmed Crystal serializer preserves MethodDef body text (which includes newlines)

### 2. Added Integration Tests

Added comprehensive test cases in `spec/integration/cli_spec.cr`:

```crystal
it "preserves newlines when transpiling Ruby to Crystal" do
  fixture_file = "spec/fixtures/cli/rb_simple.rb"
  cmd = ["crystal", "run", "bin/warp.cr", "--", "transpile", "crystal", "-s", fixture_file, "--stdout"].join(" ")
  
  out = %x(#{cmd})
  
  # Output should contain newlines, not all concatenated
  line_count = out.lines.size
  line_count.should be > 3
  
  # Should preserve structure
  out.includes?("def ").should eq(true)
  out.includes?("end").should eq(true)
end

it "preserves newlines when transpiling Crystal to Ruby" do
  fixture_file = "spec/fixtures/cli/cr_simple.cr"
  cmd = ["crystal", "run", "bin/warp.cr", "--", "transpile", "ruby", "-s", fixture_file, "--stdout"].join(" ")
  
  out = %x(#{cmd})
  
  # Output should contain newlines, not all concatenated
  line_count = out.lines.size
  line_count.should be > 2
  
  # Should preserve structure
  out.includes?("def ").should eq(true)
  out.includes?("end").should eq(true)
end

it "does not emit duplicate slashes in require_relative paths" do
  fixture_file = "spec/fixtures/cli/cr_simple.cr"
  cmd = ["crystal", "run", "bin/warp.cr", "--", "transpile", "ruby", "-s", fixture_file, "--stdout"].join(" ")

  out = %x(#{cmd})

  out.includes?("require_relative \".//").should eq(false)
  out.includes?("require_relative './/").should eq(false)
end
```

### 3. Fixed ports/ruby Files

Created `scripts/fix_ports_ruby_newlines.cr` to normalize the ports/ruby submodule files by:

- Adding newlines between comments and keywords
- Separating method/module definitions from preceding comments
- Ensuring proper formatting throughout the Ruby port files

Applied the fix to 81 files in the ports/ruby submodule.

## Architecture Notes

### Trivia Preservation Pipeline

The transpiler preserves newlines through this pipeline:

1. **Lexer** → Creates Newline tokens alongside other token types
2. **CST Parser** → Builds GreenNode tree with original source text
3. **RawText Nodes** → Store `String(bytes[start..end])` which includes all trivia
4. **Serializer** → Emits node.text directly without modification
5. **File Output** → Written as-is via File.write()

**Note:** Crystal → Ruby currently applies regex substitutions on the source text. It does not yet transform a CST and re-emit it. This is accurate but fragile compared to a CST-based transform.

### Key Data Structures

- **GreenNode.text : String?** - Stores original source bytes as string for RawText nodes
- **MethodDefPayload.body : String** - Stores method body with newlines preserved
- **RedNode** - Delegates to GreenNode for text access

## Test Results

```text
5 examples, 0 failures, 0 errors, 0 pending
```

All CLI integration tests pass, including:

- Crystal → Ruby transpilation with newline preservation
- Ruby → Crystal transpilation with newline preservation  
- Startup summary with CPU and worker info
- Per-run Summary with file counts

## Verification Commands

```bash
# Test newline preservation in Ruby -> Crystal
crystal run bin/warp.cr -- transpile crystal -s spec/fixtures/cli/rb_simple.rb --stdout

# Test newline preservation in Crystal -> Ruby
crystal run bin/warp.cr -- transpile ruby -s spec/fixtures/cli/cr_simple.cr --stdout

# Run integration tests
crystal spec spec/integration/cli_spec.cr
```

## Future Work

1. **Deterministic Port Generation**: Implement a dedicated port generator that produces Ruby files with proper formatting from Crystal sources
2. **Trivia Tracking**: Add explicit trivia tracking in CST to preserve comments and whitespace patterns
3. **Format Preservation**: Extend the serializer to support user-defined formatting preferences
4. **CI Validation**: Add CI checks to ensure transpiled code matches expected line counts and formatting
