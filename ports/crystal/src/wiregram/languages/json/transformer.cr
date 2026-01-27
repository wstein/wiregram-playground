# frozen_string_literal: true

require "./uom"

module WireGram
  module Languages
    module Json
      # Transformer for JSON AST to UOM
      class Transformer
        @uom : WireGram::Languages::Json::UOM

        # Transform AST to JSON UOM (normalization ready)
        def self.transform(ast)
          uom = UOM.new
          visitor = new(uom)
          visitor.visit_value(ast)
          uom
        end

        def initialize(uom : WireGram::Languages::Json::UOM)
          @uom = uom
        end

        def visit_value(node) : UOM::ValueBase?
          return nil unless node

          case node.type
          when WireGram::Core::NodeType::Object
            items = node.children.map { |c| visit_object_item(c).as(UOM::ObjectItem | Nil) }.compact.to_a
            obj = UOM::ObjectValue.new(items)
            @uom.root = obj
            obj
          when WireGram::Core::NodeType::Array
            values_array = [] of UOM::ValueBase
            node.children.each do |c|
              v = visit_value(c)
              values_array << v if v
            end
            arr = UOM::ArrayValue.new(values_array)
            @uom.root = arr
            arr
          when WireGram::Core::NodeType::String
            val = UOM::StringValue.new(node.value.as(String))
            @uom.root = val
            val
          when WireGram::Core::NodeType::Number
            val = UOM::NumberValue.new(node.value.as(Int64 | Float64))
            @uom.root = val
            val
          when WireGram::Core::NodeType::Boolean
            val = UOM::BooleanValue.new(node.value.as(Bool))
            @uom.root = val
            val
          when WireGram::Core::NodeType::Null
            val = UOM::NullValue.new
            @uom.root = val
            val
          when WireGram::Core::NodeType::Pair
            nil  # Pair should be handled by visit_object_item, not visit_value
          else
            # Fallback for unknown node types
            val = UOM::StringValue.new(node.value.to_s)
            @uom.root = val
            val
          end
        end

        private def visit_object_item(node) : UOM::ObjectItem?
          return nil unless node && node.type == WireGram::Core::NodeType::Pair

          key_node = node.children[0]
          value_node = node.children[1]

          key = extract_key(key_node)
          value = visit_value(value_node)
          return nil unless value

          UOM::ObjectItem.new(key, value)
        end

        def extract_key(node) : String
          node.value.to_s
        end
      end
    end
  end
end
