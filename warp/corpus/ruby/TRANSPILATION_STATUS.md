# Ruby → Crystal Transpilation Status

## Architecture Transition: AST → CST

⚠️ **Major Refactor in Progress**: Transitioning from AST-based to CST-based transpilation.

- **Current (AST)**: Loses formatting, reconstructs code from scratch
- **New (CST)**: Preserves formatting, minimal targeted edits
- **Status**: Design complete ([papers/cst-transpiler-design.adoc](../../papers/cst-transpiler-design.adoc)), implementation starting

**Benefits of CST Approach:**

- Preserves original formatting, whitespace, comments
- Minimal diffs (only transformed code changes)
- Professional transpiler quality
- Easier debugging and review

## Corpus File Status

| File | Status | Notes |
| ---- | ------ | ----- |
| 00_simple.rb | ✅ Working | Sorbet `sig { returns(Type) }` correctly transpiles to Crystal `def name : Type` |
| 01_methods.rb | ✅ Partial | Simple methods + sig work; complex params (splat, kwargs, forwarding) marked OPAQUE |
| 02_strings.rb | ⚠️ Partial | `T.let()` works; symbol interpolation `:"value_#{expr}"` causes errors |
| 03_heredocs.rb | ❌ Failing | Heredoc parsing needs work; complex expressions not emitted correctly |
| 04_regex.rb | ✅ Working | `T.let(regex, Regexp)` transpiles correctly to Crystal assignments |
| 05_classes.rb | ❌ Failing | sig blocks inside classes cause unterminated call errors |
| 06_blocks_lambdas.rb | ✅ Partial | Basic blocks with do-params work; lambda/Proc literals need work |
| 07_control_flow.rb | ❌ Failing | elsif/else chains not parsed; multiline if breaks |
| 08_operators.rb | ❌ Failing | Complex operator expressions with << and >> cause unterminated calls |
| 09_comments.rb | ❌ Failing | Comments with special tokens break parsing |
| 10_complex.rb | ❌ Failing | require with parens not handled |
| 11_sorbet_annotations.rb | ✅ Partial | Class methods, namespace resolution (T::Sig) now working; range operators, pattern matching still failing |

## Completed Features

### Sorbet Type Annotation Support ✅

**Implemented:**

- `sig { returns(Type) }` blocks before methods
- Automatic extraction of return types from sig blocks
- Transpilation to Crystal type annotations (`def name : Type`)
- `T.let(value, Type)` for variable type annotations
- Metadata propagation from AST → IR → Crystal output

**Examples:**

```ruby
# Ruby with Sorbet
sig { returns(String) }
def hello
  "world"
end
```

Transpiles to:

```crystal
def hello : String
  "world"
end
```

### Lexer ✅

- String literals (single/double quoted, basic escape sequences)
- Regex literals
- Number and float parsing
- Comment handling (basic)
- Heredoc detection
- Operator tokenization (arithmetic, comparison, logical)
- Symbol literals (basic)

✅ **Parser (Conservative):**

- Method definitions (basic signatures)
- Class definitions (with inheritance via `<`)
- Module definitions
- If/unless/while control flow (basic)
- Blocks with `do |params| ... end` (basic)
- Method calls (with receiver and arguments)
- Arrays and hashes (literal syntax)
- Variable assignments
- Binary operations

✅ **IR & Transpilation:**

- AST → IR mapping
- IR → Crystal AST lowering
- Literal type inference (Int, Float, String, Regex, Bool, Nil)
- Method return type annotation for literal returns
- String literal normalization (single → double quotes)
- Class inheritance rendering

✅ **Output Quality:**

- Valid Crystal syntax for working examples
- Opaque comments for unsupported constructs
- Method body omission for garbled complex parameters

## Known Limitations & Next Steps

### Parser Gaps

- [x] Sorbet `sig { }` blocks - ✅ **Completed!**
- [x] `T.let(value, Type)` annotations - ✅ **Completed!**
- [ ] Sorbet `params` extraction from sig blocks
- [ ] Complex parameter forms (splat `*args`, keyword `**kwargs`, forwarding `...`)
- [ ] elsif/else branches after if
- [ ] Lambda and Proc literals
- [ ] Symbol interpolation (`:("value_#{expr}"`)
- [ ] String mutation operators (`<<` on strings)
- [ ] require/load statements with arguments
- [ ] Method call without parens (bare args)
- [ ] Safe navigation (`.&`)
- [ ] Range literals (`1..10`, `1...10`)

### Type System

- [ ] Generic types (Array[T], Hash[K, V])
- [ ] Union types (T1 | T2)
- [ ] Optional types (T?)
- [ ] Custom class types
- [ ] Method overloading via sig

### Runtime Shims

- [ ] super(...) forwarding
- [ ] yield and block_given?

### Output Quality

- [ ] More granular diagnostics (lossy mappings, conversion notes)
- [ ] Escape sequence preservation and normalization
- [ ] Preserve comments in output
- [ ] Formatting alignment with Crystal idioms

## Command-Line Usage

```bash
crystal run bin/rtc.cr -- --help
crystal run bin/rtc.cr -- --emit ast corpus/ruby/file.rb
crystal run bin/rtc.cr -- --emit ir corpus/ruby/file.rb
crystal run bin/rtc.cr -- --diagnostics corpus/ruby/file.rb | crystal tool format -
```

## Next Priority Work

1. **Fix Sorbet annotation parsing** – Detect and skip/preserve `: Type` in method signatures
2. **Improve if/elsif/else branching** – Parse multiline conditionals
3. **Add lambda/Proc support** – Transpile to Crystal blocks or Proc.new
4. **Expand runtime shims** – Generate Crystal properties from attr_*
5. **Add diagnostics output** – Report lossy mappings to STDERR
6. **Round-trip tests** – Run transpiled Crystal and verify behavior matches Ruby
