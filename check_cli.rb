#!/usr/bin/env ruby
# frozen_string_literal: true

# Manual CLI verification checklist

puts 'WireGram CLI Verification Checklist'
puts '=' * 50
puts

# Load the library
$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'wiregram/cli'

tests = {
  'Language Discovery' => [
    ['Can list languages', -> { WireGram::CLI::Languages.available }],
    ['JSON module resolves', -> { WireGram::CLI::Languages.module_for('json') }],
    ['UCL module resolves', -> { WireGram::CLI::Languages.module_for('ucl') }],
    ['Expression module resolves', -> { WireGram::CLI::Languages.module_for('expression') }]
  ],
  'JSON Language' => [
    ['Has process', -> { WireGram::Languages::Json.respond_to?(:process) }],
    ['Has tokenize', -> { WireGram::Languages::Json.respond_to?(:tokenize) }],
    ['Has parse', -> { WireGram::Languages::Json.respond_to?(:parse) }],
    ['Has process_pretty', -> { WireGram::Languages::Json.respond_to?(:process_pretty) }]
  ],
  'UCL Language' => [
    ['Has process', -> { WireGram::Languages::Ucl.respond_to?(:process) }],
    ['Has tokenize', -> { WireGram::Languages::Ucl.respond_to?(:tokenize) }],
    ['Has parse', -> { WireGram::Languages::Ucl.respond_to?(:parse) }]
  ],
  'Expression Language' => [
    ['Has process', -> { WireGram::Languages::Expression.respond_to?(:process) }],
    ['Has tokenize', -> { WireGram::Languages::Expression.respond_to?(:tokenize) }],
    ['Has parse', -> { WireGram::Languages::Expression.respond_to?(:parse) }],
    ['Has process_pretty', -> { WireGram::Languages::Expression.respond_to?(:process_pretty) }]
  ]
}

passed = 0
failed = 0

tests.each do |category, checks|
  puts "\n#{category}:"
  checks.each do |name, test|
    result = test.call
    if result
      puts "  ✓ #{name}"
      passed += 1
    else
      puts "  ✗ #{name} (returned false)"
      failed += 1
    end
  rescue StandardError => e
    puts "  ✗ #{name} (#{e.message})"
    failed += 1
  end
end

puts "\n#{"=" * 50}"
puts "Results: #{passed} passed, #{failed} failed"
puts

if failed.zero?
  puts '✅ All checks passed! CLI is ready for use.'
  exit 0
else
  puts '❌ Some checks failed. See details above.'
  exit 1
end
