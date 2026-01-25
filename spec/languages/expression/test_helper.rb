# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/wiregram/languages/expression'

module ExpressionTestHelper
  def process_expression(input)
    WireGram::Languages::Expression.process(input)
  end

  def tokenize_expression(input)
    WireGram::Languages::Expression.tokenize(input)
  end

  def parse_expression(input)
    WireGram::Languages::Expression.parse(input)
  end

  def transform_expression(input)
    WireGram::Languages::Expression.transform(input)
  end

  def serialize_expression(input)
    WireGram::Languages::Expression.serialize(input)
  end

  def load_fixture(filename)
    fixture_path = File.join(File.dirname(__FILE__), 'fixtures', filename)
    File.read(fixture_path)
  end

  def load_valid_fixture(filename)
    load_fixture("valid/#{filename}")
  end

  def load_invalid_fixture(filename)
    load_fixture("invalid/#{filename}")
  end

  def assert_expression_pipeline(input, expected_output = nil)
    result = process_expression(input)

    # Check that all pipeline stages completed
    expect(result).to have_key(:tokens)
    expect(result).to have_key(:ast)
    expect(result).to have_key(:uom)
    expect(result).to have_key(:output)

    # Check that tokens were generated
    expect(result[:tokens]).to be_a(Array)
    expect(result[:tokens].size).to be > 0

    # Check that AST was generated
    expect(result[:ast]).to be_a(WireGram::Core::Node)

    # Check that UOM was generated
    expect(result[:uom]).to be_a(WireGram::Languages::Expression::UOM)
    expect(result[:uom].root).not_to be_nil

    # Check that output was generated
    expect(result[:output]).to be_a(String)
    expect(result[:output].length).to be > 0

    # If expected output is provided, check it matches
    if expected_output
      # Normalize escaped newline literals in expected_output (allow both "\n" or real newlines)
      normalized_expected = expected_output.gsub('\\n', "\n")
      expect(result[:output]).to eq(normalized_expected)
    end

    result
  end

  def assert_expression_error(input, expected_error_types = [])
    result = process_expression(input)

    # Check that errors were detected
    expect(result[:errors]).to be_a(Array)
    expect(result[:errors].size).to be > 0

    # Check that expected error types are present
    error_types = result[:errors].map { |error| error[:type] }
    expected_error_types.each do |expected_type|
      expect(error_types).to include(expected_type)
    end

    result
  end
end
