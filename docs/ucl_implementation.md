# UCL (Universal Configuration Language) Implementation

## Overview

This is a comprehensive implementation of UCL parsing, normalization, and serialization for the WireGram universal code analysis framework.

### What is UCL?

UCL (Universal Configuration Language) is a configuration format designed to be more user-friendly than JSON while being suitable for nested data structures and various value types. It's commonly used in FreeBSD and other projects.

### Key Features Supported

- **Objects**: `{ key = value; }`
- **Arrays**: `[value1, value2, value3]`
- **Strings**: Both quoted and unquoted values
- **Numbers**: Integers, floats, hex numbers, scientific notation
- **Booleans**: `true`, `false`, `yes`, `no`, `on`, `off`
- **Null Values**: `null` or `nil`
- **Comments**: Line comments (`#`) and nested block comments (`/* */`)
- **Operators**: Both `=` and `:` as separators (normalized to `=`)
- **Normalization**: Converts various formats to canonical forms

## Pipeline

The UCL implementation follows a standard text processing pipeline:

```
Input (*.in) 
  ↓
LEXER (Tokenization)
  ↓ Tokens (stored in JSON for debugging)
PARSER (AST Building)
  ↓ AST (stored in JSON for debugging)
SERIALIZER (Normalization)
  ↓
Output (*.res)
```

## File Structure

```
lib/wiregram/languages/ucl/
├── lexer.rb          # Tokenizer - converts source text to tokens
├── parser.rb         # Parser - builds Abstract Syntax Tree from tokens
└── serializer.rb     # Serializer - converts AST to normalized UCL format

lib/wiregram/languages/ucl.rb  # Module with unified .process() method

spec/ucl_spec.rb      # Comprehensive unit tests (43 tests)

scripts/test_ucl_integration.rb # Integration tests with libucl test files

tmp/debug/            # Debug output directory for intermediate results
```

## Usage

### Basic Usage

```ruby
require 'wiregram'

input = 'key = value;'
result = WireGram::Languages::Ucl.process(input)

puts result[:output]  # Normalized output
puts result[:tokens]  # Token stream (for debugging)
puts result[:ast]     # Abstract Syntax Tree (for debugging)
puts result[:errors]  # Any parser errors
```

### Using the Weave API

```ruby
fabric = WireGram.weave(source, language: :ucl)
puts fabric.source        # Original source
puts fabric.ast           # Parsed AST
puts fabric.tokens        # Tokens
```

## Normalization Rules

The UCL normalizer applies the following transformations:

### Boolean Values
- `true` → `true`
- `false` → `false`
- `yes` → `true`
- `no` → `false`
- `on` → `true`
- `off` → `false`

### Numeric Values
- Integers: preserved as-is (e.g., `123` → `123`)
- Floats: preserved as-is (e.g., `1.0` → `1.0`)
- Scientific notation: preserved as-is (e.g., `-1e-10` → `-1e-10`)
- Hex numbers: converted to decimal (e.g., `0xdeadbeef` → `3735928559`)
- Negative hex: handled correctly (e.g., `-0xdeadbeef` → `-3735928559`)
- Invalid hex (with decimal point): treated as strings (e.g., `0xdeadbeef.1` → `"0xdeadbeef.1"`)
- Invalid hex (invalid characters): treated as strings (e.g., `0xreadbeef` → `"0xreadbeef"`)

### String Values
- Quoted strings: preserved but always re-quoted in output
- Unquoted identifiers: converted to quoted strings
- Escape sequences: properly handled and re-escaped in output

### Key Names
- Quoted and unquoted keys are normalized to unquoted in output
- Keys can use identifiers, dots, and hyphens

### Separators
- Both `=` and `:` are accepted as assignment separators
- Normalized to `=` in output

## Examples

### Simple Assignment
```ucl
# Input
key = value

# Output
key = "value";
```

### Objects
```ucl
# Input
{
  section {
    param = value
  }
}

# Output
section {
    param = "value";
}
```

### Arrays
```ucl
# Input
values = [1, 2, 3]

# Output
values = [1, 2, 3];
```

### Mixed Types
```ucl
# Input
config {
  debug = yes
  port = 8080
  server = 0xdeadbeef
  urls = [
    "https://example.com"
    "https://test.com"
  ]
}

# Output
config {
    debug = true;
    port = 8080;
    server = 3735928559;
    urls = ["https://example.com", "https://test.com"];
}
```

## Lexer Details

The lexer (`lexer.rb`) tokenizes UCL source code into:

### Token Types
- `:identifier` - Variable names and unquoted identifiers
- `:string` - Quoted strings (double or single quotes)
- `:number` - Integer and float literals
- `:hex_number` - Hexadecimal number literals
- `:invalid_hex` - Malformed hex numbers (treated as strings)
- `:boolean` - Boolean keywords (`true`, `false`, `yes`, `no`, `on`, `off`)
- `:null` - Null values (`null`, `nil`)
- `:lbrace` / `:rbrace` - `{` and `}`
- `:lbracket` / `:rbracket` - `[` and `]`
- `:colon` / `:equals` - `:` and `=` separators
- `:comma` / `:semicolon` - `,` and `;`
- `:eof` - End of input

