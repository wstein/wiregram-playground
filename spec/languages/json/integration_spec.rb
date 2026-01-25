# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/json_test_helper'
require_relative '../../../lib/wiregram/languages/json'

describe 'JSON Language Integration' do
  describe 'complete pipeline' do
    it 'processes simple JSON' do
      input = '{"name": "John", "age": 30}'
      result = WireGram::Languages::Json.process(input)

      expect(result[:input]).to eq(input)
      expect(result[:tokens]).to be_a(Array)
      expect(result[:ast]).to be_a(WireGram::Core::Node)
      expect(result[:uom]).to be_a(WireGram::Languages::Json::UOM)
      expect(result[:output]).to eq('{"name": "John", "age": 30}')
      expect(result[:errors]).to be_empty
    end

    it 'processes nested JSON' do
      input = '{"user": {"name": "John", "address": {"city": "NYC"}}, "active": true}'
      result = WireGram::Languages::Json.process(input)

      expect(result[:input]).to eq(input)
      expect(result[:tokens]).to be_a(Array)
      expect(result[:ast]).to be_a(WireGram::Core::Node)
      expect(result[:uom]).to be_a(WireGram::Languages::Json::UOM)
      expect(result[:output]).to eq('{"user": {"name": "John", "address": {"city": "NYC"}}, "active": true}')
      expect(result[:errors]).to be_empty
    end

    it 'processes arrays' do
      input = '[1, "hello", true, null]'
      result = WireGram::Languages::Json.process(input)

      expect(result[:input]).to eq(input)
      expect(result[:tokens]).to be_a(Array)
      expect(result[:ast]).to be_a(WireGram::Core::Node)
      expect(result[:uom]).to be_a(WireGram::Languages::Json::UOM)
      expect(result[:output]).to eq('[1, "hello", true, null]')
      expect(result[:errors]).to be_empty
    end

    it 'processes complex nested structures' do
      input = '{"users": [{"name": "John", "age": 30}, {"name": "Jane", "age": 25}], "count": 2}'
      result = WireGram::Languages::Json.process(input)

      expect(result[:input]).to eq(input)
      expect(result[:tokens]).to be_a(Array)
      expect(result[:ast]).to be_a(WireGram::Core::Node)
      expect(result[:uom]).to be_a(WireGram::Languages::Json::UOM)
      expect(result[:output]).to eq('{"users": [{"name": "John", "age": 30}, {"name": "Jane", "age": 25}], "count": 2}')
      expect(result[:errors]).to be_empty
    end

    it 'handles pretty formatting' do
      input = '{"name":"John","age":30}'
      result = WireGram::Languages::Json.process_pretty(input)

      expect(result[:input]).to eq(input)
      expect(result[:output]).to include('"name": "John"')
      expect(result[:output]).to include('"age": 30')
      expect(result[:output]).to include("\n")
      expect(result[:errors]).to be_empty
    end

    it 'handles simple Ruby structure conversion' do
      input = '{"name": "John", "age": 30}'
      result = WireGram::Languages::Json.process_simple(input)

      expect(result[:input]).to eq(input)
      expect(result[:output]).to eq({ 'name' => 'John', 'age' => 30 })
      expect(result[:errors]).to be_empty
    end

    it 'handles malformed JSON' do
      input = '{"name": "John", "age":}'
      result = WireGram::Languages::Json.process(input)

      expect(result[:input]).to eq(input)
      expect(result[:errors]).not_to be_empty
      # With error recovery, we may still get partial output
      expect(result[:output]).to be_a(String)
    end
  end

  describe 'UOM to_simple_json' do
    it 'converts UOM to Ruby structures' do
      input = '{"name": "John", "age": 30, "active": true, "tags": ["developer", "ruby"]}'
      result = WireGram::Languages::Json.process(input)

      expect(result[:uom]).to be_a(WireGram::Languages::Json::UOM)
      simple_json = result[:uom].to_simple_json

      expected = {
        'name' => 'John',
        'age' => 30,
        'active' => true,
        'tags' => ['developer', 'ruby']
      }
      expect(simple_json).to eq(expected)
    end
  end
end
