# frozen_string_literal: true

require 'spec_helper'
require 'wiregram/languages/ucl/lexer'

RSpec.describe WireGram::Languages::Ucl::Lexer do
  it 'skips nested block comments correctly' do
    src = '/* outer /* inner */ still */ foo'
    lexer = described_class.new(src)

    # First token should be identifier 'foo'
    tok = lexer.next_token
    # Skip possible unknown/whitespace until identifier
    tok = lexer.next_token while tok && tok[:type] != :identifier && tok[:type] != :eof

    expect(tok[:type]).to eq(:identifier)
    expect(tok[:value]).to eq('foo')
  end

  it 'captures URLs as a single unquoted string' do
    src = 'http://example.com/path foo'
    lexer = described_class.new(src)

    tok = lexer.next_token
    expect(tok[:type]).to eq(:string)
    expect(tok[:value]).to start_with('http://example.com')
  end

  it 'handles interpolation within unquoted strings' do
    src = 'foo${bar}baz'
    lexer = described_class.new(src)

    tok = lexer.next_token
    expect(tok[:type]).to eq(:string)
    expect(tok[:value]).to eq('foo${bar}baz')
  end

  it 'handles nested interpolation within unquoted strings' do
    src = 'a${b${c}d}e'
    lexer = described_class.new(src)

    tok = lexer.next_token
    expect(tok[:type]).to eq(:string)
    expect(tok[:value]).to eq('a${b${c}d}e')
  end

  it 'parses identifiers with leading dash as identifiers (flags)' do
    src = '-flag other'
    lexer = described_class.new(src)

    tok = lexer.next_token
    expect(tok[:type]).to eq(:identifier)
    expect(tok[:value]).to eq('-flag')
  end
end