### Comment Handling
- Line comments: `# comment` (skipped)
- Block comments: `/* comment */` with full nesting support
  - Nested blocks are properly tracked: `/* /* /* */ */ */`

## Parser Details

The parser (`parser.rb`) builds an Abstract Syntax Tree (AST) from tokens:

### AST Node Types
- `:program` - Root node containing all top-level elements
- `:object` - Object literal `{ ... }`
- `:assignment` - Key-value assignment
- `:array` - Array literal `[ ... ]`
- `:identifier` - Identifier or variable name
- `:string` - String literal
- `:number` - Numeric literal
- `:hex_number` - Hex number literal
- `:boolean` - Boolean value
- `:null` - Null value

### Grammar
```
program         → object_content*
object_content  → (assignment | object)*
assignment      → key (= | :) value (;|,)?
key             → identifier | string
value           → object | array | string | number | boolean | null | identifier
array           → '[' (value (',' value)*)? ']'
```

## Serializer Details

The serializer (`serializer.rb`) converts the AST back to normalized UCL format:

1. **Program unwrapping**: If the program contains a single non-empty object at the top level, it's unwrapped (no outer braces)
2. **String quoting**: All string values are always quoted in output
3. **Number conversion**: Hex numbers are converted to decimal
4. **Boolean normalization**: All booleans are output as `true` or `false`
5. **Formatting**: Consistent indentation and spacing

## Testing

### Unit Tests

Run the comprehensive unit test suite:

```bash
rspec spec/ucl_spec.rb
```

This includes 43 tests covering:
- Basic UCL parsing and normalization
- Number handling (integers, floats, hex, scientific)
- Boolean normalization
- Comments (line and block with nesting)
- Objects and nested structures
- Arrays
- String escapes
- Token generation
- AST structure

### Integration Tests

Test against libucl test files:

```bash
ruby scripts/test_ucl_integration.rb
```

This script:
- Reads all `*.in` files from `vendor/libucl/tests/basic/`
- Compares output with expected `*.res` files
- Stores debug information for failed tests in `tmp/debug/`
- Reports pass/fail statistics

Debug output includes:
- `.tokens.json` - Token stream for the test
- `.ast.json` - Abstract Syntax Tree
- `.output.txt` - Actual output
- `.expected.txt` - Expected output (for failed tests)

## Known Limitations

The current implementation focuses on core UCL features. The following advanced features are **not yet implemented**:

1. **Macros and Directives**: `.include()`, `.priority()`, `.substitute()`, etc.
2. **Variable Expansion**: `${variable}` syntax
3. **Multiline Strings**: Heredoc syntax (`<<EOF ... EOF`)
4. **Variable References**: References to previously defined variables
5. **Special Directives**: `.inherit()`, `.assign()`, etc.
6. **UCL-specific Operators**: Merge operators (`+=`), etc.

These features would require:
- Preprocessing pass for includes and macro expansion
- Symbol table for variable tracking
- Heredoc string parsing in the lexer
- Additional semantic analysis in the transformer

## Architecture

### Design Principles

1. **Separation of Concerns**: Lexer, Parser, and Serializer are independent modules
2. **AST-based**: Uses an intermediate Abstract Syntax Tree for flexibility
3. **Error Recovery**: Parser continues on errors instead of failing completely
4. **Normalization**: Output is always in a canonical, consistent format
5. **Debugging**: Intermediate representations can be saved to disk for analysis

### Data Flow

```
Source Text
    ↓
[Lexer]  → Tokenize → Stream of Tokens
    ↓
[Parser] → Build AST → Abstract Syntax Tree
    ↓
[Serializer] → Normalize → Canonical UCL Output
```

Each stage can be examined independently for debugging:
- Lexer output: `result[:tokens]`
- Parser output: `result[:ast]`
- Serializer output: `result[:output]`

## Future Enhancements

To improve test coverage and support more UCL features:

1. **Macro Support**: Implement UCL directives and macro expansion
2. **Include Processing**: Handle `.include()` directives
3. **Variable Expansion**: Support `${variable}` syntax
4. **Multiline Strings**: Add heredoc and literal string support
5. **Better Error Messages**: More informative parser error messages with position information
6. **Symbol Resolution**: Track and validate variable references
7. **Type System**: Optional type checking for configuration values

## References

- [UCL Format Specification](https://github.com/vstakhov/libucl)
- [libucl Test Suite](https://github.com/vstakhov/libucl/tree/master/tests)
- [FreeBSD UCL Documentation](https://www.freebsd.org/releases/11.0R/release-notes.html#features-installertools-pkg)

## License

Part of the WireGram framework. See main LICENSE file for details.
