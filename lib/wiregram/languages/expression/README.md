# Expression Language

The Expression Language module provides a complete pipeline for processing mathematical and programming expressions.

## Overview

This language implementation handles:
- Basic arithmetic operations (`+`, `-`, `*`, `/`)
- Variable assignments (`let x = 42`)
- Parentheses for grouping expressions
- String literals
- Identifier references

## Features

### Complete Processing Pipeline
```ruby
result = WireGram::Languages::Expression.process("let x = 42 + 10")
# Returns hash with :tokens, :ast, :uom, :output, and :errors
```

### Individual Processing Steps
```ruby
# Tokenization
tokens = WireGram::Languages::Expression.tokenize("1 + 2")

# Parsing
ast = WireGram::Languages::Expression.parse("1 + 2")

# Transformation to UOM
uom = WireGram::Languages::Expression.transform("1 + 2")

# Serialization
output = WireGram::Languages::Expression.serialize("1 + 2")
```

### Pretty Printing
```ruby
# Pretty print with indentation
result = WireGram::Languages::Expression.process_pretty("let x = 42", 2)

# Simple serialization
result = WireGram::Languages::Expression.process_simple("let x = 42")
```

## Architecture

```
Input → Lexer → Tokens → Parser → AST → Transformer → UOM → Serializer → Output
```

### Components

1. **Lexer**: Tokenizes input into meaningful units
2. **Parser**: Builds Abstract Syntax Tree (AST) from tokens
3. **Transformer**: Converts AST to Universal Object Model (UOM)
4. **Serializer**: Generates output from UOM
5. **UOM**: Universal Object Model representation

## Usage Examples

### Basic Arithmetic
```ruby
result = WireGram::Languages::Expression.process("1 + 2 * 3")
# Output: "1 + 2 * 3" (respects operator precedence)
```

### Variable Assignments
```ruby
result = WireGram::Languages::Expression.process("let x = 42")
# Output: "let x = 42"
```

### Complex Expressions
```ruby
result = WireGram::Languages::Expression.process("""
let x = 42
let y = x + 1
x * y
""")
# Output preserves the original structure
```

## Error Handling

The language implementation includes robust error handling:
- Syntax errors
- Unexpected tokens
- Incomplete expressions
- Malformed input

## Testing

Tests are located in `spec/languages/expression/` and include:
- Integration tests
- Snapshot tests
- Unit tests for each component
- Fixture-based testing

## API Reference

### Main Methods
- `process(input, options = {})` - Complete pipeline processing
- `process_pretty(input, indent_size = 2)` - Pretty printing
- `process_simple(input)` - Simple serialization
- `tokenize(input)` - Tokenization only
- `parse(input)` - Parsing only
- `transform(input)` - Transformation only
- `serialize(input)` - Serialization only
- `serialize_pretty(input, indent_size = 2)` - Pretty serialization
- `serialize_simple(input)` - Simple serialization

### Options
- `pretty: true/false` - Enable/disable pretty printing
- `indent_size: Integer` - Indentation size for pretty printing