# Enhanced Lexer Error Reporting Examples

This file demonstrates the enhanced error reporting capabilities.

## Basic Usage

Create a test file with a lexical error:

```ruby
# broken.rb
def greet(name)
  message = "Hello
  puts message
end
```

Run Warp:

```sh
crystal run bin/warp.cr -- transpile crystal -s broken.rb
```

Expected output:

```text
Using config: .warp.yaml
Error: Lexical error

LexError at 2:15: Unterminated string literal

   1 | def greet(name)
   2 |   message = "Hello
       ^^^^^^^^^^^^^^^^^
   3 |   puts message
   4 | end
```

## Creating LexerError Objects

```crystal
require "warp"

source = "str = \"unterminated"
bytes = source.to_slice

# Create error at position of opening quote
position = source.index("\"unterminated").not_nil!

error = Warp::Lang::Ruby::LexerError.new(
  Warp::Core::ErrorCode::StringError,
  "Unterminated string literal",
  bytes,
  position
)

# Print formatted error
puts error.to_s
puts ""
puts "Line: #{error.line}"
puts "Column: #{error.column}"
puts "Content: #{error.line_content}"
```

Output:

```text
LexError at 1:8: Unterminated string literal

   1 | str = "unterminated
       ^^^^^^^^
```

## Integration with Lexer

The lexer can be enhanced to return `LexerError`:

```crystal
module Warp::Lang::Ruby
  class Lexer
    def self.scan(bytes : Bytes) : {Array(Token), ErrorCode}
      # Current implementation
    end

    def self.scan_with_context(bytes : Bytes) : {Array(Token), LexerError?}
      tokens = [] of Token
      i = 0
      len = bytes.size

      # ... lexing logic ...

      if error_code != ErrorCode::Success
        error = LexerError.new(error_code, error_message, bytes, position)
        return {tokens, error}
      end

      {tokens, nil}
    end
  end
end
```

## Error Handling in CLI

```crystal
# In CLI runner
tokens, lex_error = Lexer.scan(bytes)
if lex_error
  puts lex_error.to_s
  return 1
end
```

## Advanced: Multiple Errors

Future enhancement for collecting multiple errors:

```crystal
module Warp::Lang::Ruby
  class Lexer
    def self.scan_all_errors(bytes : Bytes) : {Array(Token), Array(LexerError)}
      errors = [] of LexerError
      # Collect all lexer errors instead of stopping at first
      {tokens, errors}
    end
  end
end
```

Usage:

```crystal
tokens, errors = Lexer.scan_all_errors(bytes)

if !errors.empty?
  puts "#{errors.size} lexical errors found:\n"
  errors.each do |error|
    puts error.to_s
    puts ""
  end
  return 1
end
```

## Custom Error Messages

Create context-specific errors:

```crystal
# Helpful message for common mistakes
case
when source.includes?("<<HEREDOC") && !source.includes?("HEREDOC")
  message = "Unterminated heredoc: missing terminator 'HEREDOC'"
when source.includes?("%{") && !source.includes?("}")
  message = "Unterminated percent literal: missing closing '}'"
when source.includes?("%Q{") && !source.includes?("}")
  message = "Unterminated percent string: missing closing '}'"
else
  message = "Unterminated string literal"
end

error = LexerError.new(ErrorCode::StringError, message, bytes, position)
```

## Testing Error Context

Unit test showing error extraction:

```crystal
describe "LexerError context extraction" do
  it "extracts correct line and column" do
    source = "line1\nline2 = \"unterminated\nline3"
    bytes = source.to_slice
    
    # Position of opening quote
    position = source.index("\"unterminated").not_nil!
    
    error = Warp::Lang::Ruby::LexerError.new(
      ErrorCode::StringError,
      "Unterminated string",
      bytes,
      position
    )
    
    error.line.should eq(2)
    error.column.should eq(10)
    error.line_content.should eq("line2 = \"unterminated")
  end

  it "builds correct context snippet" do
    source = "a = 1\nb = \"unclosed\nc = 3"
    bytes = source.to_slice
    position = source.index("\"unclosed").not_nil!
    
    error = Warp::Lang::Ruby::LexerError.new(
      ErrorCode::StringError,
      "Unterminated string",
      bytes,
      position
    )
    
    context = error.context
    context.should contain("→")  # Error line marker
    context.should contain("a = 1")  # Context before
    context.should contain("c = 3")  # Context after
  end
end
```

## Performance Considerations

- **Lazy context extraction**: Context is only built when accessing the error
- **Minimal overhead**: Line/column calculation is O(n) but typically small files
- **Memory efficient**: Stores reference to source bytes, not copies
- **Zero-copy snippets**: String views used where possible

## Future Improvements

1. **Color support**: Highlight error markers and line numbers
2. **Multi-error reporting**: Collect all errors in one pass
3. **Recovery suggestions**: "Did you mean...?" suggestions
4. **IDE integration**: Machine-readable JSON format
5. **Caching**: Cache line/column lookups for repeated errors
