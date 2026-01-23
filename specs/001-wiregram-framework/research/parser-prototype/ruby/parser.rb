#!/usr/bin/env ruby
# Minimal RD parser for arithmetic expressions: supports + and parenthesis

require_relative '../../lexer-prototype/ruby/lexer.rb'

# AST nodes
class Num; attr_reader :value; def initialize(v); @value = v; end; def to_s; "Num(#{value})"; end; end
class Bin; attr_reader :op, :left, :right; def initialize(op, l, r); @op=op; @left=l; @right=r; end; def to_s; "(#{left} #{op} #{right})"; end; end

class Parser
  def initialize(tokens)
    # Filter out non-semantic tokens (comments, whitespace). Trivia should be attached to neighboring tokens in a full implementation.
    @tokens = tokens.reject { |t| t.type == :WHITESPACE || t.type == :COMMENT }
    @i = 0
  end

  def peek
    @tokens[@i]
  end

  def eat(type = nil)
    t = peek
    if type && t && t.type != type
      raise "Unexpected token #{t.type}, expected #{type}"
    end
    @i += 1
    t
  end

  def parse_primary
    t = peek
    if t.type == :NUMBER
      eat(:NUMBER)
      Num.new(t.value.to_i)
    elsif t.type == :SYMBOL && t.value == '('
      eat(:SYMBOL)
      e = parse_expr
      eat(:SYMBOL)
      e
    else
      raise "Unexpected primary: #{t}"
    end
  end

  def parse_term
    left = parse_primary
    while peek && peek.type == :SYMBOL && ['*','/'].include?(peek.value)
      op = eat(:SYMBOL).value
      right = parse_primary
      left = Bin.new(op, left, right)
    end
    left
  end

  def parse_expr
    left = parse_term
    while peek && peek.type == :SYMBOL && ['+','-'].include?(peek.value)
      op = eat(:SYMBOL).value
      right = parse_term
      left = Bin.new(op, left, right)
    end
    left
  end
end

if __FILE__ == $0
  path = ARGV[0] || 'specs/001-wiregram-framework/research/corpus/sample.minilang'
  text = File.read(path)
  tokens = lex(text)
  parser = Parser.new(tokens)
  ast = parser.parse_expr
  puts "AST: #{ast}"
end
