#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Expression parsing with WireGram
#
# This example demonstrates how to parse expressions into an AST
# and visualize the tree structure.

require_relative '../lib/wiregram'

def print_tree(node, indent = 0)
  return unless node.is_a?(WireGram::Core::Node)
  
  prefix = "  " * indent
  value_str = node.value ? " (#{node.value})" : ""
  puts "#{prefix}#{node.type}#{value_str}"
  
  node.children.each do |child|
    print_tree(child, indent + 1)
  end
end

puts "=== WireGram Expression Parser Example ==="
puts

# Example 1: Simple expression
source1 = "42 + 10"
puts "Expression: #{source1}"
fabric1 = WireGram.weave(source1)
puts "\nAST:"
print_tree(fabric1.ast)
puts "\nReversed back to source:"
puts "  #{fabric1.to_source}"
puts

# Example 2: Complex expression
source2 = "(10 + 5) * 2 - 3"
puts "\n" + "=" * 50
puts "Expression: #{source2}"
fabric2 = WireGram.weave(source2)
puts "\nAST:"
print_tree(fabric2.ast)
puts "\nReversed back to source:"
puts "  #{fabric2.to_source}"
puts

# Example 3: Variable assignment
source3 = "let x = 42 + 10"
puts "\n" + "=" * 50
puts "Expression: #{source3}"
fabric3 = WireGram.weave(source3)
puts "\nAST:"
print_tree(fabric3.ast)
puts "\nReversed back to source:"
puts "  #{fabric3.to_source}"
puts

# Example 4: Multiple operations
source4 = "let result = 100 / 5 + 3 * 2"
puts "\n" + "=" * 50
puts "Expression: #{source4}"
fabric4 = WireGram.weave(source4)
puts "\nAST:"
print_tree(fabric4.ast)
puts "\nReversed back to source:"
puts "  #{fabric4.to_source}"
