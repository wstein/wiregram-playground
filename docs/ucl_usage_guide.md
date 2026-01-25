# UCL Usage Guide - Step by Step

## Quick Start

### 1. Processing a Simple Configuration

```ruby
require 'wiregram'

# Process a simple UCL configuration
config_text = <<~UCL
  server {
    host = "localhost"
    port = 8080
    debug = yes
  }
UCL

result = WireGram::Languages::Ucl.process(config_text)

# Get the normalized output
puts result[:output]
# Output:
# server {
#     host = "localhost";
#     port = 8080;
#     debug = true;
# }
```

### 2. Understanding the Pipeline

Every time you call `WireGram::Languages::Ucl.process()`, three things happen:

```ruby
result = WireGram::Languages::Ucl.process(input)

# 1. Lexer - Breaks the text into tokens
result[:tokens]   # Array of token objects

# 2. Parser - Builds an Abstract Syntax Tree (AST)
result[:ast]      # Tree structure of the parsed input

# 3. Serializer - Converts AST to normalized UCL
result[:output]   # String with normalized output

# Any parsing errors
result[:errors]   # Array of error objects
```

## Working with Tokens

Tokens are the first step in processing. Each token has a type and value:

```ruby
input = 'key = "value";'
result = WireGram::Languages::Ucl.process(input)

result[:tokens].each do |token|
  puts "#{token[:type]}: #{token[:value].inspect}"
end

# Output:
# identifier: "key"
# equals: "="
# string: "value"
# semicolon: ";"
# eof: nil
```

### Common Token Types

| Type | Example | Used For |
|------|---------|----------|
| `:identifier` | `mykey`, `server` | Unquoted variable names |
| `:string` | `"value"` | Quoted string literals |
| `:number` | `123` | Integer literals |
| `:hex_number` | `0xDEAD` | Hexadecimal numbers |
| `:boolean` | `true`, `yes`, `no` | Boolean values |
| `:null` | `null` | Null values |
| `:lbrace` / `:rbrace` | `{` / `}` | Object delimiters |
| `:lbracket` / `:rbracket` | `[` / `]` | Array delimiters |
| `:equals` / `:colon` | `=` / `:` | Assignment operators |

## Working with the AST (Abstract Syntax Tree)

The AST is a hierarchical representation of your configuration:

```ruby
input = <<~UCL
  {
    server = {
      port = 8080
    }
  }
UCL

result = WireGram::Languages::Ucl.process(input)
ast = result[:ast]

def print_ast(node, depth = 0)
  indent = "  " * depth
  puts "#{indent}#{node.type}"
  node.children&.each { |child| print_ast(child, depth + 1) }
end

print_ast(ast)

# Output:
# program
#   assignment
#     identifier
#     object
#       assignment
#         identifier
#         number
```

### AST Node Structure

Each node is a `WireGram::Core::Node` object with:

```ruby
node.type        # Symbol: :program, :object, :assignment, etc.
node.value       # Value of the node (nil for containers)
node.children    # Array of child nodes
```

## Normalization Examples

### Numbers

```ruby
# Hex numbers are converted to decimal
input = 'num = 0xFF'
result = WireGram::Languages::Ucl.process(input)
puts result[:output]  # num = 255;

# Scientific notation is preserved
input = 'val = -1e-10'
result = WireGram::Languages::Ucl.process(input)
puts result[:output]  # val = -1e-10;

# Invalid hex is treated as string
input = 'num = 0xZZZZ'
result = WireGram::Languages::Ucl.process(input)
puts result[:output]  # num = "0xZZZZ";
```

### Booleans

```ruby
# Various formats normalize to true/false
examples = [
  'flag = true',
  'flag = yes',
  'flag = on',
  'flag = false',
  'flag = no',
  'flag = off'
]

examples.each do |input|
  result = WireGram::Languages::Ucl.process(input)
  puts result[:output]
end

# Output:
# flag = true;
# flag = true;
# flag = true;
# flag = false;
# flag = false;
# flag = false;
```

### Strings

```ruby
# Both quoted and unquoted identifiers become quoted strings
inputs = [
  'key = value',           # Unquoted identifier
  'key = "value"',         # Quoted string
  "key = 'value'",         # Single quoted
]

inputs.each do |input|
  result = WireGram::Languages::Ucl.process(input)
  puts result[:output]
end

# Output (all the same):
# key = "value";
# key = "value";
# key = "value";
```

## Debugging

### Saving Intermediate Results

Use the integration test script to process files and save debug information:

```bash
# Process all libucl test files and save debug output
ruby scripts/test_ucl_integration.rb

# Debug files are saved in tmp/debug/:
# - test_name.tokens.json   → Token stream
# - test_name.ast.json      → Abstract Syntax Tree
# - test_name.output.txt    → Actual output
# - test_name.expected.txt  → Expected output (if different)
```

### Manual Debugging

```ruby
require 'json'
require 'wiregram/languages/ucl'

input = 'key = value;'
result = WireGram::Languages::Ucl.process(input)

# Print tokens
puts "Tokens:"
puts JSON.pretty_generate(result[:tokens])

# Print AST
def ast_to_hash(node)
  {
    type: node.type,
    value: node.value,
    children: node.children&.map { |child| ast_to_hash(child) } || []
  }
end

puts "\nAST:"
puts JSON.pretty_generate(ast_to_hash(result[:ast]))

# Print output
puts "\nOutput:"
puts result[:output]

# Check for errors
puts "\nErrors:"
puts result[:errors]
```

