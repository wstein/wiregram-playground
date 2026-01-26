#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Basic tokenization with the WireGram lexer
#
# This example demonstrates how to use the WireGram lexer to tokenize
# source code into a stream of tokens.

require_relative '../lib/wiregram'
require_relative '../lib/wiregram/languages/expression/lexer'

puts '=== WireGram Simple Lexer Example ==='
puts

# Sample code to tokenize
source_code = 'let x = 42 + 10'

puts 'Source code:'
puts "  #{source_code}"
puts

# Create a lexer
lexer = WireGram::Languages::Expression::Lexer.new(source_code)

# Tokenize the source
tokens = lexer.tokenize

puts 'Tokens:'
tokens.each_with_index do |token, i|
  puts "  #{i}. #{token[:type].to_s.ljust(12)} #{token[:value].inspect}"
end
puts

# Example with more complex expression
complex_source = 'let result = (10 + 5) * 2 - 3'

puts 'Complex source code:'
puts "  #{complex_source}"
puts

lexer2 = WireGram::Languages::Expression::Lexer.new(complex_source)
tokens2 = lexer2.tokenize

puts 'Tokens:'
tokens2.each_with_index do |token, i|
  puts "  #{i}. #{token[:type].to_s.ljust(12)} #{token[:value].inspect}"
end
puts

# Example with error recovery
bad_source = 'let x = 42 + @invalid'

puts 'Source with invalid character:'
puts "  #{bad_source}"
puts

lexer3 = WireGram::Languages::Expression::Lexer.new(bad_source)
tokens3 = lexer3.tokenize

puts 'Tokens (with error recovery):'
tokens3.each_with_index do |token, i|
  puts "  #{i}. #{token[:type].to_s.ljust(12)} #{token[:value].inspect}"
end

if lexer3.errors.any?
  puts "\nErrors found:"
  lexer3.errors.each do |error|
    puts "  - Unknown character '#{error[:char]}' at position #{error[:position]}"
  end
end
