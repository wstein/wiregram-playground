# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/snapshot_helper'
require_relative '../../../lib/wiregram/languages/expression'

describe 'Expression Language Snapshots' do
  include SnapshotHelper

  describe 'tokenization snapshots' do
    it 'snapshots tokens for simple number' do
      input = '42'
      lexer = WireGram::Languages::Expression::Lexer.new(input)
      tokens = lexer.tokenize

      # Convert tokens to a readable format for snapshotting
      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      assert_snapshot('simple_expression_tokens', token_strings.join("\n"), 'expression')
    end

    it 'snapshots tokens for arithmetic expression' do
      input = '1 + 2'
      lexer = WireGram::Languages::Expression::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      assert_snapshot('arithmetic_expression_tokens', token_strings.join("\n"), 'expression')
    end

    it 'snapshots tokens for assignment' do
      input = 'let x = 42'
      lexer = WireGram::Languages::Expression::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      assert_snapshot('assignment_expression_tokens', token_strings.join("\n"), 'expression')
    end

    it 'snapshots tokens for complex expression' do
      input = 'let result = (x + y) * 2'
      lexer = WireGram::Languages::Expression::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      assert_snapshot('complex_expression_tokens', token_strings.join("\n"), 'expression')
    end
  end

  describe 'AST snapshots' do
    it 'snapshots AST for simple number' do
      input = '42'
      result = WireGram::Languages::Expression.process(input)

      # Convert AST to JSON format
      ast_string = result[:ast].to_json

      assert_snapshot('simple_expression_ast', ast_string, 'expression')
    end

    it 'snapshots AST for arithmetic expression' do
      input = '1 + 2'
      result = WireGram::Languages::Expression.process(input)

      ast_string = result[:ast].to_json

      assert_snapshot('arithmetic_expression_ast', ast_string, 'expression')
    end

    it 'snapshots AST for assignment' do
      input = 'let x = 42'
      result = WireGram::Languages::Expression.process(input)

      ast_string = result[:ast].to_json

      assert_snapshot('assignment_expression_ast', ast_string, 'expression')
    end

    it 'snapshots AST for complex expression' do
      input = 'let result = (x + y) * 2'
      result = WireGram::Languages::Expression.process(input)

      ast_string = result[:ast].to_json

      assert_snapshot('complex_expression_ast', ast_string, 'expression')
    end
  end

  describe 'UOM snapshots' do
    it 'snapshots UOM for simple number' do
      input = '42'
      result = WireGram::Languages::Expression.process(input)

      # Convert UOM to pretty JSON for snapshot
      uom_pretty = result[:uom].root.to_json

      # Store input separately
      assert_snapshot('simple_expression_input', input, 'expression')

      # Store UOM-only snapshot
      assert_snapshot('simple_expression_uom', uom_pretty, 'expression')
    end

    it 'snapshots UOM for arithmetic expression' do
      input = '1 + 2'
      result = WireGram::Languages::Expression.process(input)

      uom_pretty = result[:uom].root.to_json

      # Store input separately
      assert_snapshot('arithmetic_expression_input', input, 'expression')

      # Store UOM-only snapshot
      assert_snapshot('arithmetic_expression_uom', uom_pretty, 'expression')
    end

    it 'snapshots UOM for assignment' do
      input = 'let x = 42'
      result = WireGram::Languages::Expression.process(input)

      uom_pretty = result[:uom].root.to_json

      # Store input separately
      assert_snapshot('assignment_expression_input', input, 'expression')

      # Store UOM-only snapshot
      assert_snapshot('assignment_expression_uom', uom_pretty, 'expression')
    end

    it 'snapshots UOM for complex expression' do
      input = 'let result = (x + y) * 2'
      result = WireGram::Languages::Expression.process(input)

      uom_pretty = result[:uom].root.to_json

      # Store input separately
      assert_snapshot('complex_expression_input', input, 'expression')

      # Store UOM-only snapshot
      assert_snapshot('complex_expression_uom', uom_pretty, 'expression')
    end
  end

  describe 'output snapshots' do
    it 'snapshots normalized output for simple number' do
      input = '42'
      result = WireGram::Languages::Expression.process(input)

      assert_snapshot('simple_expression_output', result[:output], 'expression')
    end

    it 'snapshots normalized output for arithmetic expression' do
      input = '1 + 2'
      result = WireGram::Languages::Expression.process(input)

      assert_snapshot('arithmetic_expression_output', result[:output], 'expression')
    end

    it 'snapshots normalized output for assignment' do
      input = 'let x = 42'
      result = WireGram::Languages::Expression.process(input)

      assert_snapshot('assignment_expression_output', result[:output], 'expression')
    end

    it 'snapshots normalized output for complex expression' do
      input = 'let result = (x + y) * 2'
      result = WireGram::Languages::Expression.process(input)

      assert_snapshot('complex_expression_output', result[:output], 'expression')
    end
  end

  describe 'complete pipeline snapshots' do
    it 'snapshots complete pipeline for simple expression' do
      input = '42'

      # Process through complete pipeline
      result = WireGram::Languages::Expression.process(input)

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
        #{result[:uom].root.to_json}

        === OUTPUT ===
        #{result[:output]}

        === ERRORS ===
        #{result[:errors].inspect}
      SNAPSHOT

      assert_snapshot('simple_expression_complete', snapshot_content, 'expression')
    end

    it 'snapshots complete pipeline for complex expression' do
      input = <<~EXPR
        let x = 42
        let y = x + 1
        let result = (x * y) / 2
      EXPR

      # Process through complete pipeline
      result = WireGram::Languages::Expression.process(input)

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
        #{result[:uom].root.to_json}

        === OUTPUT ===
        #{result[:output]}

        === ERRORS ===
        #{result[:errors].inspect}
      SNAPSHOT

      assert_snapshot('complex_expression_complete', snapshot_content, 'expression')
    end
  end
end
