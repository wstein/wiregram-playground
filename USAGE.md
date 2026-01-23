# WireGram Usage Guide

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/wstein/wiregram-playground.git
cd wiregram-playground

# Install dependencies
bundle install
```

### Running the Demo

```bash
ruby demo.rb
```

This will showcase all major features of the WireGram framework.

## Core Concepts

### 1. Weaving Source Code into Fabric

The fundamental operation in WireGram is "weaving" source code into a digital fabric:

```ruby
require 'wiregram'

# Weave source code into a digital fabric
fabric = WireGram.weave("let x = 42 + 10")

# The fabric contains:
# - Original source code
# - Abstract Syntax Tree (AST)
# - Token stream
```

### 2. Reversibility - Unweaving Back to Source

One of WireGram's key features is perfect reversibility:

```ruby
fabric = WireGram.weave("let x = 42 + 10")
source = fabric.to_source  # => "let x = 42 + 10"
```

### 3. Pattern Detection

Find patterns in your code:

```ruby
fabric = WireGram.weave("let x = 10 + 5 * 2")

# Find arithmetic operations
operations = fabric.find_patterns(:arithmetic_operations)

# Find literals
literals = fabric.find_patterns(:literals)

# Find identifiers
identifiers = fabric.find_patterns(:identifiers)
```

### 4. Code Analysis

Analyze code complexity and quality:

```ruby
fabric = WireGram.weave("let x = 100 / 5 + 3 * 2")
analyzer = fabric.analyze

# Get complexity metrics
complexity = analyzer.complexity
puts complexity[:operations_count]
puts complexity[:tree_depth]

# Get diagnostics
diagnostics = analyzer.diagnostics
```

### 5. Code Transformation

Transform code automatically:

```ruby
fabric = WireGram.weave("let x = 10 + 20")

# Built-in transformation: constant folding
optimized = fabric.transform(:constant_folding)
puts optimized.to_source  # => "let x = 30"

# Custom transformation
transformed = fabric.transform do |node|
  if node.type == :add
    node.with(type: :multiply)  # Change + to *
  else
    node
  end
end
```

### 6. Building a Linter

Create custom linting rules:

```ruby
require 'wiregram/tools/linter'

linter = WireGram::Tools::Linter.new do
  rule "no-constant-expressions", severity: :warning do |fabric|
    analyzer = fabric.analyze
    analyzer.diagnostics.select { |d| d[:type] == :optimization }
  end
end

fabric = WireGram.weave("let x = 100 + 200")
issues = linter.lint(fabric)
puts linter.format_results
```

### 7. Building an Auto-Fixer

Automatically fix code issues:

```ruby
require 'wiregram/tools/fixer'

fixer = WireGram::Tools::AutoFixer.new do
  fix "optimize-constants" do |fabric|
    fabric.transform(:constant_folding)
  end
end

fabric = WireGram.weave("let x = 10 + 20")
fixed = fixer.apply_fixes(fabric)
puts fixed.to_source  # => "let x = 30"
```

### 8. Building a Language Server

Foundation for language server protocol:

```ruby
require 'wiregram/tools/server'

server = WireGram::Tools::LanguageServer.new

server.on_change do |document|
  fabric = document.fabric
  analyzer = fabric.analyze
  
  # Return diagnostics
  analyzer.diagnostics
end

server.on_completion do |document, position|
  # Return completions
  ["identifier", "keyword"]
end

# Process a document change
server.process_change("file:///example.wg", "let x = 42")
```

## Advanced Usage

### Custom AST Traversal

```ruby
fabric = WireGram.weave("let x = 42 + 10")

# Traverse all nodes
fabric.ast.traverse do |node|
  puts "Node: #{node.type}, Value: #{node.value}"
end

# Find specific nodes
numbers = fabric.ast.find_all { |node| node.type == :number }
```

### Error Recovery

WireGram gracefully handles malformed input:

```ruby
lexer = WireGram::Languages::Expression::Lexer.new("let x = 42 + @invalid")
tokens = lexer.tokenize

# Check for errors
if lexer.errors.any?
  lexer.errors.each do |error|
    puts "Error: #{error[:type]} at position #{error[:position]}"
  end
end
```

### Immutable Transformations

All nodes are immutable. Use `with` to create modified copies:

```ruby
node = WireGram::Core::Node.new(:number, value: 42)
new_node = node.with(value: 100)

# Original node is unchanged
puts node.value      # => 42
puts new_node.value  # => 100
```

## Examples

The `examples/` directory contains working demonstrations:

- `simple_lexer.rb` - Tokenization examples
- `expression_parser.rb` - Parsing and AST visualization
- `code_analyzer.rb` - Pattern detection and analysis
- `auto_fixer.rb` - Automatic code optimization

Run any example:

```bash
ruby examples/simple_lexer.rb
ruby examples/expression_parser.rb
ruby examples/code_analyzer.rb
ruby examples/auto_fixer.rb
```

## Testing

Run the test suite:

```bash
ruby test/test_wiregram.rb
```

## Extending WireGram

### Adding a New Language

To add support for a new language:

1. Create a lexer inheriting from `WireGram::Core::BaseLexer`
2. Create a parser inheriting from `WireGram::Core::BaseParser`
3. Implement the required methods
4. Register the language in `WireGram.weave`

Example:

```ruby
class MyLexer < WireGram::Core::BaseLexer
  protected
  def try_tokenize_next
    # Your tokenization logic
  end
end

class MyParser < WireGram::Core::BaseParser
  def parse
    # Your parsing logic
  end
end
```

### Creating Custom Transformations

Define reusable transformations:

```ruby
module MyTransformations
  def self.inline_variables(fabric)
    fabric.transform do |node|
      # Transformation logic
    end
  end
end

# Use it
fabric = WireGram.weave("let x = 42")
result = MyTransformations.inline_variables(fabric)
```

## API Reference

### Core Classes

- `WireGram::Core::Node` - Immutable AST node
- `WireGram::Core::Fabric` - Digital fabric representation
- `WireGram::Core::BaseLexer` - Base lexer class
- `WireGram::Core::BaseParser` - Base parser class

### Engine Classes

- `WireGram::Engines::Analyzer` - Code analysis
- `WireGram::Engines::Transformer` - Code transformation
- `WireGram::Engines::Recovery` - Error recovery

### Tool Classes

- `WireGram::Tools::Linter` - Linting framework
- `WireGram::Tools::AutoFixer` - Auto-fixing framework
- `WireGram::Tools::LanguageServer` - Language server foundation

## License

See LICENSE file for details.
