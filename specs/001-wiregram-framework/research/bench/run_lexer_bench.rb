#!/usr/bin/env ruby
# Simple micro-benchmark for Ruby lexer prototype
require 'benchmark'
require_relative '../lexer-prototype/ruby/lexer.rb'

path = ARGV[0] || 'specs/001-wiregram-framework/research/corpus/sample.rb'
text = File.read(path)

n = 1000
Benchmark.bm do |bm|
  bm.report('lex') { n.times { lex(text) } }
end
