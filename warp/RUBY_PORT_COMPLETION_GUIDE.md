# Ruby Port Completion Guide

## Overview
The Ruby port of the Warp JSON parser requires conversion of ~20 implementation files from Crystal syntax to pure Ruby. This guide documents the required transformations.

## Files Requiring Conversion

### Priority 1: Core Types (Required for all tests)
```
lib/warp/parallel/cpu_detector.rb
lib/warp/parallel/worker_pool.rb
lib/warp/cst/types.rb
lib/warp/ir/types.rb
lib/warp/dom/types.rb
```

### Priority 2: Builders and Visitors (Required for parsing tests)
```
lib/warp/ast/builder.rb
lib/warp/cst/builder.rb
lib/warp/ir/builder.rb
lib/warp/dom/builder.rb
```

### Priority 3: Remaining Implementation
```
lib/warp/backend/avx_backend.rb (create or stub)
lib/warp/backend/avx2_backend.rb (create or stub)
lib/warp/backend/avx512_backend.rb (create or stub)
lib/warp/backend/armv6_backend.rb (create or stub)
lib/warp/backend/neon_backend.rb (create or stub)
lib/warp/backend/neon_masks.rb (create or stub)
lib/warp/lang/***/* (all language-specific implementations)
```

## Conversion Patterns

### Pattern 1: Enum Declaration
**Crystal:**
```crystal
enum NodeKind
  Root
  Object
  Array
  Pair
  String
  Number
  True
  False
  Null
end

def get_kind
  NodeKind::Root  # Access via ::
end
```

**Ruby:**
```ruby
module NodeKind
  Root = :root
  Object = :object
  Array = :array
  Pair = :pair
  String = :string
  Number = :number
  True = :true
  False = :false
  Null = :null
end

def get_kind
  NodeKind::Root  # Same syntax works
end
```

### Pattern 2: Struct with Getters
**Crystal:**
```crystal
struct Node
  getter kind : NodeKind
  getter children : Array(Node)
  getter value : String?
  getter position : Int32

  def initialize(@kind : NodeKind, @children : Array(Node) = [], @value : String? = nil, @position : Int32 = 0)
  end
end
```

**Ruby:**
```ruby
class Node
  attr_reader :kind
  attr_reader :children
  attr_reader :value
  attr_reader :position

  def initialize(kind, children = [], value = nil, position = 0)
    @kind = kind
    @children = children
    @value = value
    @position = position
  end
end
```

### Pattern 3: Type Annotations Everywhere
**Crystal:**
```crystal
def process_node(node : Node, depth : Int32) : String
  result : String = ""
  items : Array(Node) = node.children
  count : Int32 = items.size
  return result
end
```

**Ruby:**
```ruby
def process_node(node, depth)
  result = ""
  items = node.children
  count = items.size
  result
end
```

### Pattern 4: Block Syntax (Square Brackets)
**Crystal:**
```crystal
def collect_nodes
  nodes = items.map [ |item| item.node ]
  filtered = nodes.select [ |n| n.valid? ]
  transformed = filtered.map [ |n| transform(n) ]
  transformed
end
```

**Ruby:**
```ruby
def collect_nodes
  nodes = items.map { |item| item.node }
  filtered = nodes.select { |n| n.valid? }
  transformed = filtered.map { |n| transform(n) }
  transformed
end
```

### Pattern 5: String Building
**Crystal:**
```crystal
def build_output
  output = String.build [ |io|
    io.write("prefix:")
    io.write(buffer[start, length])
    io.write(":suffix")
  ]
  output
end
```

**Ruby:**
```ruby
def build_output
  output = "prefix:" + buffer[start, length].to_s + ":suffix"
  output
end

# Or using StringBuilder pattern
def build_output
  io = StringIO.new
  io.write("prefix:")
  io.write(buffer[start, length].to_s)
  io.write(":suffix")
  io.string
end
```

### Pattern 6: Numeric Suffixes
**Crystal:**
```crystal
mask : UInt64 = 0xFF_u64
value : Int32 = 42_i32
float_val : Float64 = 3.14_f64
size : USize = buffer.size_usize
count = 10_u8
```

**Ruby:**
```ruby
mask = 0xFF
value = 42
float_val = 3.14
size = buffer.size
count = 10
```

### Pattern 7: Nil-Coalescing and Optional Types
**Crystal:**
```crystal
def get_value
  value : String? = nil
  result = value || "default"
  return result
end

def process(data : Array(UInt8)?)
  if data
    process_bytes(data)
  else
    process_empty
  end
end
```

**Ruby:**
```ruby
def get_value
  value = nil
  result = value || "default"
  result
end

def process(data = nil)
  if data
    process_bytes(data)
  else
    process_empty
  end
end
```

### Pattern 8: Multiple Return Values (Case statements)
**Crystal:**
```crystal
case node.kind
when NodeKind::Root
  handle_root(node)
when NodeKind::Object, NodeKind::Array
  handle_container(node)
else
  handle_other(node)
end
```

