#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Automatic code fixing with WireGram
#
# This example demonstrates how to use the AutoFixer to automatically
# optimize and transform code.

require_relative '../lib/wiregram'
require_relative '../lib/wiregram/tools/fixer'
require_relative '../lib/wiregram/tools/linter'

puts '=== WireGram AutoFixer Example ==='
puts

# Example 1: Constant folding
source1 = 'let x = 10 + 20'
puts 'Original code:'
puts "  #{source1}"
puts

fabric1 = WireGram.weave(source1)
puts 'Before optimization:'
puts "  #{fabric1.to_source}"
puts

# Apply constant folding
optimized1 = fabric1.transform(:constant_folding)
puts 'After constant folding:'
puts "  #{optimized1.to_source}"
puts

# Example 2: More complex constant folding
source2 = 'let result = 5 * 4 + 10 / 2'
puts "\n#{"=" * 50}"
puts 'Original code:'
puts "  #{source2}"
puts

fabric2 = WireGram.weave(source2)
optimized2 = fabric2.transform(:constant_folding)
puts 'After constant folding:'
puts "  #{optimized2.to_source}"
puts

# Example 3: Using AutoFixer with custom rules
puts "\n#{"=" * 50}"
puts 'Using AutoFixer with custom transformations:'
puts

fixer = WireGram::Tools::AutoFixer.new do
  fix 'optimize' do |fabric|
    fabric.transform(:constant_folding)
  end

  fix 'custom-transform' do |fabric|
    # Custom transformation
    fabric.transform do |node|
      if node.type == :multiply && node.children.any? { |c| c.type == :number && c.value == 1 }
        # Remove multiplication by 1
        node.children.find { |c| c.type != :number || c.value != 1 }
      else
        node
      end
    end
  end
end

source3 = 'let value = 25 * 1 + 15'
puts 'Original:'
puts "  #{source3}"
puts

fabric3 = WireGram.weave(source3)
fixed3 = fixer.apply_fixes(fabric3)
puts 'After all fixes:'
puts "  #{fixed3.to_source}"
puts

# Example 4: Combining linter and fixer
puts "\n#{"=" * 50}"
puts 'Combining Linter and AutoFixer:'
puts

linter = WireGram::Tools::Linter.new do
  rule 'constant-expression' do |fabric|
    analyzer = fabric.analyze
    analyzer.diagnostics.select { |d| d[:type] == :optimization }
  end
end

source4 = 'let x = 100 + 200'
fabric4 = WireGram.weave(source4)

puts 'Original code:'
puts "  #{source4}"
puts

# Lint first
issues = linter.lint(fabric4)
puts "\nLinter results:"
puts linter.format_results
puts

# Then fix
if issues.any?
  puts 'Applying fixes...'
  fixed4 = fabric4.transform(:constant_folding)
  puts 'Fixed code:'
  puts "  #{fixed4.to_source}"
end
