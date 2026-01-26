# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UCL parser top-level array handling' do
  it 'parses a top-level array from a JSON fixture into an :array node' do
    fixture = File.read(File.expand_path('../../../vendor/libucl/tests/schema/maxProperties.json', __dir__))

    ast = WireGram::Languages::Ucl.parse(fixture)

    expect(ast).to be_a(WireGram::Core::Node)
    expect(ast.type).to eq(:array)
    expect(ast.children).to be_an(Array)
    expect(ast.children.first).to be_a(WireGram::Core::Node)
  end

  it 'process handles JSON array fixtures and returns uom_json with expected keys' do
    fixture = File.read(File.expand_path('../../../vendor/libucl/tests/schema/maxProperties.json', __dir__))

    result = WireGram::Languages::Ucl.process(fixture)

    expect(result[:uom_json]).to be_a(Hash).or be_an(Array)
    # If we get an array, the first element should include schema and tests keys
    if result[:uom_json].is_a?(Array)
      expect(result[:uom_json].first['schema']).to be_a(Hash)
      expect(result[:uom_json].first['tests']).to be_an(Array)
    else
      expect(result[:uom_json]['schema']).to be_a(Hash)
      expect(result[:uom_json]['tests']).to be_an(Array)
    end
  end
end
