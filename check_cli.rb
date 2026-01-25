#!/usr/bin/env ruby
# Manual CLI verification checklist

puts "WireGram CLI Verification Checklist"
puts "=" * 50
puts

# Load the library
$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'wiregram/cli'

tests = {
  "Language Discovery" => [
    ["Can list languages", lambda { WireGram::CLI::Languages.available }],
    ["JSON module resolves", lambda { WireGram::CLI::Languages.module_for('json') }],
    ["UCL module resolves", lambda { WireGram::CLI::Languages.module_for('ucl') }],
    ["Expression module resolves", lambda { WireGram::CLI::Languages.module_for('expression') }],
  ],
  "JSON Language" => [
    ["Has process", lambda { WireGram::Languages::Json.respond_to?(:process) }],
    ["Has tokenize", lambda { WireGram::Languages::Json.respond_to?(:tokenize) }],
    ["Has parse", lambda { WireGram::Languages::Json.respond_to?(:parse) }],
    ["Has process_pretty", lambda { WireGram::Languages::Json.respond_to?(:process_pretty) }],
  ],
  "UCL Language" => [
    ["Has process", lambda { WireGram::Languages::Ucl.respond_to?(:process) }],
    ["Has tokenize", lambda { WireGram::Languages::Ucl.respond_to?(:tokenize) }],
    ["Has parse", lambda { WireGram::Languages::Ucl.respond_to?(:parse) }],
  ],
  "Expression Language" => [
    ["Has process", lambda { WireGram::Languages::Expression.respond_to?(:process) }],
    ["Has tokenize", lambda { WireGram::Languages::Expression.respond_to?(:tokenize) }],
    ["Has parse", lambda { WireGram::Languages::Expression.respond_to?(:parse) }],
    ["Has process_pretty", lambda { WireGram::Languages::Expression.respond_to?(:process_pretty) }],
  ]
}

passed = 0
failed = 0

tests.each do |category, checks|
  puts "\n#{category}:"
  checks.each do |name, test|
    begin
      result = test.call
      if result
        puts "  ✓ #{name}"
        passed += 1
      else
        puts "  ✗ #{name} (returned false)"
        failed += 1
      end
    rescue => e
      puts "  ✗ #{name} (#{e.message})"
      failed += 1
    end
  end
end

puts "\n" + "=" * 50
puts "Results: #{passed} passed, #{failed} failed"
puts

if failed == 0
  puts "✅ All checks passed! CLI is ready for use."
  exit 0
else
  puts "❌ Some checks failed. See details above."
  exit 1
end
