# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UCL UOM from JSON' do
  it 'converts JSON fixtures into UOM and uom_json' do
    input = File.read(File.expand_path('../../../vendor/libucl/tests/schema/maxProperties.json', __dir__))

    result = WireGram::Languages::Ucl.process(input)

    expect(result).to be_a(Hash)
    expect(result[:uom_json]).to be_a(Hash)
    expect(result[:uom_json]['schema']).to eq({ 'maxProperties' => 2 })
    expect(result[:uom_json]['tests']).to be_an(Array)
    expect(result[:errors]).to eq([])
  end
end
