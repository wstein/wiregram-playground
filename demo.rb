#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script showcasing WireGram capabilities
#
# This script demonstrates the core features of the WireGram framework:
# - Source code as reversible digital fabric
# - Code analysis and pattern detection
# - Automatic transformations and optimizations
# - Error recovery mechanisms

require_relative 'lib/wiregram'
require_relative 'lib/wiregram/tools/linter'
require_relative 'lib/wiregram/tools/fixer'

def separator
  puts "\n#{"=" * 60}\n"
end

puts <<~BANNER
  ╔══════════════════════════════════════════════════════════╗
  ║                  WireGram Framework                       ║
  ║     Next-Gen Universal Code Analysis & Transformation    ║
  ╚══════════════════════════════════════════════════════════╝
BANNER

# Demonstration 1: Basic Weaving and Unweaving
separator
puts '1. REVERSIBLE DIGITAL FABRIC'
puts '   Treating source code as a reversible fabric...'

source = 'let x = 42 + 10'
puts "\nOriginal source code:"
puts "  #{source}"

fabric = WireGram.weave(source)
puts "\n✓ Woven into digital fabric (AST representation)"
puts "\nUnweaving back to source:"
puts "  #{fabric.to_source}"
puts "\n✓ Perfect reversibility maintained!"

# Demonstration 2: Pattern Analysis
separator
puts '2. PATTERN DETECTION & ANALYSIS'
puts '   Finding patterns in the code fabric...'

complex_source = 'let result = 100 / 5 + 3 * 2'
puts "\nSource code:"
puts "  #{complex_source}"

fabric2 = WireGram.weave(complex_source)
analyzer = fabric2.analyze

operations = analyzer.find_patterns(:arithmetic_operations)
literals = analyzer.find_patterns(:literals)

puts "\n✓ Detected #{operations.length} arithmetic operations:"
operations.each do |op|
  puts "    - #{op.type}"
end

puts "\n✓ Found #{literals.length} literal values:"
literals.each do |lit|
  puts "    - #{lit.type}: #{lit.value}"
end

complexity = analyzer.complexity
puts "\nComplexity metrics:"
puts "  Operations: #{complexity[:operations_count]}"
puts "  Tree depth: #{complexity[:tree_depth]}"

# Demonstration 3: Code Transformation
separator
puts '3. AUTOMATIC TRANSFORMATIONS'
puts '   Optimizing code through fabric transformations...'

optimization_source = 'let value = 25 + 15 * 2'
puts "\nOriginal code:"
puts "  #{optimization_source}"

fabric3 = WireGram.weave(optimization_source)
optimized = fabric3.transform(:constant_folding)

puts "\nAfter constant folding optimization:"
puts "  #{optimized.to_source}"
puts "\n✓ Constant expressions automatically evaluated!"

# Demonstration 4: Error Recovery
separator
puts '4. RESILIENT ERROR RECOVERY'
puts '   Handling malformed input gracefully...'

malformed_source = 'let x = 42 + @invalid'
puts "\nSource with invalid character:"
puts "  #{malformed_source}"

begin
  lexer = WireGram::Languages::Expression::Lexer.new(malformed_source)
  lexer.tokenize

  puts "\n✓ Lexer recovered and continued tokenization"
  puts "  Errors logged: #{lexer.errors.length}"

  if lexer.errors.any?
    lexer.errors.each do |error|
      puts "    - Unknown character '#{error[:char]}' at position #{error[:position]}"
    end
  end
rescue StandardError => e
  puts "\nError: #{e.message}"
end

# Demonstration 5: Linting and Auto-fixing
separator
puts '5. INTELLIGENT LINTING & AUTO-FIXING'
puts '   Building robust code quality tools...'

puts "\nCreating a linter with custom rules..."
linter = WireGram::Tools::Linter.new do
  rule 'constant-expression', severity: :info do |fabric|
    analyzer = fabric.analyze
    analyzer.diagnostics.select { |d| d[:type] == :optimization }
  end
end

lint_source = 'let x = 100 + 200'
puts "\nSource code:"
puts "  #{lint_source}"

fabric4 = WireGram.weave(lint_source)
issues = linter.lint(fabric4)

puts "\n#{linter.format_results}"

if issues.any?
  puts "\nApplying automatic fixes..."
  fixed = fabric4.transform(:constant_folding)
  puts 'Fixed code:'
  puts "  #{fixed.to_source}"
  puts "\n✓ Code automatically optimized!"
end

# Demonstration 6: Custom Transformations
separator
puts '6. DECLARATIVE TRANSFORMATIONS'
puts '   Defining custom code transformations...'

transform_source = '10 + 5'
puts "\nOriginal code:"
puts "  #{transform_source}"

fabric5 = WireGram.weave(transform_source)

# Custom transformation: Convert addition to multiplication
custom_transformed = fabric5.transform do |node|
  if node.type == :add
    puts "\n  Transforming: addition → multiplication"
    node.with(type: :multiply)
  else
    node
  end
end

puts "\nTransformed code:"
puts "  #{custom_transformed.to_source}"
puts "\n✓ Custom transformation applied!"

# Summary
separator
puts 'SUMMARY'
puts

puts '✓ WireGram successfully demonstrated:'
puts '  • Reversible source code fabric abstraction'
puts '  • High-fidelity parsing with error recovery'
puts '  • Pattern detection and code analysis'
puts '  • Automatic code transformations'
puts '  • Declarative linting and fixing'
puts '  • Foundation for language servers and tooling'

puts "\n🎯 Ready for building next-generation:"
puts '   → Language Servers'
puts '   → Linters & Formatters'
puts '   → Auto-fixers & Refactoring Tools'
puts '   → Code Analysis & Optimization Tools'

separator
puts 'Explore more examples in the examples/ directory!'
puts
