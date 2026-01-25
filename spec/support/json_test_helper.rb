# frozen_string_literal: true

module JsonTestHelper
  # Helper methods for JSON testing
  def json_fixture_path(filename)
    File.join(fixture_dir, 'json', filename)
  end

  def json_fixture(filename)
    File.read(json_fixture_path(filename))
  end

  def fixture_dir
    File.join(File.dirname(__FILE__), '..', 'languages', 'json', 'fixtures')
  end

  def create_json_uom_from_hash(hash)
    WireGram::Languages::Json::UOM.new(
      hash_to_json_uom(hash)
    )
  end

  def hash_to_json_uom(hash)
    case hash
    when Hash
      items = hash.map do |key, value|
        WireGram::Languages::Json::UOM::ObjectItem.new(
          key,
          hash_to_json_uom(value)
        )
      end
      WireGram::Languages::Json::UOM::ObjectValue.new(items)
    when Array
      items = hash.map { |item| hash_to_json_uom(item) }
      WireGram::Languages::Json::UOM::ArrayValue.new(items)
    when String
      WireGram::Languages::Json::UOM::StringValue.new(hash)
    when Numeric
      WireGram::Languages::Json::UOM::NumberValue.new(hash)
    when TrueClass, FalseClass
      WireGram::Languages::Json::UOM::BooleanValue.new(hash)
    when NilClass
      WireGram::Languages::Json::UOM::NullValue.new
    else
      WireGram::Languages::Json::UOM::StringValue.new(hash.to_s)
    end
  end

  def assert_json_uom_equal(expected, actual)
    expect(actual).to be_instance_of(expected.class)
    expect(actual).to eq(expected)
  end

  def assert_json_normalized(expected, actual)
    expect(actual.to_normalized_string).to eq(expected)
  end

  def assert_json_simple_equal(expected, actual)
    expect(actual.to_simple_json).to eq(expected)
  end

  # Common test cases for JSON values
  def json_value_test_cases
    [
      { input: 'null', expected: nil, type: :null },
      { input: 'true', expected: true, type: :boolean },
      { input: 'false', expected: false, type: :boolean },
      { input: '"hello"', expected: 'hello', type: :string },
      { input: '42', expected: 42, type: :number },
      { input: '3.14', expected: 3.14, type: :number },
      { input: '-1e10', expected: -1e10, type: :number }
    ]
  end

  # Common test cases for JSON objects
  def json_object_test_cases
    [
      { input: '{}', expected: {}, description: 'empty object' },
      {
        input: '{"key": "value"}',
        expected: { 'key' => 'value' },
        description: 'simple object'
      },
      {
        input: '{"name": "John", "age": 30}',
        expected: { 'name' => 'John', 'age' => 30 },
        description: 'object with mixed types'
      }
    ]
  end

  # Common test cases for JSON arrays
  def json_array_test_cases
    [
      { input: '[]', expected: [], description: 'empty array' },
      { input: '["a", "b"]', expected: ['a', 'b'], description: 'string array' },
      { input: '[1, 2, 3]', expected: [1, 2, 3], description: 'number array' },
      { input: '[true, false]', expected: [true, false], description: 'boolean array' }
    ]
  end

  # Edge case test cases
  def json_edge_case_test_cases
    [
      { input: '"\n"', expected: "\n", description: 'newline in string' },
      { input: '"\t"', expected: "\t", description: 'tab in string' },
      { input: '"\\""', expected: '"', description: 'escaped quote' },
      { input: '"\\\\"', expected: '\\', description: 'escaped backslash' },
      { input: '"\\u0041"', expected: 'A', description: 'unicode escape' },
      { input: '1e100', expected: 1e100, description: 'large scientific notation' },
      { input: '1e-100', expected: 1e-100, description: 'small scientific notation' }
    ]
  end
end

RSpec.configure do |config|
  config.include JsonTestHelper
end
