# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/json_test_helper'
require_relative '../../../lib/wiregram/languages/json'

describe WireGram::Languages::Json::UOM do
  describe 'Value classes' do
    describe 'StringValue' do
      it 'creates string value' do
        value = described_class::StringValue.new('hello')
        expect(value.type).to eq(:string)
        expect(value.value).to eq('hello')
      end

      it 'serializes to JSON' do
        value = described_class::StringValue.new('hello')
        expect(value.to_json).to eq('"hello"')
      end

      it 'handles escaped characters' do
        value = described_class::StringValue.new('line1\nline2')
        expect(value.to_json).to eq('"line1\\\\nline2"')
      end

      it 'handles quotes in strings' do
        value = described_class::StringValue.new('He said "Hello"')
        expect(value.to_json).to eq('"He said \\"Hello\\""')
      end

      it 'to_simple_json returns the value' do
        value = described_class::StringValue.new('hello')
        expect(value.to_simple_json).to eq('hello')
      end
    end

    describe 'NumberValue' do
      it 'creates number value' do
        value = described_class::NumberValue.new(42)
        expect(value.type).to eq(:number)
        expect(value.value).to eq(42)
      end

      it 'serializes to JSON' do
        value = described_class::NumberValue.new(42)
        expect(value.to_json).to eq('42')
      end

      it 'handles floats' do
        value = described_class::NumberValue.new(3.14)
        expect(value.to_json).to eq('3.14')
      end

      it 'to_simple_json returns the value' do
        value = described_class::NumberValue.new(42)
        expect(value.to_simple_json).to eq(42)
      end
    end

    describe 'BooleanValue' do
      it 'creates true value' do
        value = described_class::BooleanValue.new(true)
        expect(value.type).to eq(:boolean)
        expect(value.value).to eq(true)
      end

      it 'creates false value' do
        value = described_class::BooleanValue.new(false)
        expect(value.type).to eq(:boolean)
        expect(value.value).to eq(false)
      end

      it 'serializes to JSON' do
        value = described_class::BooleanValue.new(true)
        expect(value.to_json).to eq('true')
      end

      it 'to_simple_json returns the value' do
        value = described_class::BooleanValue.new(true)
        expect(value.to_simple_json).to eq(true)
      end
    end

    describe 'NullValue' do
      it 'creates null value' do
        value = described_class::NullValue.new
        expect(value.type).to eq(:null)
        expect(value.value).to be_nil
      end

      it 'serializes to JSON' do
        value = described_class::NullValue.new
        expect(value.to_json).to eq('null')
      end

      it 'to_simple_json returns nil' do
        value = described_class::NullValue.new
        expect(value.to_simple_json).to be_nil
      end
    end
  end

  describe 'ObjectValue' do
    it 'creates empty object' do
      obj = described_class::ObjectValue.new([])
      expect(obj.items).to be_empty
      expect(obj.to_json).to eq('{}')
    end

    it 'creates object with items' do
      items = [
        described_class::ObjectItem.new('name', described_class::StringValue.new('John')),
        described_class::ObjectItem.new('age', described_class::NumberValue.new(30))
      ]
      obj = described_class::ObjectValue.new(items)
      expect(obj.items.length).to eq(2)
      expect(obj.to_json).to eq('{"name": "John", "age": 30}')
    end

    it 'to_simple_json returns hash' do
      items = [
        described_class::ObjectItem.new('name', described_class::StringValue.new('John')),
        described_class::ObjectItem.new('age', described_class::NumberValue.new(30))
      ]
      obj = described_class::ObjectValue.new(items)
      expected = { 'name' => 'John', 'age' => 30 }
      expect(obj.to_simple_json).to eq(expected)
    end
  end

  describe 'ArrayValue' do
    it 'creates empty array' do
      arr = described_class::ArrayValue.new([])
      expect(arr.items).to be_empty
      expect(arr.to_json).to eq('[]')
    end

    it 'creates array with items' do
      items = [
        described_class::StringValue.new('a'),
        described_class::NumberValue.new(1),
        described_class::BooleanValue.new(true)
      ]
      arr = described_class::ArrayValue.new(items)
      expect(arr.items.length).to eq(3)
      expect(arr.to_json).to eq('["a", 1, true]')
    end

    it 'to_simple_json returns array' do
      items = [
        described_class::StringValue.new('a'),
        described_class::NumberValue.new(1),
        described_class::BooleanValue.new(true)
      ]
      arr = described_class::ArrayValue.new(items)
      expected = ['a', 1, true]
      expect(arr.to_simple_json).to eq(expected)
    end
  end

  describe 'ObjectItem' do
    it 'creates object item' do
      key = 'name'
      value = described_class::StringValue.new('John')
      item = described_class::ObjectItem.new(key, value)
      expect(item.key).to eq('name')
      expect(item.value).to eq(value)
    end

    it 'serializes to JSON' do
      key = 'name'
      value = described_class::StringValue.new('John')
      item = described_class::ObjectItem.new(key, value)
      expect(item.to_json).to eq('"name": "John"')
    end

    it 'to_simple_json returns array' do
      key = 'name'
      value = described_class::StringValue.new('John')
      item = described_class::ObjectItem.new(key, value)
      expect(item.to_simple_json).to eq(['name', 'John'])
    end
  end

  describe 'UOM' do
    it 'creates UOM with root' do
      root = described_class::StringValue.new('hello')
      uom = described_class.new(root)
      expect(uom.root).to eq(root)
    end

    it 'to_normalized_string returns JSON' do
      root = described_class::StringValue.new('hello')
      uom = described_class.new(root)
      expect(uom.to_normalized_string).to eq('"hello"')
    end

    it 'to_simple_json returns simple value' do
      root = described_class::StringValue.new('hello')
      uom = described_class.new(root)
      expect(uom.to_simple_json).to eq('hello')
    end

    it 'handles nil root' do
      uom = described_class.new(nil)
      expect(uom.to_normalized_string).to eq('')
      expect(uom.to_simple_json).to be_nil
    end
  end

  describe 'Equality' do
    it 'compares string values' do
      v1 = described_class::StringValue.new('hello')
      v2 = described_class::StringValue.new('hello')
      v3 = described_class::StringValue.new('world')
      expect(v1).to eq(v2)
      expect(v1).not_to eq(v3)
    end

    it 'compares object values' do
      items1 = [described_class::ObjectItem.new('a', described_class::StringValue.new('1'))]
      items2 = [described_class::ObjectItem.new('a', described_class::StringValue.new('1'))]
      items3 = [described_class::ObjectItem.new('b', described_class::StringValue.new('2'))]

      obj1 = described_class::ObjectValue.new(items1)
      obj2 = described_class::ObjectValue.new(items2)
      obj3 = described_class::ObjectValue.new(items3)

      expect(obj1).to eq(obj2)
      expect(obj1).not_to eq(obj3)
    end
  end
end
