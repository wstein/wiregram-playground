# UCL Language

The UCL (Universal Configuration Language) module provides a complete pipeline for processing UCL configuration files.

## Overview

This language implementation handles:
- UCL object syntax (`key = value`)
- Nested objects and arrays
- Variable interpolation
- Comments
- Include directives
- Advanced configuration features
- JSON compatibility mode

## Features

### Complete Processing Pipeline
```ruby
result = WireGram::Languages::Ucl.process('key = "value"; nested { subkey = 42; }')
# Returns hash with :tokens, :ast, :uom, :output, and :errors
```

### Individual Processing Steps
```ruby
# Tokenization
tokens = WireGram::Languages::Ucl.tokenize('key = "value"')

# Parsing
ast = WireGram::Languages::Ucl.parse('key = "value"')

# Transformation to UOM
uom = WireGram::Languages::Ucl.transform('key = "value"')

# Serialization
output = WireGram::Languages::Ucl.serialize('key = "value"')
```

### Pretty Printing
```ruby
# Pretty print with indentation
result = WireGram::Languages::Ucl.process_pretty('key = "value"', 2)

# Simple serialization
result = WireGram::Languages::Ucl.process_simple('key = "value"')
```

## Architecture

```
Input → Lexer → Tokens → Parser → AST → Transformer → UOM → Serializer → Output
```

### Components

1. **Lexer**: Tokenizes UCL input into meaningful units
2. **Parser**: Builds Abstract Syntax Tree (AST) from tokens
3. **Transformer**: Converts AST to Universal Object Model (UOM)
4. **Serializer**: Generates UCL/JSON output from UOM
5. **UOM**: Universal Object Model representation

## Usage Examples

### Simple UCL Configuration
```ruby
result = WireGram::Languages::Ucl.process('key = "value"')
# Output: 'key = "value"'
```

### Nested Objects
```ruby
result = WireGram::Languages::Ucl.process('nested { subkey = 42; }')
# Output: 'nested { subkey = 42; }'
```

### Arrays
```ruby
result = WireGram::Languages::Ucl.process('items = [1, 2, 3]')
# Output: 'items = [1, 2, 3]'
```

### Complex Configuration
```ruby
result = WireGram::Languages::Ucl.process('''
server {
  host = "localhost";
  port = 8080;
  features = ["ssl", "compression"];
}
''')
# Output preserves the original structure
```

### JSON Output
```ruby
result = WireGram::Languages::Ucl.process('key = "value"', output_format: :json)
# Output: '{"key": "value"}'
```

## Error Handling

The language implementation includes robust error handling:
- Syntax errors (missing semicolons, braces, brackets)
- Invalid UCL structures
- Unexpected tokens
- Incomplete objects/arrays
- Malformed input
- Circular references

## Testing

Tests are located in `spec/languages/ucl/` and include:
- Integration tests
- Snapshot tests
- Unit tests for each component
- Fixture-based testing with various UCL patterns
- JSON compatibility tests

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
- `output_format: :ucl/:json` - Output format (UCL or JSON)
- `sort_keys: true/false` - Sort object keys alphabetically
- `include_comments: true/false` - Include comments in output

## UCL vs JSON

UCL provides several advantages over JSON:
- More readable syntax for configuration
- Comments support
- Variable interpolation
- Include directives
- Automatic type conversion
- Better support for nested structures

## Conversion Between Formats

```ruby
# UCL to JSON
ucl_input = 'key = "value"; nested { subkey = 42; }'
json_output = WireGram::Languages::Ucl.serialize(ucl_input, output_format: :json)

# JSON to UCL
json_input = '{"key": "value", "nested": {"subkey": 42}}'
ucl_output = WireGram::Languages::Ucl.serialize(json_input, output_format: :ucl)
```

## Advanced Features

- **Variable Interpolation**: `${variable}` syntax
- **Include Directives**: `include "file.ucl"`
- **Merge Strategies**: Deep merge of configuration objects
- **Type Coercion**: Automatic conversion between types
- **Validation**: Schema validation support