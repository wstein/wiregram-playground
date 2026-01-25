# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/wiregram'

class TestWireGramCore < Minitest::Test
  def test_node_creation
    node = WireGram::Core::Node.new(:number, value: 42)
    assert_equal :number, node.type
    assert_equal 42, node.value
    assert_empty node.children
  end

  def test_node_immutability
    node = WireGram::Core::Node.new(:number, value: 42)
    assert node.frozen?
    assert node.children.frozen?
    assert node.metadata.frozen?
  end

  def test_node_with
    node = WireGram::Core::Node.new(:number, value: 42)
    new_node = node.with(value: 100)
    
    assert_equal 42, node.value
    assert_equal 100, new_node.value
    assert_equal :number, new_node.type
  end

  def test_node_traverse
    root = WireGram::Core::Node.new(:add, children: [
      WireGram::Core::Node.new(:number, value: 1),
      WireGram::Core::Node.new(:number, value: 2)
    ])
    
    visited = []
    root.traverse { |n| visited << n.type }
    
    assert_equal [:add, :number, :number], visited
  end

  def test_node_find_all
    root = WireGram::Core::Node.new(:program, children: [
      WireGram::Core::Node.new(:number, value: 1),
      WireGram::Core::Node.new(:number, value: 2),
      WireGram::Core::Node.new(:identifier, value: 'x')
    ])
    
    numbers = root.find_all { |n| n.type == :number }
    assert_equal 2, numbers.length
  end
end

class TestWireGramLexer < Minitest::Test
  def test_tokenize_numbers
    lexer = WireGram::Languages::Expression::Lexer.new("42 3.14")
    tokens = lexer.tokenize
    
    assert_equal :number, tokens[0][:type]
    assert_equal 42, tokens[0][:value]
    assert_equal :number, tokens[1][:type]
    assert_equal 3.14, tokens[1][:value]
  end

  def test_tokenize_operators
    lexer = WireGram::Languages::Expression::Lexer.new("+ - * /")
    tokens = lexer.tokenize
    
    assert_equal :plus, tokens[0][:type]
    assert_equal :minus, tokens[1][:type]
    assert_equal :star, tokens[2][:type]
    assert_equal :slash, tokens[3][:type]
  end

  def test_tokenize_keywords
    lexer = WireGram::Languages::Expression::Lexer.new("let x")
    tokens = lexer.tokenize
    
    assert_equal :keyword, tokens[0][:type]
    assert_equal 'let', tokens[0][:value]
    assert_equal :identifier, tokens[1][:type]
    assert_equal 'x', tokens[1][:value]
  end

  def test_error_recovery
    lexer = WireGram::Languages::Expression::Lexer.new("42 @ 10")
    tokens = lexer.tokenize
    
    assert_equal :number, tokens[0][:type]
    assert_equal :number, tokens[1][:type]
    assert_equal 1, lexer.errors.length
    assert_equal '@', lexer.errors[0][:char]
  end
end

class TestWireGramParser < Minitest::Test
  def test_parse_number
    fabric = WireGram.weave("42")
    assert_equal :program, fabric.ast.type
    assert_equal :number, fabric.ast.children[0].type
    assert_equal 42, fabric.ast.children[0].value
  end

  def test_parse_addition
    fabric = WireGram.weave("10 + 5")
    expr = fabric.ast.children[0]
    
    assert_equal :add, expr.type
    assert_equal :number, expr.children[0].type
    assert_equal 10, expr.children[0].value
    assert_equal :number, expr.children[1].type
    assert_equal 5, expr.children[1].value
  end

  def test_parse_multiplication
    fabric = WireGram.weave("10 * 5")
    expr = fabric.ast.children[0]
    
    assert_equal :multiply, expr.type
    assert_equal 10, expr.children[0].value
    assert_equal 5, expr.children[1].value
  end

  def test_parse_complex_expression
    fabric = WireGram.weave("10 + 5 * 2")
    expr = fabric.ast.children[0]
    
    # Should respect operator precedence: 10 + (5 * 2)
    assert_equal :add, expr.type
    assert_equal 10, expr.children[0].value
    assert_equal :multiply, expr.children[1].type
  end

  def test_parse_assignment
    fabric = WireGram.weave("let x = 42")
    assign = fabric.ast.children[0]
    
    assert_equal :assign, assign.type
    assert_equal :identifier, assign.children[0].type
    assert_equal 'x', assign.children[0].value
    assert_equal :number, assign.children[1].type
    assert_equal 42, assign.children[1].value
  end
