#!/usr/bin/env ruby
# Quick test of CLI without going through bin/wiregram

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'wiregram/cli'

# Test 1: list
puts "Test 1: list"
WireGram::CLI::Runner.start(['list'])

puts "\n" + "="*50 + "\n"

# Test 2: json inspect  
puts "Test 2: json inspect"
puts ""
WireGram::CLI::Runner.start(['json', 'inspect'])
