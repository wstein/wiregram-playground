# frozen_string_literal: true

require 'spec_helper'
require_relative 'support/snapshot_helper'
require_relative '../lib/wiregram/languages/ucl'

describe 'UCL Language Snapshots' do
  include SnapshotHelper

  describe 'tokenization snapshots' do
    it 'snapshots tokens for simple assignment' do
      input = 'key = "value";'
      lexer = WireGram::Languages::Ucl::Lexer.new(input)
      tokens = lexer.tokenize

      # Convert tokens to a readable format for snapshotting
      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      assert_snapshot('simple_ucl_tokens', token_strings.join("\n"), 'ucl')
    end

    it 'snapshots tokens for complex assignment' do
      input = 'key = 0xdeadbeef;'
      lexer = WireGram::Languages::Ucl::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      assert_snapshot('complex_ucl_tokens', token_strings.join("\n"), 'ucl')
    end

    it 'snapshots tokens for object' do
      input = '{ key = "value"; }'
      lexer = WireGram::Languages::Ucl::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      assert_snapshot('object_ucl_tokens', token_strings.join("\n"), 'ucl')
    end
  end

  describe 'AST snapshots' do
    it 'snapshots AST for simple assignment' do
      input = 'key = "value";'
      result = WireGram::Languages::Ucl.process(input)

      # Convert AST to JSON format
      ast_string = result[:ast].to_json

      assert_snapshot('simple_ucl_ast', ast_string, 'ucl')
    end

    it 'snapshots AST for object' do
      input = '{ key = "value"; }'
      result = WireGram::Languages::Ucl.process(input)

      ast_string = result[:ast].to_json

      assert_snapshot('object_ucl_ast', ast_string, 'ucl')
    end
  end

  describe 'UOM snapshots' do
    it 'snapshots UOM for simple assignment' do
      input = 'key = "value";'
      result = WireGram::Languages::Ucl.process(input)

      # Convert UOM to pretty JSON format
      uom_pretty = result[:uom].root.to_pretty_json

      assert_snapshot('simple_ucl_uom', uom_pretty, 'ucl')
    end

    it 'snapshots UOM for complex object' do
      input = '{ key1 = "value1"; key2 = 42; }'
      result = WireGram::Languages::Ucl.process(input)

      # Convert UOM to pretty JSON format
      uom_pretty = result[:uom].root.to_pretty_json

      assert_snapshot('complex_ucl_uom', uom_pretty, 'ucl')
    end
  end

  describe 'output snapshots' do
    it 'snapshots normalized output for simple assignment' do
      input = 'key = "value";'
      result = WireGram::Languages::Ucl.process(input)

      assert_snapshot('simple_ucl_output', result[:output], 'ucl')
    end

    it 'snapshots normalized output for complex object' do
      input = '{ key1 = "value1"; key2 = 42; }'
      result = WireGram::Languages::Ucl.process(input)

      assert_snapshot('complex_ucl_output', result[:output], 'ucl')
    end
  end

  describe 'libucl test case snapshots' do
    it 'snapshots complete pipeline for libucl test case 1' do
      input = <<~UCL
        {
        "key1": value;
        "key1": value2;
        "key1": "value;"
        "key1": 1.0,
        "key1": -0xdeadbeef
        "key1": 0xdeadbeef.1
        "key1": 0xreadbeef
        "key1": -1e-10,
        "key1": 1
        "key1": true
        "key1": no
        "key1": yes
        }
      UCL

      # Process through complete pipeline
      result = WireGram::Languages::Ucl.process(input)
      tokens_block = result[:tokens].map do |t|
        "{type: #{t[:type]}, value: #{t[:value].inspect}, position: #{t[:position]}}"
      end.join("\n")

      # Create a comprehensive snapshot with all outputs
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

      assert_snapshot('libucl_test_case_1_complete', snapshot_content, 'ucl')
    end
  end
end
