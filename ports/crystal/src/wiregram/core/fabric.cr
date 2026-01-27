# frozen_string_literal: true

require "./node"
require "./token"
require "../engines/analyzer"
require "../engines/transformer"
require "../languages/ucl/serializer"

module WireGram
  module Core
    # Digital Fabric - A reversible representation of source code
    # The fabric maintains both the structured (AST) and textual representations
    class Fabric
      getter source : String
      getter ast : Node
      getter tokens : Array(Token)

      def initialize(@source : String, @ast : Node, @tokens : Array(Token) = [] of Token)
      end

      # Unweave the fabric back to source code
      def to_source : String
        unweave(@ast)
      end

      # Find patterns in the fabric
      def find_patterns(pattern_type)
        case pattern_type
        when :arithmetic_operations
          @ast.find_all { |node| [NodeType::Add, NodeType::Subtract, NodeType::Multiply, NodeType::Divide].includes?(node.type) }
        when :literals
          @ast.find_all { |node| [NodeType::Number, NodeType::String].includes?(node.type) }
        when :identifiers
          @ast.find_all { |node| node.type == NodeType::Identifier }
        else
          [] of Node
        end
      end

      # Analyze the fabric
      def analyze
        WireGram::Engines::Analyzer.new(self)
      end

      # Transform the fabric
      def transform(transformation = nil)
        transformer = WireGram::Engines::Transformer.new(self)
        transformer.apply(transformation)
      end

      def transform(transformation = nil, &block : WireGram::Core::Node -> WireGram::Core::Node?)
        transformer = WireGram::Engines::Transformer.new(self)
        transformer.apply(transformation, &block)
      end

      # Unweave AST back to source code
      private def unweave(node : Node) : String
        case node.type
        when NodeType::Program
          node.children.map { |child| unweave(child) }.join(" ")
        when NodeType::UclProgram
          # Use UCL serializer for normalized output
          WireGram::Languages::Ucl::Serializer.serialize_program(node, renumber: false)
        when NodeType::Pair
          key = node.children[0]
          value = node.children[1]
          key_text = key.value.to_s
          value_text = unweave(value)
          "#{key_text} = #{value_text};"
        when NodeType::Object
          inner = node.children.map { |c| "  #{unweave(c)}" }.join("\n")
          "{\n#{inner}\n}"
        when NodeType::Array
          "[#{node.children.map { |c| unweave(c) }.join(", ")}]"
        when NodeType::Number
          node.value.to_s
        when NodeType::String
          "\"#{node.value}\""
        when NodeType::Identifier
          node.value.to_s
        when NodeType::Boolean
          node.value.as(Bool) ? "true" : "false"
        when NodeType::Null
          "null"
        when NodeType::Add
          "#{unweave(node.children[0])} + #{unweave(node.children[1])}"
        when NodeType::Subtract
          "#{unweave(node.children[0])} - #{unweave(node.children[1])}"
        when NodeType::Multiply
          "#{unweave(node.children[0])} * #{unweave(node.children[1])}"
        when NodeType::Divide
          "#{unweave(node.children[0])} / #{unweave(node.children[1])}"
        when NodeType::Assign
          "let #{node.children[0].value} = #{unweave(node.children[1])}"
        else
          node.value.to_s
        end
      end
    end
  end
end
