# frozen_string_literal: true

require "../core/node"
require "../core/fabric"

module WireGram
  module Engines
    # Transformer - Transforms digital fabric
    class Transformer
      getter fabric : WireGram::Core::Fabric

      def initialize(fabric : WireGram::Core::Fabric)
        @fabric = fabric
      end

      # Apply a transformation to the fabric
      def apply(transformation = nil)
        transformed_ast = case transformation
                          when :constant_folding
                            constant_folding(@fabric.ast)
                          else
                            @fabric.ast
                          end

        WireGram::Core::Fabric.new(@fabric.source, transformed_ast, @fabric.tokens)
      end

      def apply(transformation = nil, &block : WireGram::Core::Node -> WireGram::Core::Node?)
        transformed_ast = transform_with_block(@fabric.ast, &block)
        WireGram::Core::Fabric.new(@fabric.source, transformed_ast, @fabric.tokens)
      end

      # Transform using a custom block
      private def transform_with_block(node : WireGram::Core::Node, &block : WireGram::Core::Node -> WireGram::Core::Node?)
        # Transform children first (bottom-up)
        new_children = node.children.map { |child| transform_with_block(child, &block) }
        node_with_children = node.with(children: new_children)

        # Apply transformation
        block.call(node_with_children) || node_with_children
      end

      # Perform division with zero check
      def safe_divide(numerator : Float64, denominator : Float64)
        denominator.zero? ? numerator : numerator / denominator
      end

      def to_float(value)
        case value
        when Float64
          value
        when Int64
          value.to_f64
        else
          0.0
        end
      end

      # Constant folding optimization
      def constant_folding(node : WireGram::Core::Node) : WireGram::Core::Node
        # Transform children first
        new_children = node.children.map { |child| constant_folding(child) }

        # Check if this is a binary operation with constant operands
        if [WireGram::Core::NodeType::Add, WireGram::Core::NodeType::Subtract, WireGram::Core::NodeType::Multiply, WireGram::Core::NodeType::Divide].includes?(node.type)
          left, right = new_children

          if left.type == WireGram::Core::NodeType::Number && right.type == WireGram::Core::NodeType::Number
            left_val = to_float(left.value)
            right_val = to_float(right.value)

            result = case node.type
                     when WireGram::Core::NodeType::Add
                       left_val + right_val
                     when WireGram::Core::NodeType::Subtract
                       left_val - right_val
                     when WireGram::Core::NodeType::Multiply
                       left_val * right_val
                     when WireGram::Core::NodeType::Divide
                       safe_divide(left_val, right_val)
                     else
                       left_val
                     end

            return WireGram::Core::Node.new(:number, value: result)
          end
        end

        node.with(children: new_children)
      end
    end
  end
end
