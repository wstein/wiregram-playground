# frozen_string_literal: true

require 'spec_helper'

describe 'Variable expansion in UCL' do
  it 'expands $VAR and ${VAR} using provided vars and ENV' do
    input = <<~UCL
      keyvar = "$ABItest";
      keyvar = "${ABI}$ABI${ABI}${$ABI}";
      keyvar = "${some}$no${}$$test$$$$$$$";
      keyvar = "$ABI$$ABI$$$ABI$$$$";
    UCL

    # No ENV or vars set => should use 'unknown' fallback
    result = WireGram::Languages::Ucl.process(input, vars: {})
    out = result[:output]

    expect(out).to include('keyvar = "unknowntest";')
    expect(out).to include('keyvar = "unknownunknownunknown${unknown}";')
    expect(out).to include('keyvar = "${some}$no${}$$test$$$$$$$";')
    expect(out).to include('keyvar = "unknown$ABI$unknown$$";')
  end
end
