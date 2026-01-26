# frozen_string_literal: true

# Comprehensive CLI test - verifies all languages support all actions

require 'spec_helper'
require 'wiregram/cli'

RSpec.describe 'WireGram CLI' do
  let(:json_input) { '{"name": "test", "value": 42}' }
  let(:expression_input) { 'let x = 10 + 20' }
  let(:ucl_input) { 'server { port = 8080; }' }

  describe 'Languages discovery' do
    it 'lists all available languages' do
      langs = WireGram::CLI::Languages.available
      expect(langs).to include('json', 'expression', 'ucl')
    end

    it 'resolves language modules' do
      mod = WireGram::CLI::Languages.module_for('json')
      expect(mod).to eq(WireGram::Languages::Json)
    end
  end

  describe 'JSON language' do
    it 'supports process' do
      mod = WireGram::CLI::Languages.module_for('json')
      result = mod.process(json_input)
      expect(result).to have_key(:tokens)
      expect(result).to have_key(:ast)
      expect(result).to have_key(:output)
    end

    it 'supports tokenize' do
      mod = WireGram::CLI::Languages.module_for('json')
      tokens = mod.tokenize(json_input)
      expect(tokens).to be_a(Array)
      expect(tokens.length).to be > 0
    end

    it 'supports parse' do
      mod = WireGram::CLI::Languages.module_for('json')
      ast = mod.parse(json_input)
      expect(ast).to be_a(WireGram::Core::Node)
    end
  end

  describe 'Expression language' do
    it 'supports process' do
      mod = WireGram::CLI::Languages.module_for('expression')
      result = mod.process(expression_input)
      expect(result).to have_key(:tokens)
      expect(result).to have_key(:ast)
      expect(result).to have_key(:output)
    end

    it 'supports tokenize' do
      mod = WireGram::CLI::Languages.module_for('expression')
      result = mod.tokenize(expression_input)
      expect(result).to be_a(Array)
    end

    it 'supports parse' do
      mod = WireGram::CLI::Languages.module_for('expression')
      result = mod.parse(expression_input)
      expect(result).to be_a(WireGram::Core::Node)
    end
  end

  describe 'UCL language' do
    it 'supports process' do
      mod = WireGram::CLI::Languages.module_for('ucl')
      result = mod.process(ucl_input)
      expect(result).to have_key(:tokens)
      expect(result).to have_key(:ast)
      expect(result).to have_key(:output)
    end

    it 'supports tokenize' do
      mod = WireGram::CLI::Languages.module_for('ucl')
      tokens = mod.tokenize(ucl_input)
      expect(tokens).to be_a(Array)
    end

    it 'supports parse' do
      mod = WireGram::CLI::Languages.module_for('ucl')
      ast = mod.parse(ucl_input)
      expect(ast).to be_a(WireGram::Core::Node)
    end
  end

  describe 'Runner dispatch' do
    it 'lists languages without error' do
      expect { WireGram::CLI::Runner.start(['list']) }.not_to raise_error
    end

    it 'shows help for a language' do
      expect { WireGram::CLI::Runner.start(%w[json help]) }.not_to raise_error
    end

    it 'rejects unknown language' do
      expect { WireGram::CLI::Runner.start(%w[foobar help]) }.to raise_error(SystemExit)
    end
  end
end
