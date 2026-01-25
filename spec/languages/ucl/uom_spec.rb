# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe WireGram::Languages::Ucl::UOM do
  it 'produces JSON-friendly uom for maxProperties fixture' do
    input = File.read(File.expand_path('../../../vendor/libucl/tests/schema/maxProperties.json', __dir__))
    result = WireGram::Languages::Ucl.process(input)

    expect(result).to have_key(:uom)
    # The process returns raw uom object; the JSON-friendly representation is in :uom_json
    expect(result).to have_key(:uom_json)

    uom_json = result[:uom_json]
    expect(uom_json).to be_a(Hash)
    expect(uom_json['schema']).to be_a(Hash)
    expect(uom_json['schema']['maxProperties']).to eq(2)

    expect(uom_json['tests']).to be_a(Array)
    expect(uom_json['tests'].length).to eq(4)

    first = uom_json['tests'][0]
    expect(first['description']).to eq('shorter is valid')
    expect(first['data']).to be_a(Hash)
    expect(first['data']['foo']).to eq(1)

    last = uom_json['tests'][3]
    expect(last['data']).to eq('foobar')
  end
end
