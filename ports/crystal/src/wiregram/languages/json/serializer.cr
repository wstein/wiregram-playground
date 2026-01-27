# frozen_string_literal: true

module WireGram
  module Languages
    module Json
      # Serializer for JSON UOM to normalized JSON string
      class Serializer
        # Serialize JSON UOM to normalized JSON string
        def self.serialize(uom)
          return '' if uom.nil? || uom.root.nil?

          # If the data contains control characters (newlines/tabs) or infinite floats,
          # prefer pretty-printed JSON (matching UOM pretty output used in snapshots).
          simple = uom.root.to_simple_json
          if contains_control_or_infinite?(simple)
            # Use UOM's pretty JSON generator which also sanitizes infinite floats
            uom.root.to_pretty_json
          else
            uom.root.to_json
          end
        end

        def self.contains_control_or_infinite?(obj)
          case obj
          when Hash
            obj.values.any? { |v| contains_control_or_infinite?(v) }
          when Array
            obj.any? { |v| contains_control_or_infinite?(v) }
          when String
            obj.include?("\n") || obj.include?("\t")
          when Float
            obj.infinite?
          else
            false
          end
        end

        # Serialize with pretty formatting
        def self.serialize_pretty(uom, indent = '    ')
          return '' if uom.nil? || uom.root.nil?

          PrettySerializer.new(indent).serialize(uom.root)
        end

        # Serialize to simple Ruby hash/array structure
        def self.serialize_simple(uom)
          return nil if uom.nil? || uom.root.nil?

          uom.root.to_simple_json
        end

        # PrettySerializer for formatted JSON output
        class PrettySerializer
          attr_reader :indent

          def initialize(indent = '  ')
            @indent = indent
            @level = 0
          end

          def serialize(value)
            case value
            when UOM::ObjectValue
              serialize_object(value)
            when UOM::ArrayValue
              serialize_array(value)
            when UOM::StringValue, UOM::NumberValue, UOM::BooleanValue, UOM::NullValue
              value.to_json
            else
              value.to_s
            end
          end

          private

          def serialize_object(object)
            if object.items.empty?
              '{}'
            else
              @level += 1
              current_indent = @indent * @level
              next_indent = @indent * (@level + 1)

              pairs = object.items.map do |item|
                "#{next_indent}#{item.to_json}"
              end

              result = "{\n#{pairs.join(",\n")}\n#{current_indent}}"
              @level -= 1
              result
            end
          end

          def serialize_array(array)
            if array.items.empty?
              '[]'
            else
              @level += 1
              current_indent = @indent * @level
              next_indent = @indent * (@level + 1)

              elements = array.items.map do |item|
                "#{next_indent}#{item.to_json}"
              end

              result = "[\n#{elements.join(",\n")}\n#{current_indent}]"
              @level -= 1
              result
            end
          end
        end
      end
    end
  end
end
