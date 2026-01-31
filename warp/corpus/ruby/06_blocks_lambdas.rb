# typed: false
# frozen_string_literal: true

require 'sorbet-runtime'

# Blocks, lambdas, procs
[1, 2, 3].each { |n| puts n }

[1, 2, 3].map do |n|
  n * 2
end

def yield_example
  yield(1, 2) if block_given?
end

yield_example { |a, b| puts a + b }

# Ruby 3.4: The 'it' Parameter
%w[a b].map { it.upcase }

# Ruby 3.4: Relaxed Float Parsing
1 #=> 1.0
  .val2 = 1.E - 1 #=> 0.1

# Ruby 3.4: Large Integer Exponents
10**10_000_000
