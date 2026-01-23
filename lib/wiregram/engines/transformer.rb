# frozen_string_literal: true

require_relative '../core/node'
require_relative '../core/fabric'

module WireGram
  module Engines
    # Transformer - Transforms digital fabric
    class Transformer
      attr_reader :fabric

      def initialize(fabric)
        @fabric = fabric
      end

      # Apply a transformation to the fabric
      def apply(transformation = nil, &block)
        transformed_ast = if block_given?
          transform_with_block(@fabric.ast, &block)
        else
          case transformation
          when :constant_folding
            constant_folding(@fabric.ast)
          else
            @fabric.ast
          end
        end

        WireGram::Core::Fabric.new(@fabric.source, transformed_ast, @fabric.tokens)
      end

      private

      # Transform using a custom block
      def transform_with_block(node, &block)
        return node unless node.is_a?(WireGram::Core::Node)
        
        # Transform children first (bottom-up)
        new_children = node.children.map { |child| transform_with_block(child, &block) }
        node_with_children = node.with(children: new_children)
        
        # Apply transformation
        block.call(node_with_children) || node_with_children
      end

      # Constant folding optimization
      def constant_folding(node)
        return node unless node.is_a?(WireGram::Core::Node)

        # Transform children first
        new_children = node.children.map { |child| constant_folding(child) }
        
        # Check if this is a binary operation with constant operands
        if [:add, :subtract, :multiply, :divide].include?(node.type)
          left, right = new_children
          
          if left.type == :number && right.type == :number
            result = case node.type
                     when :add
                       left.value + right.value
                     when :subtract
                       left.value - right.value
                     when :multiply
                       left.value * right.value
                     when :divide
                       right.value != 0 ? left.value / right.value : left.value
                     end
            
            return WireGram::Core::Node.new(:number, value: result)
          end
        end

        node.with(children: new_children)
      end
    end
  end
end
