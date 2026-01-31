# frozen_string_literal: true
# typed: false

require 'sorbet-runtime'

# Simple Ruby file: basic structure
sig { returns(String) }
def hello
  'Hello, World!'
end

puts hello

sig { params(x: Integer).returns(Integer) }
def square(x)
  x * x
end

puts square(5)
