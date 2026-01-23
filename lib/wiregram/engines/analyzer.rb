# frozen_string_literal: true

require_relative '../core/node'

module WireGram
  module Engines
    # Analyzer - Analyzes digital fabric for patterns and issues
    class Analyzer
      attr_reader :fabric

      def initialize(fabric)
        @fabric = fabric
      end

      # Find patterns in the fabric
      def find_patterns(pattern_type)
        @fabric.find_patterns(pattern_type)
      end

      # Find unused variables
      def find_unused_variables
        identifiers = @fabric.find_patterns(:identifiers)
        # Simple heuristic: variables defined but never referenced elsewhere
        # In a real implementation, this would do proper scope analysis
        []
      end

      # Analyze complexity
      def complexity
        operations = @fabric.find_patterns(:arithmetic_operations)
        {
          operations_count: operations.length,
          tree_depth: calculate_depth(@fabric.ast)
        }
      end

      # Get all diagnostics
      def diagnostics
        issues = []
        
        # Check for potential constant folding opportunities
        @fabric.ast.traverse do |node|
          if [:add, :subtract, :multiply, :divide].include?(node.type)
            if node.children.all? { |c| c.type == :number }
              issues << {
                type: :optimization,
                message: "Constant expression can be folded",
                node: node,
                severity: :info
              }
            end
          end
        end

        issues
      end

      private

      def calculate_depth(node, current_depth = 0)
        return current_depth unless node.is_a?(WireGram::Core::Node)
        
        if node.children.empty?
          current_depth
        else
          node.children.map { |child| calculate_depth(child, current_depth + 1) }.max
        end
      end
    end
  end
end
