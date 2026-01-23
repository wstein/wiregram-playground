#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Code analysis with WireGram
#
# This example demonstrates how to analyze code patterns,
# find optimization opportunities, and generate diagnostics.

require_relative '../lib/wiregram'

puts "=== WireGram Code Analyzer Example ==="
puts

# Example 1: Finding arithmetic operations
source1 = "let x = 42 + 10 * 2 - 5"
puts "Source code:"
puts "  #{source1}"
puts

fabric1 = WireGram.weave(source1)
analyzer1 = fabric1.analyze

# Find all arithmetic operations
operations = analyzer1.find_patterns(:arithmetic_operations)
puts "Arithmetic operations found: #{operations.length}"
operations.each do |op|
  puts "  - #{op.type}"
end
puts

# Analyze complexity
complexity = analyzer1.complexity
puts "Complexity metrics:"
puts "  Operations: #{complexity[:operations_count]}"
puts "  Tree depth: #{complexity[:tree_depth]}"
puts

# Example 2: Finding optimization opportunities
source2 = "let result = 10 + 20"
puts "\n" + "=" * 50
puts "Source code (with constant expression):"
puts "  #{source2}"
puts

fabric2 = WireGram.weave(source2)
analyzer2 = fabric2.analyze

# Get diagnostics
diagnostics = analyzer2.diagnostics
puts "Diagnostics:"
if diagnostics.empty?
  puts "  No issues found"
else
  diagnostics.each do |diag|
    puts "  [#{diag[:severity].upcase}] #{diag[:message]}"
  end
end
puts

# Example 3: Pattern analysis
source3 = "let a = 5 + 3 let b = 10 * 2 let c = a + b"
puts "\n" + "=" * 50
puts "Source code (multiple statements):"
puts "  #{source3}"
puts

fabric3 = WireGram.weave(source3)
analyzer3 = fabric3.analyze

# Find literals
literals = analyzer3.find_patterns(:literals)
puts "Literals found: #{literals.length}"
literals.each do |lit|
  puts "  - #{lit.type}: #{lit.value}"
end
puts

# Find identifiers
identifiers = analyzer3.find_patterns(:identifiers)
puts "Identifiers found: #{identifiers.length}"
identifiers.each do |id|
  puts "  - #{id.value}"
end
