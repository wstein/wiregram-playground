# Ruby Test Suite Fixes - Status Report

## Date: 2026-02-02

## Issues Fixed

### 1. spec/spec_helper.rb
- **Issue**: Using Crystal's `spec` library instead of Ruby's `rspec`
- **Fix**: Changed `require "spec"` to `require "rspec"`
- **Issue**: Incorrect require path for warp library
- **Fix**: Changed `require_relative "../src/warp"` to `require_relative "../lib/warp"`

### 2. spec/unit/ruby_lexer_spec.rb
- **Issue**: Hash literals using Crystal tuple syntax `{key, value}` instead of Ruby array syntax
- **Fix**: Converted three hash literals to array syntax:
  - `{"+", ...}` → `["+", ...]`
  - `{"-", ...}` → `["-", ...]`
  - `{"*", ...}` → `["*", ...]`

### 3. spec/integration/arm_pi_parsing_spec.rb
- **Issue**: File contained extensive Crystal compile-time conditionals (`{% if flag?(:arm) %}`)
- **Fix**: Rewrote entire file to use Ruby runtime conditionals:
  - Added `is_arm_system?` helper method
  - Converted all `{% if %}...{% end %}` blocks to `skip()` statements
  - Changed `RSpec.should` to proper Ruby syntax

### 4. lib/warp.rb
- **Issue**: Using Crystal's `alias` syntax with `=` operator
- **Fix**: Converted type aliases to Ruby constant assignments:
  - `alias ErrorCode = Core::ErrorCode` → `ErrorCode = Core::ErrorCode`
  - Moved alias definitions after requires to ensure modules are loaded

## Test Results

After fixes, Ruby tests now load and parse correctly. However, the implementation files (lib/warp/**/*.rb) contain extensive Crystal syntax that needs to be converted.

### Current Status

```
✅ Test files: Syntax fixed
✅ Spec helper: Fixed
❌ Implementation files: Contain Crystal syntax (enums, type annotations, getters)
```

## Remaining Work

The following issues require further attention:

### 1. Crystal Type Annotations in Ruby Files
Files like `lib/warp/ast/types.rb` contain Crystal type annotations that are invalid in Ruby:
```crystal
# Crystal syntax (invalid in Ruby)
def initialize(@kind : NodeKind, @children : Array(Node) = [], @value : String? = nil)
  getter kind : NodeKind
end

# Should be converted to Ruby:
attr_reader :kind, :children, :value

def initialize(kind, children = [], value = nil)
  @kind = kind
  @children = children
  @value = value
end
```

### 2. Crystal Enums
Crystal `enum` declarations need to be converted to Ruby constants or classes:
```crystal
# Crystal
enum NodeKind
  Root
  Object
  Array
end

# Ruby equivalent
module NodeKind
  ROOT = :root
  OBJECT = :object
  ARRAY = :array
end
```

### 3. Crystal String Interpolation with String.build
Needs to be replaced with Ruby string operations:
```crystal
# Crystal
String.build [ |io| io.write(bytes[token.start, token.length]) ]

# Ruby
String.new(bytes[token.start..token.start+token.length])
```

### 4. Crystal-style Map Operations
Replace Crystal's bracket syntax for map operations:
```crystal
# Crystal
node.children.map [ |child| build_node(child, doc.bytes) ]

# Ruby
node.children.map { |child| build_node(child, doc.bytes) }
```

### Affected Files (Sample)
- `lib/warp/ast/types.rb`
- `lib/warp/core/types.rb`
- `lib/warp/cst/types.rb`
- `lib/warp/dom/builder.rb`
- `lib/warp/dom/value.rb`
- And approximately 15+ other implementation files

## Recommendation

The Ruby port appears to be an incomplete transpilation from Crystal. The test files have been fixed, but a comprehensive refactoring of the implementation files would be needed for the tests to run successfully.

### Quick Fix Options

1. **Use Rubocop or RuboCop --fix**: Might help with some syntax issues
2. **Use Crystal-to-Ruby transpiler**: Could automate the conversion of common patterns
3. **Selective Testing**: Focus on testing specific modules that are needed first
4. **Phase-based Approach**: Convert files in priority order based on test dependencies

## Files Modified

1. `/ports/ruby/spec/spec_helper.rb` - Fixed requires
2. `/ports/ruby/spec/unit/ruby_lexer_spec.rb` - Fixed hash syntax
3. `/ports/ruby/spec/integration/arm_pi_parsing_spec.rb` - Removed Crystal conditionals
4. `/ports/ruby/lib/warp.rb` - Fixed alias syntax
