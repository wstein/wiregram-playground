# frozen_string_literal: true

require_relative 'node'

module WireGram
  module Core
    # Digital Fabric - A reversible representation of source code
    # The fabric maintains both the structured (AST) and textual representations
    class Fabric
      attr_reader :source, :ast, :tokens

      def initialize(source, ast, tokens = [])
        @source = source
        @ast = ast
        @tokens = tokens
      end

      # Unweave the fabric back to source code
      def to_source
        unweave(@ast)
      end

      # Find patterns in the fabric
      def find_patterns(pattern_type)
        case pattern_type
        when :arithmetic_operations
          @ast.find_all { |node| [:add, :subtract, :multiply, :divide].include?(node.type) }
        when :literals
          @ast.find_all { |node| [:number, :string].include?(node.type) }
        when :identifiers
          @ast.find_all { |node| node.type == :identifier }
        else
          []
        end
      end

      # Analyze the fabric
      def analyze
        require_relative '../engines/analyzer'
        WireGram::Engines::Analyzer.new(self)
      end

      # Transform the fabric
      def transform(transformation = nil, &block)
        require_relative '../engines/transformer'
        transformer = WireGram::Engines::Transformer.new(self)
        transformer.apply(transformation, &block)
      end

      private

      # Unweave AST back to source code
      def unweave(node)
        case node.type
        when :program
          node.children.map { |child| unweave(child) }.join(" ")
        when :ucl_program
          # Use UCL serializer for normalized output
          require_relative '../languages/ucl/serializer'
          WireGram::Languages::Ucl::Serializer.serialize_program(node, renumber: false)
        when :pair
          key = node.children[0]
          value = node.children[1]
          key_text = key.value.to_s
          value_text = unweave(value)
          "#{key_text} = #{value_text};"
        when :object
          inner = node.children.map { |c| "  #{unweave(c)}" }.join("\n")
          "{\n#{inner}\n}"
        when :array
          "[" + node.children.map { |c| unweave(c) }.join(', ') + "]"
        when :number
          node.value.to_s
        when :string
          "\"#{node.value}\""
        when :identifier
          node.value.to_s
        when :boolean
          node.value ? 'true' : 'false'
        when :null
          'null'
        when :add
          "#{unweave(node.children[0])} + #{unweave(node.children[1])}"
        when :subtract
          "#{unweave(node.children[0])} - #{unweave(node.children[1])}"
        when :multiply
          "#{unweave(node.children[0])} * #{unweave(node.children[1])}"
        when :divide
          "#{unweave(node.children[0])} / #{unweave(node.children[1])}"
        when :assign
          "let #{node.children[0].value} = #{unweave(node.children[1])}"
        else
          node.value.to_s
        end
      end
    end
  end
end
