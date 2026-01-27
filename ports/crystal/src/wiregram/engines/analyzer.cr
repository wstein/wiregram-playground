# frozen_string_literal: true

require "../core/node"
require "../core/fabric"

module WireGram
  module Engines
    # Analyzer - Analyzes digital fabric for patterns and issues
    class Analyzer
      getter fabric : WireGram::Core::Fabric

      def initialize(fabric : WireGram::Core::Fabric)
        @fabric = fabric
      end

      # Find patterns in the fabric
      def find_patterns(pattern_type)
        @fabric.find_patterns(pattern_type)
      end

      # Find unused variables
      def find_unused_variables
        @fabric.find_patterns(:identifiers)
        # Simple heuristic: variables defined but never referenced elsewhere
        # In a real implementation, this would do proper scope analysis
        [] of WireGram::Core::Node
      end

      # Analyze complexity
      def complexity
        operations = @fabric.find_patterns(:arithmetic_operations)
        {
          operations_count: operations.size,
          tree_depth: calculate_depth(@fabric.ast)
        }
      end

      # Get all diagnostics
      def diagnostics
        issues = [] of Hash(Symbol, String | Symbol | WireGram::Core::Node)

        # Check for potential constant folding opportunities
        @fabric.ast.traverse do |node|
          if [WireGram::Core::NodeType::Add, WireGram::Core::NodeType::Subtract, WireGram::Core::NodeType::Multiply, WireGram::Core::NodeType::Divide].includes?(node.type) &&
             node.children.all? { |c| c.type == WireGram::Core::NodeType::Number }
            issues << {
              type: :optimization,
              message: "Constant expression can be folded",
              node: node,
              severity: :info
            }
          end
        end

        issues
      end

      private def calculate_depth(node : WireGram::Core::Node, current_depth = 0)
        if node.children.empty?
          current_depth
        else
          node.children.map { |child| calculate_depth(child, current_depth + 1) }.max
        end
      end
    end
  end
end
