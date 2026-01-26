# frozen_string_literal: true

require_relative 'test_helper'

describe 'Expression UOM' do
  include ExpressionTestHelper

  describe 'Value classes' do
    it 'creates number values' do
      value = WireGram::Languages::Expression::UOM::NumberValue.new(42)
      expect(value.type).to eq(:number)
      expect(value.value).to eq(42)
      expect(value.to_expression).to eq('42')
      expect(value.to_simple_json).to eq(42)
    end

    it 'creates string values' do
      value = WireGram::Languages::Expression::UOM::StringValue.new('hello')
      expect(value.type).to eq(:string)
      expect(value.value).to eq('hello')
      expect(value.to_expression).to eq('"hello"')
      expect(value.to_simple_json).to eq('hello')
    end

    it 'creates identifier values' do
      value = WireGram::Languages::Expression::UOM::IdentifierValue.new('x')
      expect(value.type).to eq(:identifier)
      expect(value.value).to eq('x')
      expect(value.to_expression).to eq('x')
      expect(value.to_simple_json).to eq('x')
    end

    it 'creates boolean values' do
      true_value = WireGram::Languages::Expression::UOM::BooleanValue.new(true)
      false_value = WireGram::Languages::Expression::UOM::BooleanValue.new(false)

      expect(true_value.type).to eq(:boolean)
      expect(true_value.value).to eq(true)
      expect(true_value.to_expression).to eq('true')
      expect(true_value.to_simple_json).to eq(true)

      expect(false_value.type).to eq(:boolean)
      expect(false_value.value).to eq(false)
      expect(false_value.to_expression).to eq('false')
      expect(false_value.to_simple_json).to eq(false)
    end

    it 'creates null values' do
      value = WireGram::Languages::Expression::UOM::NullValue.new
      expect(value.type).to eq(:null)
      expect(value.value).to be_nil
      expect(value.to_expression).to eq('null')
      expect(value.to_simple_json).to be_nil
    end

    it 'supports equality checking' do
      value1 = WireGram::Languages::Expression::UOM::NumberValue.new(42)
      value2 = WireGram::Languages::Expression::UOM::NumberValue.new(42)
      value3 = WireGram::Languages::Expression::UOM::NumberValue.new(43)
      value4 = WireGram::Languages::Expression::UOM::StringValue.new('42')

      expect(value1).to eq(value2)
      expect(value1).not_to eq(value3)
      expect(value1).not_to eq(value4)
    end
  end

  describe 'BinaryOperation' do
    it 'creates binary operations' do
      left = WireGram::Languages::Expression::UOM::NumberValue.new(1)
      right = WireGram::Languages::Expression::UOM::NumberValue.new(2)
      op = WireGram::Languages::Expression::UOM::BinaryOperation.new('+', left, right)

      expect(op.operator).to eq(:+)
      expect(op.left).to eq(left)
      expect(op.right).to eq(right)
      expect(op.to_expression).to eq('1 + 2')
    end

    it 'handles operator precedence with parentheses' do
      # 1 + 2 * 3 should be 1 + 2 * 3 (no parentheses needed - * has higher precedence)
      left = WireGram::Languages::Expression::UOM::NumberValue.new(1)
      right_op = WireGram::Languages::Expression::UOM::BinaryOperation.new(
        '*',
        WireGram::Languages::Expression::UOM::NumberValue.new(2),
        WireGram::Languages::Expression::UOM::NumberValue.new(3)
      )
      op = WireGram::Languages::Expression::UOM::BinaryOperation.new('+', left, right_op)

      expect(op.to_expression).to eq('1 + 2 * 3')

      # (1 + 2) * 3 should have parentheses because + has lower precedence than *
      left_op = WireGram::Languages::Expression::UOM::BinaryOperation.new(
        '+',
        WireGram::Languages::Expression::UOM::NumberValue.new(1),
        WireGram::Languages::Expression::UOM::NumberValue.new(2)
      )
      right = WireGram::Languages::Expression::UOM::NumberValue.new(3)
      op2 = WireGram::Languages::Expression::UOM::BinaryOperation.new('*', left_op, right)

      expect(op2.to_expression).to eq('(1 + 2) * 3')
    end

    it 'supports equality checking' do
      left1 = WireGram::Languages::Expression::UOM::NumberValue.new(1)
      right1 = WireGram::Languages::Expression::UOM::NumberValue.new(2)
      op1 = WireGram::Languages::Expression::UOM::BinaryOperation.new('+', left1, right1)

      left2 = WireGram::Languages::Expression::UOM::NumberValue.new(1)
      right2 = WireGram::Languages::Expression::UOM::NumberValue.new(2)
      op2 = WireGram::Languages::Expression::UOM::BinaryOperation.new('+', left2, right2)

      left3 = WireGram::Languages::Expression::UOM::NumberValue.new(1)
      right3 = WireGram::Languages::Expression::UOM::NumberValue.new(3)
      op3 = WireGram::Languages::Expression::UOM::BinaryOperation.new('+', left3, right3)

      expect(op1).to eq(op2)
      expect(op1).not_to eq(op3)
    end
  end

  describe 'UnaryOperation' do
    it 'creates unary operations' do
      operand = WireGram::Languages::Expression::UOM::NumberValue.new(5)
      op = WireGram::Languages::Expression::UOM::UnaryOperation.new('-', operand)

      expect(op.operator).to eq(:-)
      expect(op.operand).to eq(operand)
      expect(op.to_expression).to eq('-5')
    end

    it 'adds parentheses for binary operation operands' do
      left = WireGram::Languages::Expression::UOM::NumberValue.new(1)
      right = WireGram::Languages::Expression::UOM::NumberValue.new(2)
      binary_op = WireGram::Languages::Expression::UOM::BinaryOperation.new('+', left, right)
      unary_op = WireGram::Languages::Expression::UOM::UnaryOperation.new('-', binary_op)

      expect(unary_op.to_expression).to eq('-(1 + 2)')
    end
  end

  describe 'FunctionCall' do
    it 'creates function calls' do
      args = [
        WireGram::Languages::Expression::UOM::NumberValue.new(1),
        WireGram::Languages::Expression::UOM::NumberValue.new(2)
      ]
      func = WireGram::Languages::Expression::UOM::FunctionCall.new('add', args)

      expect(func.name).to eq('add')
      expect(func.arguments).to eq(args)
      expect(func.to_expression).to eq('add(1, 2)')
    end

    it 'handles empty arguments' do
      func = WireGram::Languages::Expression::UOM::FunctionCall.new('pi')
      expect(func.to_expression).to eq('pi()')
    end
  end

  describe 'Assignment' do
    it 'creates assignments' do
      variable = WireGram::Languages::Expression::UOM::IdentifierValue.new('x')
      value = WireGram::Languages::Expression::UOM::NumberValue.new(42)
      assignment = WireGram::Languages::Expression::UOM::Assignment.new(variable, value)

      expect(assignment.variable).to eq(variable)
      expect(assignment.value).to eq(value)
      expect(assignment.to_expression).to eq('x = 42')
    end
  end

  describe 'Program' do
    it 'creates programs' do
      stmt1 = WireGram::Languages::Expression::UOM::NumberValue.new(1)
      stmt2 = WireGram::Languages::Expression::UOM::NumberValue.new(2)
      program = WireGram::Languages::Expression::UOM::Program.new([stmt1, stmt2])

      expect(program.statements).to eq([stmt1, stmt2])
      expect(program.to_expression).to eq("1\n2")
    end
  end

  describe 'JSON serialization' do
    it 'serializes values to JSON' do
      value = WireGram::Languages::Expression::UOM::NumberValue.new(42)
      json = value.to_json_format

      expect(json).to eq({
                           type: :number,
                           value: 42
                         })
    end

    it 'serializes binary operations to JSON' do
      left = WireGram::Languages::Expression::UOM::NumberValue.new(1)
      right = WireGram::Languages::Expression::UOM::NumberValue.new(2)
      op = WireGram::Languages::Expression::UOM::BinaryOperation.new('+', left, right)
      json = op.to_json_format

      expect(json).to eq({
                           type: :binary_operation,
                           operator: :+,
                           left: { type: :number, value: 1 },
                           right: { type: :number, value: 2 }
                         })
    end
  end
end
