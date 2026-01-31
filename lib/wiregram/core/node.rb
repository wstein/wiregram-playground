# frozen_string_literal: true
# typed: false

begin
  require 'sorbet-runtime'
rescue LoadError
end

require 'json'

module WireGram
  module Core
    # AST Node - Represents a node in the abstract syntax tree
    # Nodes are immutable and reversible
    class Node
      extend T::Sig

      attr_reader :type, :value, :children, :metadata

      sig { params(type: Symbol, value: T.nilable(T.any(String, Integer, Symbol, T::Boolean)), children: T.nilable(T::Array[Node]), metadata: T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol)])).void }
      def initialize(type, value: nil, children: [], metadata: {})
        @type = type
        @value = value
        @children = children.freeze
        @metadata = metadata.freeze
        freeze
      end

      # Create a new node with updated properties
      sig { params(type: T.nilable(Symbol), value: T.nilable(T.any(String, Integer, Symbol, T::Boolean)), children: T.nilable(T::Array[Node]), metadata: T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol)])).returns(Node) }
      def with(type: @type, value: @value, children: @children, metadata: @metadata)
        self.class.new(type, value: value, children: children, metadata: metadata)
      end

      # Traverse the tree depth-first
      sig { params(block: T.proc.params(node: Node).void).void }
      def traverse(&block)
        block.call(self)
        @children.each { |child| child.traverse(&block) if child.is_a?(Node) }
      end

      # Find nodes matching a condition
      sig { params(block: T.proc.returns(T::Boolean)).returns(T::Array[Node]) }
      def find_all(&block)
        results = []
        traverse do |node|
          results << node if block.call(node)
        end
        results
      end

      # Convert to hash representation
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def to_h
        {
          type: @type,
          value: @value,
          children: @children.map { |c| c.is_a?(Node) ? c.to_h : c },
          metadata: @metadata
        }
      end

      sig { returns(String) }
      def inspect
        "#<Node type=#{@type} value=#{@value.inspect} children=#{@children.length}>"
      end

      # Deep serialization for snapshots - shows actual content with depth limiting
      sig { params(depth: T.nilable(Integer), max_depth: T.nilable(Integer)).returns(String) }
      def to_detailed_string(depth = 0, max_depth = 3)
        return '...' if depth > max_depth

        indent = '  ' * depth
        result = "#{indent}#<Node type=#{@type}"

        result += " value=#{@value.inspect}" if @value

        if @children.any?
          result += " children=#{@children.length}>"
          @children.each do |child|
            result += if child.is_a?(Node)
                        "\n#{child.to_detailed_string(depth + 1, max_depth)}"
                      else
                        "\n#{indent}  #{child.inspect}"
                      end
          end
        else
          result += '>'
        end

        result
      end

      # Convert to JSON format for snapshots
      sig { params(_args: T.untyped).returns(String) }
      def to_json(*_args)
        # Handle infinity values that can't be serialized to JSON
        hash = to_h
        JSON.pretty_generate(sanitize_for_json(hash))
      end

      private

      def sanitize_for_json(obj)
        case obj
        when Hash
          obj.transform_values { |v| sanitize_for_json(v) }
        when Array
          obj.map { |v| sanitize_for_json(v) }
        when Float
          if obj.infinite?
            obj.positive? ? 'Infinity' : '-Infinity'
          else
            obj
          end
        else
          obj
        end
      end
    end
  end
end