**Ruby:**
```ruby
case node.kind
when NodeKind::Root
  handle_root(node)
when NodeKind::Object, NodeKind::Array
  handle_container(node)
else
  handle_other(node)
end
```

### Pattern 9: Method Visibility
**Crystal:**
```crystal
class MyClass
  private def private_method
    puts "private"
  end

  private def self.class_private_method
    puts "class private"
  end
end
```

**Ruby:**
```ruby
class MyClass
  private

  def private_method
    puts "private"
  end

  def self.class_private_method
    puts "class private"
  end

  private_class_method :class_private_method
end
```

### Pattern 10: Compile-time Conditionals
**Crystal/Ruby Tests:**
```crystal
{% if flag?(:aarch64) %}
  # ARM code
{% end %}
```

**Ruby (Runtime Conditional):**
```ruby
def is_aarch64?
  RbConfig::CONFIG["host_cpu"].match?(/aarch64|arm64/)
end

if is_aarch64?
  # ARM code
else
  skip "aarch64 required"
end
```

## Automated Conversion Script (Example)

```bash
#!/bin/bash

# Remove numeric suffixes
find lib -name "*.rb" -exec sed -i '' \
  -e 's/_u8\b//g' \
  -e 's/_u16\b//g' \
  -e 's/_u32\b//g' \
  -e 's/_u64\b//g' \
  -e 's/_i8\b//g' \
  -e 's/_i16\b//g' \
  -e 's/_i32\b//g' \
  -e 's/_i64\b//g' \
  -e 's/_f32\b//g' \
  -e 's/_f64\b//g' \
  {} \;

# Convert bracket blocks to brace blocks
find lib -name "*.rb" -exec sed -i '' \
  's/\[\s*|/{ |/g' \
  {} \;

# Convert struct to class
find lib -name "*.rb" -exec sed -i '' \
  's/^\s*struct\s/  class /g' \
  {} \;

# Convert getter declarations (requires more careful handling)
# This is semi-manual - pattern: getter name : Type
# Becomes: attr_reader :name
```

## Testing Strategy

### Phase 1: Single File Validation
1. Convert one file
2. Check syntax: `ruby -c lib/warp/path/file.rb`
3. Load in test: `bundle exec rspec spec/` (to see new errors)
4. Fix any runtime issues

### Phase 2: Incremental Integration
1. Convert Priority 1 files completely
2. Run tests, validate no new errors
3. Move to Priority 2
4. Repeat for Priority 3

### Phase 3: Full Test Execution
```bash
cd /Users/werner/github.com/wstein/wiregram-playground/warp/ports/ruby
bundle exec rspec spec/ --format progress
```

## Validation Checklist

- [ ] All files have valid Ruby syntax
- [ ] No Crystal keywords remain (enum, getter, struct with type annotations)
- [ ] No numeric suffixes (_u8, _i32, etc.)
- [ ] No bracket block syntax ([ | ] → { | })
- [ ] No `[] of Type` or `{} of K => V` patterns
- [ ] All type annotations removed
- [ ] All .not_nil! calls handled
- [ ] All Crystal compile-time conditionals converted to runtime
- [ ] Backend files either exist or properly stubbed/commented
- [ ] All tests load without SyntaxError
- [ ] Tests execute and show results (pass/fail)

## Common Issues and Fixes

### Issue: "unexpected ':', expecting end-of-input"
**Cause**: Type annotation in method signature or variable
**Fix**: Remove the `: Type` part

### Issue: "trailing '_' in number"
**Cause**: Numeric suffix like _u64, _i32
**Fix**: Remove the suffix entirely

### Issue: "expected a delimiter after the predicates"
**Cause**: Square bracket block `[ |x| ]` instead of brace `{ |x| }`
**Fix**: Replace brackets with braces

### Issue: "unexpected local variable or method"
**Cause**: `[] of Type` or `{} of K => V` syntax
**Fix**: Use plain `[]` or `{}`

### Issue: "cannot load such file"
**Cause**: Missing backend files
**Fix**: Create stubs or comment out requires in warp.rb

## Estimated Timeline

```
Files to convert: ~20-25
Average per file: 15-20 minutes
- Reading and understanding: 5 min
- Conversion: 10 min
- Validation: 5 min

Total: 5-8 hours for full conversion
+ 2-3 hours for runtime validation
= 8-10 hours total
```

## Success Criteria

1. ✅ All implementation files have valid Ruby syntax
2. ✅ `bundle exec rspec spec/` loads without SyntaxError
3. ✅ Tests execute and produce results (not 0 examples)
4. ✅ Majority of tests pass (>80%)
5. ✅ Remaining failures are runtime issues, not syntax

---

**Current Status**: 2 of ~22 files converted (10%)  
**Next Action**: Convert Priority 1 files in parallel
