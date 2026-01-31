# frozen_string_literal: true
# typed: strict

require 'sorbet-runtime'

# String literals and interpolation
T.let('single quoted string', String)
T.let('double quoted string', String)
T.let("Value: #{1 + 2}", String)
T.let("Escaped: \n\t\"", String)

# Ruby 3.4: Chilled Strings
# Warning when mutating literal strings
s1 = 'mutable'
s1 << ' mutation' #=> warning: literal string will be frozen in the future

# Explicitly mutable (suppresses warning)
s2 = +'mutable'
s2 << ' safe mutation'

# Ruby 3.4: Byte-based String Operations
str = 'string'.b
str.append_as_bytes(0xFF)
