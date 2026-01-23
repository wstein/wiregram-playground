# WireGram Playground - Project Overview

## Summary

This repository implements a **next-generation universal, declarative framework** (WireGram) designed to unify the creation of code analysis and transformation tools. The framework provides a single, high-fidelity engine capable of processing any structured language by treating source code as a **reversible digital fabric**.

## Implementation Statistics

- **Total Lines of Code**: ~1,800 lines
- **Core Library**: 902 lines (13 files)
- **Tests**: 234 lines (23 tests, 59 assertions, 100% pass rate)
- **Examples**: 300+ lines (4 complete examples)
- **Documentation**: 11+ KB (README, USAGE guide)

## Architecture Overview

```
WireGram Framework
├── Core Components (lib/wiregram/core/)
│   ├── Node - Immutable AST representation
│   ├── Fabric - Reversible code fabric
│   ├── BaseLexer - Foundation for tokenization
│   └── BaseParser - Foundation for parsing
│
├── Engines (lib/wiregram/engines/)
│   ├── Analyzer - Pattern detection & analysis
│   ├── Transformer - Code transformations
│   └── Recovery - Error recovery mechanisms
│
├── Languages (lib/wiregram/languages/)
│   └── Expression - Complete example language
│       ├── Lexer - Tokenization
│       └── Parser - AST generation
│
└── Tools (lib/wiregram/tools/)
    ├── Linter - Declarative linting framework
    ├── AutoFixer - Automatic code fixing
    └── LanguageServer - LSP foundation
```

## Key Features Implemented

### 1. Digital Fabric Abstraction
- Treats source code as a reversible digital fabric
- Perfect round-trip: source → AST → source
- Maintains structural integrity during transformations

### 2. Universal Language Support
- Base classes for lexers and parsers
- Pluggable language implementations
- Example implementation: expression language with operators, variables, and literals

### 3. Error Recovery
- Resilient tokenization with error recovery
- Graceful handling of malformed input
- Detailed error reporting with position tracking

### 4. Pattern Detection
- Find arithmetic operations
- Locate literals and identifiers
- Custom pattern matching support

### 5. Code Analysis
- Complexity metrics (operation count, tree depth)
- Diagnostic generation
- Optimization opportunity detection

### 6. Code Transformation
- Built-in transformations (constant folding)
- Custom transformation support
- Immutable, functional approach

### 7. Practical Tools
- **Linter**: Declarative rule-based code analysis
- **AutoFixer**: Automatic code optimization and fixing
- **Language Server**: Foundation for LSP implementation

## What's Included

### Library Structure (`lib/`)
```
lib/wiregram/
├── core/
│   ├── node.rb          # Immutable AST nodes
│   ├── fabric.rb        # Digital fabric abstraction
│   ├── lexer.rb         # Base lexer with error recovery
│   └── parser.rb        # Base parser with error recovery
├── engines/
│   ├── analyzer.rb      # Code analysis engine
│   ├── transformer.rb   # Transformation engine
│   └── recovery.rb      # Error recovery utilities
├── languages/
│   └── expression/
│       ├── lexer.rb     # Expression language lexer
│       └── parser.rb    # Expression language parser
└── tools/
    ├── linter.rb        # Linting framework
    ├── fixer.rb         # Auto-fixing framework
    └── server.rb        # Language server foundation
```

### Examples (`examples/`)
1. **simple_lexer.rb** - Demonstrates tokenization with error recovery
2. **expression_parser.rb** - Shows parsing and AST visualization
3. **code_analyzer.rb** - Illustrates pattern detection and analysis
4. **auto_fixer.rb** - Shows automatic code optimization

### Tests (`test/`)
- Comprehensive test suite covering all core functionality
- 23 tests, 59 assertions
- 100% pass rate
- Tests for: Node, Lexer, Parser, Fabric, Analyzer, Transformer

### Documentation
1. **README.md** - Project overview, architecture, getting started
2. **USAGE.md** - Detailed usage guide with code examples
3. **demo.rb** - Interactive demonstration of all features

## Quick Start

```bash
# Run the demo
ruby demo.rb

# Run examples
ruby examples/simple_lexer.rb
ruby examples/expression_parser.rb
ruby examples/code_analyzer.rb
ruby examples/auto_fixer.rb

# Run tests
ruby test/test_wiregram.rb
```

## Example Usage

```ruby
require 'wiregram'

# Weave source code into a fabric
fabric = WireGram.weave("let x = 10 + 20")

# Analyze the code
analyzer = fabric.analyze
puts analyzer.complexity

# Transform the code (constant folding)
optimized = fabric.transform(:constant_folding)
puts optimized.to_source  # => "let x = 30"
```

## Design Principles

1. **Reversibility** - All transformations maintain reversibility
2. **Immutability** - AST nodes are immutable for safety
3. **Resilience** - Built-in error recovery at all levels
4. **Extensibility** - Easy to add new languages and transformations
5. **Declarative** - Transformations and rules are declarative
6. **High-Fidelity** - Preserves all structural information

## Use Cases

This framework provides a foundation for building:

- **Language Servers** - LSP implementations with diagnostics and completions
- **Linters** - Custom code quality tools
- **Formatters** - Code formatting and style enforcement
- **Auto-fixers** - Automatic code correction
- **Refactoring Tools** - Safe code transformations
- **Code Analyzers** - Pattern detection and metrics
- **Optimization Tools** - Automatic code optimization

## Future Extensions

The framework is designed to be extended with:

- Additional language implementations (JavaScript, Python, etc.)
- More transformation types (inlining, dead code elimination, etc.)
- Advanced analysis (data flow, control flow, type inference)
- Integration with LSP and editor plugins
- Performance optimizations
- Incremental parsing

## Quality Assurance

✅ All tests passing (23/23)  
✅ No security vulnerabilities (CodeQL clean)  
✅ Code review feedback addressed  
✅ Comprehensive documentation  
✅ Working examples  
✅ Nil-safe code  
✅ Proper error handling  

## License

See LICENSE file for details.

---

**WireGram** - Treating code as a digital fabric for next-generation language tools.
