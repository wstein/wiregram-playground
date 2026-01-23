# frozen_string_literal: true

require_relative '../lexer.rb'

RSpec.describe 'Lexer prototype' do
  it 'tokenizes sample file and preserves comments' do
    path = File.expand_path('../../../corpus/sample.rb', __dir__)
    text = File.read(path)
    tokens = lex(text)

    # Must find at least one comment token and one identifier
    has_comment = tokens.any? { |t| t.type == :COMMENT }
    has_ident = tokens.any? { |t| t.type == :IDENT }

    expect(has_comment).to be true
    expect(has_ident).to be true
  end
end