end

class TestWireGramFabric < Minitest::Test
  def test_to_source
    fabric = WireGram.weave("10 + 5")
    assert_equal "10 + 5", fabric.to_source
  end

  def test_to_source_assignment
    fabric = WireGram.weave("let x = 42")
    assert_equal "let x = 42", fabric.to_source
  end

  def test_find_patterns
    fabric = WireGram.weave("10 + 5 * 2")
    operations = fabric.find_patterns(:arithmetic_operations)
    
    assert_equal 2, operations.length
    assert operations.any? { |op| op.type == :add }
    assert operations.any? { |op| op.type == :multiply }
  end
end

class TestWireGramTransformer < Minitest::Test
  def test_constant_folding
    fabric = WireGram.weave("10 + 20")
    optimized = fabric.transform(:constant_folding)
    
    assert_equal "30", optimized.to_source
  end

  def test_constant_folding_multiplication
    fabric = WireGram.weave("5 * 4")
    optimized = fabric.transform(:constant_folding)
    
    assert_equal "20", optimized.to_source
  end

  def test_constant_folding_complex
    fabric = WireGram.weave("10 + 20 * 2")
    optimized = fabric.transform(:constant_folding)
    
    # Should fold 20 * 2 = 40, then 10 + 40 = 50
    assert_equal "50", optimized.to_source
  end

  def test_custom_transformation
    fabric = WireGram.weave("10 + 5")
    transformed = fabric.transform do |node|
      if node.type == :add
        # Replace addition with multiplication
        node.with(type: :multiply)
      else
        node
      end
    end
    
    assert_equal "10 * 5", transformed.to_source
  end
end

class TestWireGramAnalyzer < Minitest::Test
  def test_complexity_analysis
    fabric = WireGram.weave("10 + 5 * 2 - 3")
    analyzer = fabric.analyze
    complexity = analyzer.complexity
    
    assert complexity[:operations_count] > 0
    assert complexity[:tree_depth] > 0
  end

  def test_diagnostics
    fabric = WireGram.weave("10 + 20")
    analyzer = fabric.analyze
    diagnostics = analyzer.diagnostics
    
    # Should find constant expression optimization opportunity
    assert diagnostics.any? { |d| d[:type] == :optimization }
  end
end

class TestWireGramJson < Minitest::Test
  def test_json_tokenize_and_parse
    src = '{"a": 1, "b": [true, false, null], "c": "hi"}'
    lexer = WireGram::Languages::Json::Lexer.new(src)
    tokens = lexer.tokenize

    assert tokens.any? { |t| t[:type] == :lbrace }
    assert tokens.any? { |t| t[:type] == :rbrace }
    assert tokens.any? { |t| t[:type] == :number }
    assert tokens.any? { |t| t[:type] == :string }

    fabric = WireGram.weave(src, language: :json)
    ast = fabric.ast

    assert_equal :program, ast.type
    obj = ast.children[0]
    assert_equal :object, obj.type
    # Should have at least 3 members
    assert obj.children.length >= 3

    # Check array member exists
    pair_b = obj.children.find { |p| p.children[0].value == 'b' }
    assert pair_b
    assert_equal :array, pair_b.children[1].type

    # Check boolean and null present in array
    arr = pair_b.children[1]
    assert arr.children.any? { |v| v.type == :boolean }
    assert arr.children.any? { |v| v.type == :null }
  end
end
