# Ruby Corpus for Warp Testing

This directory contains Ruby source files to test the Warp Ruby lexer, parser, and formatter.

## Files

- **00_simple.rb** - Basic method definition and call
- **01_methods.rb** - Methods with various signatures (default args, splat, kwargs)
- **02_strings.rb** - String literals (single, double, interpolated, percent strings, symbols)
- **03_heredocs.rb** - Heredoc strings (challenging edge case!)
- **04_regex.rb** - Regular expression literals
- **05_classes.rb** - Class definitions and inheritance
- **06_blocks_lambdas.rb** - Blocks, lambdas, and procs
- **07_control_flow.rb** - if/elsif/else, unless, case/when, loops
- **08_operators.rb** - Operators and expressions
- **09_comments.rb** - Single-line and multi-line comments
- **10_complex.rb** - Real-world module with classes and methods
- **11_ruby34_features.rb** - Ruby 3.4 specific features

## Edge Cases Covered

✓ String interpolation  
✓ Heredoc literals (including squiggly)  
✓ Regular expressions  
✓ Block syntax (both `{ }` and `do..end`)  
✓ Method signatures (default args, splats, kwargs)  
✓ Class inheritance  
✓ Operator precedence  
✓ Multi-line comments  
✓ Safe navigation operator (`&.`)  
✓ Range literals  
✓ Symbol literals  
✓ Chilled strings (Ruby 3.4)  
✓ The `it` parameter (Ruby 3.4)  
✓ Relaxed float parsing (Ruby 3.4)  
✓ Large integer exponents (Ruby 3.4)  
✓ Byte-based string operations (Ruby 3.4)  
✓ Method forwarding (Ruby 3.4)  
✓ Endless methods (Ruby 3.4)  
✓ Complex ranges (Ruby 3.4)  
✓ Incomplete flip-flops (Ruby 3.4)  
✓ Complex rescue targets (Ruby 3.4)  
✓ Ambiguous syntax (Ruby 3.4)  
✓ Reserved constants (Ruby 3.4)  

## Testing Strategy

For each file, the ideal test is:

```crystal
source = File.read("corpus/ruby/XX_name.rb")
doc = Warp::Lang::Ruby::Parser.parse(source)
output = Warp::Lang::Ruby::Formatter.format(doc, mode: :preserve)
assert output == source  # Byte-for-byte equality
```

This validates:

1. **Parsing correctness** - Can we parse Ruby?
2. **CST completeness** - Does CST capture all structure?
3. **Formatting fidelity** - Can we round-trip perfectly?

## Adding More Test Files

When adding new edge cases, consider:

- String features (percent strings, %w arrays, etc.)
- Complex expressions (method chaining, operator precedence)
- Visibility modifiers (private, protected, public)
- Metaprogramming (define_method, method_missing, etc.)
- Error handling (begin/rescue/ensure/retry)
- Pattern matching (case...in)
- Type annotations (Sorbet sigs)

## Known Challenges

1. **Heredocs** - Must track indentation level and "end marker"
2. **String interpolation** - Nested expressions inside `#{...}`
3. **Optional parentheses** - `method_name arg1, arg2` without parens
4. **Whitespace sensitivity** - Trailing commas in arrays/hashes
5. **Method definitions** - `def method(a:, b: default)` with keyword args
