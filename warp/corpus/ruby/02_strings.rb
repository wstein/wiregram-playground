# typed: strict
# String literals and interpolation
single_quoted = T.let('single quoted string', String)
double_quoted = T.let("double quoted string", String)
interpolated = T.let("Value: #{1 + 2}", String)
escaped = T.let("Escaped: \n\t\"", String)

percent_string = %q(percent quoted)
percent_interpolated = %Q(percent #{1 + 1})

symbol = :symbol_literal
symbol_interpolated = :"symbol_#{42}"

# Ruby 3.4: Chilled Strings
# Warning when mutating literal strings
s1 = "mutable"
s1 << " mutation" #=> warning: literal string will be frozen in the future

# Explicitly mutable (suppresses warning)
s2 = +"mutable"
s2 << " safe mutation"

# Ruby 3.4: Byte-based String Operations
str = "string".b
str.append_as_bytes(0xFF)
