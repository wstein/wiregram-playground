# frozen_string_literal: true

require 'spec_helper'

describe WireGram::Languages::Ucl::Transformer do
  it 'transforms nested sections into UOM and renders correctly' do
    input = <<~UCL
      section1 { param1 = value; param2 = value, section3 { param = value; param2 = value, param3 = ["value1", value2, 100500] }}
    UCL

    result = WireGram::Languages::Ucl.process(input)

    expect(result[:output]).to include('section1 {')
    expect(result[:output]).to include('param1 = "value";')
    expect(result[:output]).to include('section3 {')
    expect(result[:output]).to include('param3 [')
    expect(result[:errors]).to be_empty
  end
end
