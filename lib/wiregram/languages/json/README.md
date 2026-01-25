# JSON Language

The JSON Language module provides a complete pipeline for processing JSON (JavaScript Object Notation) data.

## Overview

This language implementation handles:
- JSON objects with key-value pairs
- JSON arrays
- Primitive data types (strings, numbers, booleans, null)
- Nested structures
- Unicode support
- JSON5 extensions (comments, trailing commas)

## Features

### Complete Processing Pipeline
```ruby
result = WireGram::Languages::Json.process('{"name": "test", "value": 42}')
# Returns hash with :tokens, :ast, :uom, :output, and :errors
```

### Individual Processing Steps
```ruby
# Tokenization
tokens = WireGram::Languages::Json.tokenize('{"key": "value"}')

# Parsing
ast = WireGram::Languages::Json.parse('{"key": "value"}')

# Transformation to UOM
uom = WireGram::Languages::Json.transform('{"key": "value"}')

# Serialization
output = WireGram::Languages::Json.serialize('{"key": "value"}')
```

### Pretty Printing
```ruby
# Pretty print with indentation
result = WireGram::Languages::Json.process_pretty('{"key":"value"}', 2)

# Simple serialization
result = WireGram::Languages::Json.process_simple('{"key":"value"}')
```

## Architecture

```
Input → Lexer → Tokens → Parser → AST → Transformer → UOM → Serializer → Output
```

### Components

1. **Lexer**: Tokenizes JSON input into meaningful units
2. **Parser**: Builds Abstract Syntax Tree (AST) from tokens
3. **Transformer**: Converts AST to Universal Object Model (UOM)
4. **Serializer**: Generates JSON output from UOM
5. **UOM**: Universal Object Model representation

## Usage Examples

### Simple JSON Object
```ruby
result = WireGram::Languages::Json.process('{"name": "John", "age": 30}')
# Output: '{"name": "John", "age": 30}'
```

### JSON Array
```ruby
result = WireGram::Languages::Json.process('[1, 2, 3, "test"]')
# Output: '[1, 2, 3, "test"]'
```

### Nested Structures
```ruby
result = WireGram::Languages::Json.process('{"user": {"name": "John", "age": 30}, "items": [1, 2, 3]}')
# Output preserves the original structure
```

### Pretty Printing
```ruby
result = WireGram::Languages::Json.process_pretty('{"key":"value"}', 2)
# Output:
# {
#   "key": "value"
# }
```

## Error Handling

The language implementation includes robust error handling:
- Syntax errors (missing commas, colons, brackets)
- Invalid JSON structures
- Unexpected tokens
- Incomplete objects/arrays
- Malformed input

## Testing

Tests are located in `spec/languages/json/` and include:
- Integration tests
- Snapshot tests
- Unit tests for each component
- Fixture-based testing with various JSON patterns

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
- `sort_keys: true/false` - Sort object keys alphabetically