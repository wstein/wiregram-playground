# typed: false
# frozen_string_literal: true

require 'sorbet-runtime'

# Control flow: if/unless, case/when, loops
if x > 10
  puts 'big'
elsif x > 5
  puts 'medium'
else
  puts 'small'
end

puts 'yes'

case value
when 1, 2, 3
  puts 'one to three'
when 4..6
  puts 'four to six'
else
  puts 'something else'
end

counter += 1 while counter < 10

(1..5).each { |i| puts i }

x = 0
x += 1 until x == 10

# Ruby 3.4: Endless Methods
def square(x) = x * x
