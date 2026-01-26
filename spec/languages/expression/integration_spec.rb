# frozen_string_literal: true

require_relative 'test_helper'

describe 'Expression Language Integration' do
  include ExpressionTestHelper

  describe 'complete pipeline processing' do
    it 'processes simple numbers' do
      result = assert_expression_pipeline('42', '42')
      expect(result[:output]).to eq('42')
    end

    it 'processes identifiers' do
      result = assert_expression_pipeline('x', 'x')
      expect(result[:output]).to eq('x')
    end

    it 'processes strings' do
      result = assert_expression_pipeline('"hello"', '"hello"')
      expect(result[:output]).to eq('"hello"')
    end

    it 'processes arithmetic expressions' do
      result = assert_expression_pipeline('1 + 2', '1 + 2')
      expect(result[:output]).to eq('1 + 2')
    end

    it 'processes complex arithmetic with precedence' do
      result = assert_expression_pipeline('1 + 2 * 3', '1 + 2 * 3')
      expect(result[:output]).to eq('1 + 2 * 3')
    end

    it 'processes parenthesized expressions' do
      result = assert_expression_pipeline('(1 + 2) * 3', '(1 + 2) * 3')
      expect(result[:output]).to eq('(1 + 2) * 3')
    end

    it 'processes assignments' do
      result = assert_expression_pipeline('let x = 42', 'let x = 42')
      expect(result[:output]).to eq('let x = 42')
    end

    it 'processes complex programs' do
      input = "let x = 42\nlet y = x + 1\nx * y"
      result = assert_expression_pipeline(input, input)
      expect(result[:output]).to eq(input)
    end
  end

  describe 'error handling' do
    it 'handles incomplete expressions' do
      result = assert_expression_error('let x =', [:unexpected_token])
      expect(result[:errors]).to be_a(Array)
      expect(result[:errors].size).to be > 0
    end

    it 'handles malformed expressions' do
      result = assert_expression_error('1 + + 2', [:unexpected_token])
      expect(result[:errors]).to be_a(Array)
      expect(result[:errors].size).to be > 0
    end

    it 'handles unclosed strings' do
      result = assert_expression_error('"unclosed string', [:unexpected_token])
      expect(result[:errors]).to be_a(Array)
      expect(result[:errors].size).to be > 0
    end
  end

  describe 'fixture-based testing' do
    it 'processes valid simple expressions' do
      input = load_valid_fixture('simple.txt')
      result = assert_expression_pipeline(input.strip, '42')
      expect(result[:output]).to eq('42')
    end

    it 'processes valid identifiers' do
      input = load_valid_fixture('identifiers.txt')
      result = assert_expression_pipeline(input.strip, "x\nvariable_name\nresult")
      expect(result[:output]).to eq("x\nvariable_name\nresult")
    end

    it 'processes valid strings' do
      input = load_valid_fixture('strings.txt')
      assert_expression_pipeline(input.strip, '"hello"\n"world"\n"test string"')
    end

    it 'processes valid arithmetic expressions' do
      input = load_valid_fixture('arithmetic.txt')
      result = assert_expression_pipeline(input.strip, "1 + 2\nx * y\na - b\nresult / 2\n1 + 2 * 3\n(1 + 2) * 3")
      expect(result[:output]).to eq("1 + 2\nx * y\na - b\nresult / 2\n1 + 2 * 3\n(1 + 2) * 3")
    end

    it 'processes valid assignments' do
      input = load_valid_fixture('assignments.txt')
      result = assert_expression_pipeline(input.strip,
                                          "let x = 42\nlet result = x + y\nlet message = \"hello\"\nlet value = 1 * 2 + 3")
      expect(result[:output]).to eq("let x = 42\nlet result = x + y\nlet message = \"hello\"\nlet value = 1 * 2 + 3")
    end

    it 'processes valid complex expressions' do
      input = load_valid_fixture('complex.txt')
      result = assert_expression_pipeline(input.strip, input.strip)
      expect(result[:output]).to eq(input.strip)
    end

    it 'handles invalid incomplete expressions' do
      input = load_invalid_fixture('incomplete.txt')
      result = assert_expression_error(input.strip, [:unexpected_token])
      expect(result[:errors]).to be_a(Array)
      expect(result[:errors].size).to be > 0
    end

    it 'handles invalid malformed expressions' do
      input = load_invalid_fixture('malformed.txt')
      result = assert_expression_error(input.strip, [:unexpected_token])
      expect(result[:errors]).to be_a(Array)
      expect(result[:errors].size).to be > 0
    end
  end

  describe 'API methods' do
    it 'provides tokenize method' do
      tokens = tokenize_expression('1 + 2')
      expect(tokens).to be_a(Array)
      expect(tokens.size).to be > 0
      expect(tokens.first).to have_key(:type)
      expect(tokens.first).to have_key(:value)
    end

    it 'provides parse method' do
      ast = parse_expression('1 + 2')
      expect(ast).to be_a(WireGram::Core::Node)
      expect(ast.type).to eq(:program)
    end

    it 'provides transform method' do
      uom = transform_expression('1 + 2')
      expect(uom).to be_a(WireGram::Languages::Expression::UOM)
      expect(uom.root).not_to be_nil
    end

    it 'provides serialize method' do
      output = serialize_expression('1 + 2')
      expect(output).to be_a(String)
      expect(output).to eq('1 + 2')
    end

    it 'provides process method' do
      result = process_expression('1 + 2')
      expect(result).to have_key(:tokens)
      expect(result).to have_key(:ast)
      expect(result).to have_key(:uom)
      expect(result).to have_key(:output)
      expect(result[:output]).to eq('1 + 2')
    end
  end

  describe 'pretty printing' do
    it 'provides process_pretty method' do
      result = WireGram::Languages::Expression.process_pretty('1 + 2', 2)
      expect(result[:output]).to eq('1 + 2')
    end

    it 'provides process_simple method' do
      result = WireGram::Languages::Expression.process_simple('1 + 2')
      expect(result[:output]).to eq('1 + 2')
    end
  end
end
