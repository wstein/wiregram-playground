# String literals and interpolation
# Tests various string syntaxes available in Crystal

# Basic string literals
str1 = "Double quoted"
str2 = 'Single quoted'

# String interpolation
name = "Alice"
message = "Hello, #{name}!"
complex = "Result: #{1 + 2 * 3}"

# Escape sequences
escaped = "Line 1\nLine 2\tTabbed"
quoted = "Contains \"quotes\""

# String literals with special syntax
symbols = %w(apple banana cherry)
array_q = %q{single quoted literal}
array_Q = %Q{interpolated #{name} literal}

# Percent strings
percent_r = %r{/path/to/regex}

# Multi-line strings
multiline = "This is a
multi-line string
with multiple lines"
