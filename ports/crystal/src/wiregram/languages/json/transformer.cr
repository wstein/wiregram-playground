# frozen_string_literal: true

require_relative 'uom'

module WireGram
  module Languages
    module Json
      # Transformer for JSON AST to UOM
      class Transformer
        # Transform AST to JSON UOM (normalization ready)
        def self.transform(ast)
          uom = UOM.new
          visitor = new(uom)
          visitor.visit_value(ast)
          uom
        end

        def initialize(uom)
          @uom = uom
        end

        def visit_value(node)
          return nil unless node

          case node.type
          when :object
            obj = UOM::ObjectValue.new(node.children.map { |c| visit_object_item(c) })
            @uom.root = obj
            obj
          when :array
            arr = UOM::ArrayValue.new(node.children.map { |c| visit_value(c) })
            @uom.root = arr
            arr
          when :string
            val = UOM::StringValue.new(node.value)
            @uom.root = val
            val
          when :number
            val = UOM::NumberValue.new(node.value)
            @uom.root = val
            val
          when :boolean
            val = UOM::BooleanValue.new(node.value)
            @uom.root = val
            val
          when :null
            val = UOM::NullValue.new
            @uom.root = val
            val
          when :pair
            visit_object_item(node)
          else
            # Fallback for unknown node types
            val = UOM::StringValue.new(node.value.to_s)
            @uom.root = val
            val
          end
        end

        private

        def visit_object_item(node)
          return nil unless node && node.type == :pair

          key_node = node.children[0]
          value_node = node.children[1]

          key = extract_key(key_node)
          value = visit_value(value_node)

          UOM::ObjectItem.new(key, value)
        end

        def extract_key(node)
          node.value.to_s
        end
      end
    end
  end
end
