# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/snapshot_helper'
require_relative '../../../lib/wiregram/languages/json'

describe 'JSON Language Snapshots' do
  include SnapshotHelper

  describe 'tokenization snapshots' do
    it 'snapshots tokens for simple JSON' do
      input = '{"name": "John", "age": 30}'
      lexer = WireGram::Languages::Json::Lexer.new(input)
      tokens = lexer.tokenize

      # Convert tokens to a readable format for snapshotting
      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      assert_snapshot('simple_json_tokens', token_strings.join("\n"), 'json')
    end

    it 'snapshots tokens for nested JSON' do
      input = '{"user": {"name": "John", "address": {"city": "NYC"}}, "active": true}'
      lexer = WireGram::Languages::Json::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      assert_snapshot('nested_json_tokens', token_strings.join("\n"))
    end

    it 'snapshots tokens for arrays' do
      input = '[1, "hello", true, null]'
      lexer = WireGram::Languages::Json::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      assert_snapshot('arrays_json_tokens', token_strings.join("\n"))
    end
  end

  describe 'AST snapshots' do
    it 'snapshots AST for simple JSON' do
      input = '{"name": "John", "age": 30}'
      result = WireGram::Languages::Json.process(input)

      # Convert AST to JSON format
      ast_string = result[:ast].to_json

      assert_snapshot('simple_json_ast', ast_string, 'json')
    end

    it 'snapshots AST for nested JSON' do
      input = '{"user": {"name": "John", "address": {"city": "NYC"}}, "active": true}'
      result = WireGram::Languages::Json.process(input)

      ast_string = result[:ast].to_json

      assert_snapshot('nested_json_ast', ast_string)
    end
  end

  describe 'UOM snapshots' do
    it 'snapshots UOM for simple JSON' do
      input = '{"name": "John", "age": 30}'
      result = WireGram::Languages::Json.process(input)

      # Convert UOM to JSON format
      uom_pretty = result[:uom].root.to_pretty_json

      # Store input separately
      assert_snapshot('simple_json_input', input, 'json')

      # Store UOM-only snapshot
      assert_snapshot('simple_json_uom', uom_pretty, 'json')
    end

    it 'snapshots UOM for complex JSON' do
      input = '{"users": [{"name": "John", "age": 30}, {"name": "Jane", "age": 25}], "count": 2}'
      result = WireGram::Languages::Json.process(input)

      # Convert UOM to JSON format
      uom_pretty = result[:uom].root.to_pretty_json

      # Store input separately
      assert_snapshot('complex_json_input', input, 'json')

      # Store UOM-only snapshot
      assert_snapshot('complex_json_uom', uom_pretty, 'json')
    end
  end

  describe 'output snapshots' do
    it 'snapshots normalized output for simple JSON' do
      input = '{"name": "John", "age": 30}'
      result = WireGram::Languages::Json.process(input)

      assert_snapshot('simple_json_output', result[:output], 'json')
    end

    it 'snapshots pretty output for simple JSON' do
      input = '{"name":"John","age":30}'
      result = WireGram::Languages::Json.process_pretty(input)

      assert_snapshot('simple_json_pretty', result[:output], 'json')
    end

    it 'snapshots simple Ruby structure for simple JSON' do
      input = '{"name": "John", "age": 30}'
      result = WireGram::Languages::Json.process_simple(input)

      # Convert Ruby structure to string for snapshotting
      ruby_string = result[:output].inspect

      assert_snapshot('simple_json_ruby', ruby_string)
    end
  end

  describe 'fixture-based snapshots' do
    # Test with the existing fixture files
    Dir.glob(File.expand_path('../../languages/json/fixtures/valid/*.json', __dir__)).each do |fixture_file|
      fixture_name = File.basename(fixture_file, '.json')

      it "snapshots complete pipeline for #{fixture_name} fixture" do
        input = File.read(fixture_file)

        # Process through complete pipeline
        result = WireGram::Languages::Json.process(input)

        # Create a comprehensive snapshot with all outputs (no top-level indent)
        tokens_block = result[:tokens].map { |t| "{type: #{t[:type]}, value: #{t[:value].inspect}, position: #{t[:position]}}" }.join("\n")
        snapshot_content = <<~SNAPSHOT
          === INPUT ===
          #{input}

          === TOKENS ===
          #{tokens_block}

          === AST ===
          #{result[:ast].to_json}

          === UOM ===
          #{result[:uom].root.to_pretty_json}

          === OUTPUT ===
          #{result[:output]}

          === ERRORS ===
          #{result[:errors].inspect}
        SNAPSHOT

        assert_snapshot("#{fixture_name}_complete", snapshot_content, 'json')
      end
    end
  end
end
