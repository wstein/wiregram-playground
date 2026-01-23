#!/usr/bin/env ruby
# Minimal regex-based lexer prototype preserving trivia

class Token
  attr_reader :type, :value, :leading_trivia, :trailing_trivia
  def initialize(type, value, leading_trivia = nil, trailing_trivia = nil)
    @type = type
    @value = value
    @leading_trivia = leading_trivia
    @trailing_trivia = trailing_trivia
  end
  def to_s
    "#{type}:#{value.inspect} [lead=#{leading_trivia.inspect} trail=#{trailing_trivia.inspect}]"
  end
end

RULES = [
  [:COMMENT, /^#.*$/],
  [:WHITESPACE, /^\s+/],
  [:NUMBER, /^\d+/],
  [:IDENT, /^[A-Za-z_][A-Za-z0-9_]*/],
  [:SYMBOL, /^[(){}\[\];,+=*\-\/<>%]/],
]

def lex(text)
  i = 0
  tokens = []
  while i < text.length
    slice = text[i..-1]
    matched = false
    RULES.each do |name, rx|
      if m = rx.match(slice)
        val = m[0]
        tokens << Token.new(name, val)
        i += val.length
        matched = true
        break
      end
    end
    unless matched
      # Unknown single char, emit as SYMBOL and continue
      tokens << Token.new(:SYMBOL, slice[0])
      i += 1
    end
  end
  tokens
end

if __FILE__ == $0
  path = ARGV[0] || 'specs/001-wiregram-framework/research/corpus/sample.rb'
  text = File.read(path)
  tokens = lex(text)
  puts "Tokens: #{tokens.size}"
  tokens.each { |t| puts t }
end