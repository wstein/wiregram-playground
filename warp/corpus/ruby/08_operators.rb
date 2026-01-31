# frozen_string_literal: true
# typed: false

# Operators and expressions
require 'sorbet-runtime'

a = 10
b = 20
a**b
true || false

1..10
1...10

obj&.method_name

# Ruby 3.4: Complex Ranges
# Range from 1 to ..2
1.....2

# Range with float-like syntax
1...0.2
