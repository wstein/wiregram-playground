require_relative '../parser.rb'
require 'rspec'

RSpec.describe 'Parser prototype' do
  it 'parses simple arithmetic expression' do
    path = File.expand_path('../../../corpus/sample.minilang', __dir__)
    text = File.read(path)
    tokens = lex(text)
    parser = Parser.new(tokens)
    ast = parser.parse_expr
    expect(ast.to_s).to include('+').or include('-').or include('*').or include('/')
  end
end