## Common Patterns

### Processing a Configuration File

```ruby
require 'wiregram/languages/ucl'

# Read UCL file
config_text = File.read('config.ucl')

# Process
result = WireGram::Languages::Ucl.process(config_text)

if result[:errors].any?
  puts "Parsing errors:"
  result[:errors].each { |err| puts "  - #{err}" }
else
  # Write normalized output
  File.write('config.normalized.ucl', result[:output])
  puts "Normalized config saved to config.normalized.ucl"
end
```

### Analyzing Configuration Structure

```ruby
require 'wiregram/languages/ucl'

config = <<~UCL
  database {
    host = "localhost"
    port = 5432
  }
  cache = true
UCL

result = WireGram::Languages::Ucl.process(config)

def find_assignments(node, path = [])
  assignments = []
  
  if node.type == :assignment
    key = node.children[0].value
    value = node.children[1]
    assignments << { path: path + [key], value_type: value.type }
  end
  
  node.children&.each do |child|
    next_path = (node.type == :assignment) ? path : path
    assignments.concat(find_assignments(child, next_path))
  end
  
  assignments
end

puts "Configuration structure:"
find_assignments(result[:ast]).each do |assign|
  puts "  #{assign[:path].join('.')} (#{assign[:value_type]})"
end

# Output:
#   [:database] (object)
#   [:database, :host] (string)
#   [:database, :port] (number)
#   [:cache] (boolean)
```

### Converting UCL to JSON

```ruby
require 'json'
require 'wiregram/languages/ucl'

def ucl_to_hash(node)
  case node.type
  when :program
    ucl_to_hash(node.children[0]) if node.children.any?
  when :object
    node.children.each_with_object({}) do |child, hash|
      if child.type == :assignment
        key = child.children[0].value
        value = ucl_to_hash(child.children[1])
        hash[key] = value
      end
      hash
    end
  when :array
    node.children.map { |child| ucl_to_hash(child) }
  when :string, :identifier
    node.value
  when :number, :hex_number
    node.value.to_i rescue node.value.to_f rescue node.value
  when :boolean
    node.value
  when :null
    nil
  else
    node.value
  end
end

config_text = <<~UCL
  {
    database {
      host = "localhost"
      ports = [5432, 5433]
    }
  }
UCL

result = WireGram::Languages::Ucl.process(config_text)
json_data = ucl_to_hash(result[:ast])

puts JSON.pretty_generate(json_data)

# Output:
# {
#   "database": {
#     "host": "localhost",
#     "ports": [5432, 5433]
#   }
# }
```

## Error Handling

### Parser Errors

The parser is designed to be resilient and continue even when it encounters errors:

```ruby
require 'wiregram/languages/ucl'

# Input with missing assignment operator
input = 'key value;'

result = WireGram::Languages::Ucl.process(input)

if result[:errors].any?
  puts "Found #{result[:errors].length} errors:"
  result[:errors].each do |error|
    puts "  Type: #{error[:type]}"
    puts "  Got: #{error[:got]}"
    puts "  Position: #{error[:position]}"
  end
else
  puts "Parsing successful!"
end
```

### Validation

```ruby
def validate_config(config_text)
  result = WireGram::Languages::Ucl.process(config_text)
  
  if result[:errors].any?
    return { valid: false, errors: result[:errors] }
  end
  
  # Additional validation logic here
  { valid: true, output: result[:output] }
end

config = 'key = value;'
validation = validate_config(config)

if validation[:valid]
  puts "Config is valid!"
else
  puts "Config has errors: #{validation[:errors]}"
end
```

## Performance Tips

1. **Process once, use many times**: Store the result and reuse it
2. **Check errors early**: Validate input before doing complex processing
3. **Use tokens for simple analysis**: If you just need to list keys, process tokens instead of building full AST
4. **Cache debug output**: Save intermediate results to disk when processing large files

## Testing Your Configuration

```ruby
require 'wiregram/languages/ucl'

def test_normalization(input, expected_output)
  result = WireGram::Languages::Ucl.process(input)
  
  if result[:output].strip == expected_output.strip
    puts "✓ Test passed"
    true
  else
    puts "✗ Test failed"
    puts "  Expected: #{expected_output.inspect}"
    puts "  Got:      #{result[:output].inspect}"
    false
  end
end

# Test cases
test_normalization(
  'key = value',
  'key = "value";'
)

test_normalization(
  'flag = yes',
  'flag = true;'
)

test_normalization(
  'num = 0xFF',
  'num = 255;'
)
```

## Next Steps

- Check out `spec/ucl_spec.rb` for more examples of various UCL features
- Run `ruby scripts/test_ucl_integration.rb` to see how the implementation handles real-world test files
- Explore `lib/wiregram/languages/ucl/` to understand the lexer, parser, and serializer implementations
- Read the full [UCL Implementation Documentation](./ucl_implementation.md) for technical details
