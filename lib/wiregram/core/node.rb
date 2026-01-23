# frozen_string_literal: true

module WireGram
  module Core
    # AST Node - Represents a node in the abstract syntax tree
    # Nodes are immutable and reversible
    class Node
      attr_reader :type, :value, :children, :metadata

      def initialize(type, value: nil, children: [], metadata: {})
        @type = type
        @value = value
        @children = children.freeze
        @metadata = metadata.freeze
        freeze
      end

      # Create a new node with updated properties
      def with(type: @type, value: @value, children: @children, metadata: @metadata)
        self.class.new(type, value: value, children: children, metadata: metadata)
      end

      # Traverse the tree depth-first
      def traverse(&block)
        block.call(self)
        @children.each { |child| child.traverse(&block) if child.is_a?(Node) }
      end

      # Find nodes matching a condition
      def find_all(&block)
        results = []
        traverse { |node| results << node if block.call(node) }
        results
      end

      # Convert to hash representation
      def to_h
        {
          type: @type,
          value: @value,
          children: @children.map { |c| c.is_a?(Node) ? c.to_h : c },
          metadata: @metadata
        }
      end

      def inspect
        "#<Node type=#{@type} value=#{@value.inspect} children=#{@children.length}>"
      end
    end
  end
end
