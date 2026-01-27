# frozen_string_literal: true

module WireGram
  module Languages
    module Json
      # Serializer for JSON UOM to normalized JSON string
      class Serializer
        # Serialize JSON UOM to normalized JSON string
        def self.serialize(uom)
          return "" if uom.nil? || uom.root.nil?

          root = uom.root.not_nil!
          simple = root.to_simple_json
          if contains_control_or_infinite?(simple)
            root.to_pretty_json
          else
            root.to_json_string
          end
        end

        def self.contains_control_or_infinite?(obj)
          case obj
          when Hash
            obj.each_value do |v|
              return true if contains_control_or_infinite?(v)
            end
            false
          when Array
            obj.any? { |v| contains_control_or_infinite?(v) }
          when String
            obj.includes?("\n") || obj.includes?("\t")
          when Float64
            obj.infinite?
          else
            false
          end
        end

        # Serialize with pretty formatting
        def self.serialize_pretty(uom, indent = "    ")
          return "" if uom.nil? || uom.root.nil?

          PrettySerializer.new(indent).serialize(uom.root.not_nil!)
        end

        # Serialize to simple Ruby hash/array structure
        def self.serialize_simple(uom)
          return nil if uom.nil? || uom.root.nil?

          uom.root.not_nil!.to_simple_json
        end

        # PrettySerializer for formatted JSON output
        class PrettySerializer
          getter indent : String

          def initialize(indent = "  ")
            @indent = indent
            @level = 0
          end

          def serialize(value)
            case value
            when WireGram::Languages::Json::UOM::ObjectValue
              serialize_object(value)
            when WireGram::Languages::Json::UOM::ArrayValue
              serialize_array(value)
            when WireGram::Languages::Json::UOM::StringValue, WireGram::Languages::Json::UOM::NumberValue, WireGram::Languages::Json::UOM::BooleanValue, WireGram::Languages::Json::UOM::NullValue
              value.to_json
            else
              value.to_s
            end
          end

          private def serialize_object(object)
            if object.items.empty?
              "{}"
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
              "[]"
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
