#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: JSON parsing with WireGram
# Demonstrates parsing JSON into an AST and printing it.

require_relative '../lib/wiregram'

def print_tree(node, indent = 0)
  return unless node.is_a?(WireGram::Core::Node)

  prefix = '  ' * indent
  value_str = node.value.nil? ? '' : " (#{node.value.inspect})"
  puts "#{prefix}#{node.type}#{value_str}"

  node.children.each do |child|
    print_tree(child, indent + 1)
  end
end

puts '=== WireGram JSON Parser Example ==='
puts

source1 = '{"name": "Alice", "age": 30, "active": true, "tags": ["dev","ruby"]}'
puts "JSON: #{source1}"
fabric1 = WireGram.weave(source1, language: :json)
puts "\nAST:"
print_tree(fabric1.ast)
puts "\nReversed back to source:"
puts "  #{fabric1.to_source}"
