# frozen_string_literal: true

require 'benchmark'
require_relative '../lib/wiregram/languages/json/lexer'
require_relative '../lib/wiregram/languages/ucl/lexer'

# Generate a large JSON payload (~10MB by default) or use a file if provided
input_arg = ARGV[0] || '10'

if File.file?(input_arg)
  src = File.read(input_arg)
  puts "Read input file #{input_arg} (#{(src.bytesize / 1024.0 / 1024.0).round(2)} MB)"
else
  size_mb = input_arg.to_i
  item = '{"key":"value","n":123,"s":"a short string"},'
  items = []
  items_capacity = (size_mb * 1024 * 1024) / item.bytesize
  items_capacity = 10 if items_capacity < 10
  items_capacity.times do
    items << item
  end
  src = "[#{items.join}{}]"
  puts "Generated JSON payload ~#{(src.bytesize / 1024.0 / 1024.0).round(2)} MB (#{items_capacity} items)"
end

# Helper to tokenize using next_token to measure per-token overhead
def time_lex(klass, src)
  lexer = klass.new(src)
  Benchmark.realtime do
    loop do
      tok = lexer.next_token
      break if tok && tok[:type] == :eof
    end
  end
end

json_time = time_lex(WireGram::Languages::Json::Lexer, src)
ucl_time = time_lex(WireGram::Languages::Ucl::Lexer, src)

puts "JsonLexer: #{json_time.round(4)}s"
puts "UclLexer:  #{ucl_time.round(4)}s"
puts "Ucl / Json ratio: #{(ucl_time / json_time).round(2)}"
