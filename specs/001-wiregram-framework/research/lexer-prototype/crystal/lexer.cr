# Minimal Crystal lexer using regex (prototype)

struct Token
  property type : String
  property value : String
  def initialize(@type, @value); end
  def to_s
    "#{type}:#{value}"
  end
end

RULES = [
  ["COMMENT", /^#.*$/],
  ["WHITESPACE", /^\s+/],
  ["NUMBER", /^\d+/],
  ["IDENT", /^[A-Za-z_][A-Za-z0-9_]*/],
  ["SYMBOL", /^[(){}\[\];,+=*\-\/<>%]/],
]

def lex(text : String)
  i = 0
  tokens = [] of Token
  while i < text.size
    slice = text[i..-1]
    matched = false
    for (name, rx) in RULES
      if m = rx.match(slice)
        val = m[0]
        tokens << Token.new(name, val)
        i += val.size
        matched = true
        break
      end
    end
    unless matched
      tokens << Token.new("SYMBOL", slice[0].to_s)
      i += 1
    end
  end
  tokens
end

if ARGV.size > 0
  path = ARGV[0]
  text = File.read(path)
  tokens = lex(text)
  puts "Tokens: #{tokens.size}"
  tokens.each do |t|
    puts t.to_s
  end
end