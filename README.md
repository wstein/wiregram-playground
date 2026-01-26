# WireGram Playground

A next-generation universal, declarative framework designed to unify the creation of code analysis and transformation tools.

## Overview

WireGram provides a single, high-fidelity engine capable of processing any structured language. By treating source code as a **reversible digital fabric**, it abstracts away complex optimization and error-recovery mechanisms, offering a resilient foundation for building next-generation language servers, linters, and auto-fixers that are both robust and efficient.

## Key Concepts

### Source Code as Digital Fabric
WireGram treats source code as a flexible, reversible fabric that can be:
- Analyzed without destructive transformations
- Modified while preserving structure and intent
- Recovered from errors automatically
- Optimized for different use cases

### Universal Language Support
The framework provides a unified interface for:
- Lexical analysis (tokenization)
- Syntactic analysis (parsing)
- Semantic analysis
- Code transformations
- Error recovery

### Declarative Transformations
Define code transformations declaratively:
```ruby
transform do |node|
  case node.type
  when :function_call
    optimize_call(node)
  when :variable_declaration
    validate_naming(node)
  end
end
```

## Architecture

```
┌─────────────────────────────────────────┐
│          WireGram Framework             │
├─────────────────────────────────────────┤
│  Source Code → Digital Fabric Engine    │
│                                         │
│  ┌───────────┐  ┌──────────┐            │
│  │  Lexer    │→ │  Parser  │            │
│  └───────────┘  └──────────┘            │
│        ↓            ↓                   │
│  ┌─────────────────────┐                │
│  │   AST Fabric        │                │
│  │  (Reversible)       │                │
│  └─────────────────────┘                │
│        ↓                                │
│  ┌─────────────────────┐                │
│  │  Transformation     │                │
│  │  Engine             │                │
│  └─────────────────────┘                │
│        ↓                                │
│  ┌─────────────────────┐                │
│  │  Output Generator   │                │
│  └─────────────────────┘                │
└─────────────────────────────────────────┘
```

## Getting Started

### Installation

This is a Ruby-based playground. Requirements:
- Ruby 2.7 or higher
- Bundler

```bash
bundle install
```

### Running tests

Run all tests (RSpec unit tests + Cucumber features) with coverage enabled by default:

```bash
bundle exec rake test
```

To run only the RSpec suite:

```bash
bundle exec rake spec
# or
bundle exec rspec
```

To run only the Cucumber features (coverage will also be collected):

```bash
bundle exec rake cucumber
# or
bundle exec cucumber
```

To disable coverage for faster test runs:

```bash
NO_COVERAGE=1 bundle exec rake test
```

Coverage reports (including branch coverage) are written to `coverage/index.html` by SimpleCov.

### Basic Usage

```ruby
require 'wiregram'

# Create a fabric from source code
fabric = WireGram.weave("let x = 42 + 10")

# Analyze the fabric
analyzer = WireGram::Analyzer.new(fabric)
results = analyzer.find_patterns(:arithmetic_operations)

# Transform the fabric
transformer = WireGram::Transformer.new(fabric)
optimized = transformer.apply(:constant_folding)

# Unweave back to source code
puts optimized.to_source  # => "let x = 52"
```

## Examples

See the `examples/` directory for practical demonstrations:
- `examples/simple_lexer.rb` - Basic tokenization
- `examples/expression_parser.rb` - Expression parsing
- `examples/code_analyzer.rb` - Code analysis
- `examples/auto_fixer.rb` - Automatic code fixes

## Use Cases

### Language Servers
Build robust language servers with built-in error recovery:
```ruby
server = WireGram::LanguageServer.new
server.on_change do |document|
  fabric = WireGram.weave(document.text)
  diagnostics = fabric.analyze
  completions = fabric.suggest_completions
end
```

### Linters
Create powerful linters with declarative rules:
```ruby
linter = WireGram::Linter.new do
  rule "no-unused-vars" do |fabric|
    fabric.find_unused_variables
  end
end
```

### Auto-fixers
Implement smart code transformations:
```ruby
fixer = WireGram::AutoFixer.new do
  fix "modernize-syntax" do |fabric|
    fabric.transform(:legacy_syntax, to: :modern_syntax)
  end
end
```

## Project Structure

```
.
├── lib/
│   ├── wiregram/
│   │   ├── core/
│   │   │   ├── fabric.rb        # Digital fabric abstraction
│   │   │   ├── lexer.rb         # Base lexer
│   │   │   ├── parser.rb        # Base parser
│   │   │   └── node.rb          # AST node
│   │   ├── engines/
│   │   │   ├── transformer.rb   # Transformation engine
│   │   │   ├── analyzer.rb      # Analysis engine
│   │   │   └── recovery.rb      # Error recovery
│   │   ├── languages/
│   │   │   └── expression/      # Example language
│   │   └── tools/
│   │       ├── linter.rb
│   │       ├── fixer.rb
│   │       └── server.rb
│   └── wiregram.rb
├── examples/
├── test/
└── README.md
```

## Contributing

This is a playground for exploring next-generation code analysis and transformation concepts. Feel free to experiment with new ideas and approaches!

## License

See LICENSE file for details.
