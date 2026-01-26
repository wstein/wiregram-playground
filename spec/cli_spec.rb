# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'wiregram/cli'

RSpec.describe WireGram::CLI::Runner do
  it 'lists languages without error' do
    expect { WireGram::CLI::Runner.start(['list']) }.not_to raise_error
  end

  it 'shows help for a language' do
    expect { WireGram::CLI::Runner.start(%w[json help]) }.not_to raise_error
  end

  it 'inspects json from a file' do
    input = '{"a":1}'
    require 'tempfile'
    tmp = Tempfile.new('json_input')
    begin
      tmp.write(input)
      tmp.flush
      expect { WireGram::CLI::Runner.start(['json', 'inspect', tmp.path]) }.not_to raise_error
    ensure
      tmp.close
      tmp.unlink
    end
  end

  it 'inspects json with no input (non-blocking)' do
    # When no stdin is provided, Runner should treat as empty input and return quickly
    expect { WireGram::CLI::Runner.start(%w[json inspect]) }.not_to raise_error
  end
end
