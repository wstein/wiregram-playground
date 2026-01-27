# frozen_string_literal: true

require "json"

module WireGram
  module Languages
    module Json
      # Universal Object Model for JSON
      # Represents JSON data in a normalized, language-agnostic format
      class UOM
        alias SimpleJson = Bool | Int64 | Float64 | String | Nil | Array(SimpleJson) | Hash(String, SimpleJson)

        property root : ValueBase?

        def initialize(@root : ValueBase? = nil)
        end

        def to_normalized_string
          return "" unless @root

          @root.not_nil!.to_json_string
        end

        def to_simple_json : SimpleJson?
          return nil unless @root

          @root.not_nil!.to_simple_json
        end

        def self.pretty_json(value)
          JSON.build(indent: "  ") do |json|
            write_json(json, value)
          end
        end

        def self.write_json(json : JSON::Builder, value)
          case value
          when ValueBase
            write_json(json, value.to_simple_json)
          when Hash
            json.object do
              value.each do |k, v|
                json.field k.to_s do
                  write_json(json, v)
                end
              end
            end
          when Array
            json.array do
              value.each { |v| write_json(json, v) }
            end
          when Float64
            if value.infinite?
              json.string(value.positive? ? "Infinity" : "-Infinity")
            else
              json.scalar(value)
            end
          else
            json.scalar(value)
          end
        end

        abstract class ValueBase
          abstract def to_json_string : String
          abstract def to_simple_json : SimpleJson
          abstract def to_json_format
          abstract def to_pretty_json : String
          abstract def to_pretty_string(indent : Int32 = 0) : String
          abstract def to_detailed_string(depth : Int32 = 0, max_depth : Int32 = 3) : String

          def to_json : String
            to_json_string
          end

          def to_json(builder : JSON::Builder)
            builder.raw(to_json_string)
          end
        end

        # JSON Value base class
        class Value < ValueBase
          getter type : Symbol
          getter value : String | Int64 | Float64 | Bool | Nil

          def initialize(@type : Symbol, @value)
          end

          def to_json_string : String
            case @type
            when :string
              @value.to_s.to_json
            when :number
              number = @value
              if number.is_a?(Float64) && number.infinite?
                (number.positive? ? "Infinity" : "-Infinity").to_json
              else
                number.to_json
              end
            when :boolean
              @value.as(Bool).to_s
            when :null
              "null"
            else
              @value.to_s.to_json
            end
          end

          def ==(other)
            other.is_a?(Value) && other.type == @type && other.value == @value
          end

          def inspect : String
            "#<#{self.class.name} type=#{@type} value=#{@value.inspect}>"
          end

          # Convert UOM value to JSON format
          def to_json_format
            {
              type: @type,
              value: @value
            }
          end

          # Simple JSON - just the value (keep for backward compatibility)
          def to_simple_json : SimpleJson
            case @type
            when :string, :number, :boolean
              @value
            when :null
              nil
            else
              @value
            end
          end

          # Pretty JSON for snapshots
          def to_pretty_json : String
            UOM.pretty_json(to_simple_json)
          end

          # Pretty-print UOM for snapshots
          def to_pretty_string(indent = 0) : String
            indent_str = "  " * indent
            case @type
            when :string
              "#{indent_str}#<WireGram::Languages::Json::UOM::Value:0xXXXXXXXX @type=:string, @value=\"#{@value}\">"
            when :number, :boolean, :null
              "#{indent_str}#<WireGram::Languages::Json::UOM::Value:0xXXXXXXXX @type=#{@type}, @value=#{@value.inspect}>"
            else
              "#{indent_str}#<WireGram::Languages::Json::UOM::Value:0xXXXXXXXX @type=#{@type}, @value=#{@value.inspect}>"
            end
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3) : String
            return "..." if depth > max_depth

            indent = "  " * depth
            case @type
            when :string
              "#{indent}#<Json::UOM::Value type=#{@type} value=\"#{escape_json_string(@value.to_s)}\">"
            when :number, :boolean, :null
              "#{indent}#<Json::UOM::Value type=#{@type} value=#{@value.inspect}>"
            else
              "#{indent}#<Json::UOM::Value type=#{@type} value=#{@value.inspect}>"
            end
          end

          private def escape_json_string(str : String) : String
            str.gsub("\\", "\\\\").gsub("\"", "\\\"")
          end
        end

        # JSON String value
        class StringValue < Value
          def initialize(value)
            super(:string, value.to_s)
          end
        end

        # JSON Number value
        class NumberValue < Value
          def initialize(value : Int64 | Float64)
            super(:number, value)
          end
        end

        # JSON Boolean value
        class BooleanValue < Value
          def initialize(value)
            super(:boolean, value ? true : false)
          end
        end

        # JSON Null value
        class NullValue < Value
          def initialize
            super(:null, nil)
          end
        end

        # JSON Object (key-value pairs)
        class ObjectValue < ValueBase
          getter items : Array(ObjectItem)

          def initialize(@items : Array(ObjectItem) = [] of ObjectItem)
          end

          def to_json_string : String
            return "{}" if @items.empty?

            pairs = @items.map do |item|
              value = item.value
              next nil unless value
              "\"#{escape_json_string(item.key)}\": #{value.to_json_string}"
            end.compact
            "{#{pairs.join(", ")}}"
          end

          def to_simple_json : SimpleJson
            result = {} of String => SimpleJson
            @items.each do |item|
              value = item.value
              next unless value
              result[item.key] = value.to_simple_json
            end
            result
          end

          def ==(other)
            other.is_a?(ObjectValue) && other.items == @items
          end

          def inspect : String
            "#<Json::UOM::ObjectValue items=#{@items.size}>"
          end

          # Convert UOM object to JSON format
          def to_json_format
            {
              type: :object,
              items: @items.map(&.to_json_format)
            }
          end

          # Pretty JSON for snapshots (render as actual JSON data structure)
          def to_pretty_json : String
            UOM.pretty_json(to_simple_json)
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3) : String
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<Json::UOM::ObjectValue items=#{@items.size}>"

            if @items.any?
              @items.each do |item|
                result += "\n#{indent}  #<Json::UOM::ObjectItem key=\"#{escape_json_string(item.key)}\">"
                value = item.value
                result += "\n#{value.to_detailed_string(depth + 2, max_depth)}" if value
              end
            end

            result
          end

          # Pretty-print UOM object for snapshots
          def to_pretty_string(indent = 0) : String
            indent_str = "  " * indent
            result = "#{indent_str}#<WireGram::Languages::Json::UOM::ObjectValue:0xXXXXXXXX @items=#{@items.size}>"

            if @items.any?
              @items.each do |item|
                result += "\n#{indent_str}  #<WireGram::Languages::Json::UOM::ObjectItem:0xXXXXXXXX @key=\"#{escape_json_string(item.key)}\">"
                value = item.value
                result += "\n#{value.to_pretty_string(indent + 2)}" if value
              end
            end

            result
          end

          private def escape_json_string(str : String) : String
            str.gsub("\\", "\\\\").gsub("\"", "\\\"")
          end
        end

        # JSON Array
        class ArrayValue < ValueBase
          getter items : Array(ValueBase)

          def initialize(@items : Array(ValueBase) = [] of ValueBase)
          end

          def to_json_string : String
            return "[]" if @items.empty?

            elements = @items.map(&.to_json_string)
            "[#{elements.join(", ")}]"
          end

          def to_simple_json : SimpleJson
            items = [] of SimpleJson
            @items.each do |item|
              items << item.to_simple_json
            end
            items
          end

          def ==(other)
            other.is_a?(ArrayValue) && other.items == @items
          end

          def inspect : String
            "#<Json::UOM::ArrayValue items=#{@items.size}>"
          end

          # Convert UOM array to JSON format
          def to_json_format
            {
              type: :array,
              items: @items.map(&.to_json_format)
            }
          end

          # Pretty JSON for snapshots (render as actual JSON data structure)
          def to_pretty_json : String
            UOM.pretty_json(to_simple_json)
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3) : String
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<Json::UOM::ArrayValue items=#{@items.size}>"

            if @items.any?
              @items.each_with_index do |item, index|
                result += "\n#{indent}  [#{index}]"
                result += "\n#{item.to_detailed_string(depth + 2, max_depth)}"
              end
            end

            result
          end

          # Pretty-print UOM array for snapshots
          def to_pretty_string(indent = 0) : String
            indent_str = "  " * indent
            result = "#{indent_str}#<WireGram::Languages::Json::UOM::ArrayValue:0xXXXXXXXX @items=#{@items.size}>"

            if @items.any?
              @items.each_with_index do |item, index|
                result += "\n#{indent_str}  [#{index}]"
                result += "\n#{item.to_pretty_string(indent + 2)}"
              end
            end

            result
          end
        end

        # JSON Object Item (key-value pair)
        class ObjectItem
          getter key : String
          getter value : ValueBase?

          def initialize(key, value : ValueBase?)
            @key = key.to_s
            @value = value
          end

          def to_json_string : String
            value = @value
            return "\"#{escape_json_string(@key)}\": null" unless value

            "\"#{escape_json_string(@key)}\": #{value.to_json_string}"
          end

          def to_json : String
            to_json_string
          end

          def to_simple_json
            value = @value
            return [@key, nil] unless value

            [@key, value.to_simple_json]
          end

          def ==(other)
            other.is_a?(ObjectItem) && other.key == @key && other.value == @value
          end

          def inspect : String
            "#<Json::UOM::ObjectItem key=#{@key.inspect} value=#{@value.inspect}>"
          end

          # Convert UOM object item to JSON format
          def to_json_format
            {
              type: :object_item,
              key: @key,
              value: @value ? @value.not_nil!.to_json_format : nil
            }
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3) : String
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<Json::UOM::ObjectItem key=\"#{escape_json_string(@key)}\">"

            value = @value
            result += "\n#{value.to_detailed_string(depth + 1, max_depth)}" if value

            result
          end

          # Pretty-print UOM object item for snapshots
          def to_pretty_string(indent = 0) : String
            indent_str = "  " * indent
            result = "#{indent_str}#<WireGram::Languages::Json::UOM::ObjectItem:0xXXXXXXXX @key=\"#{escape_json_string(@key)}\">"

            value = @value
            result += "\n#{value.to_pretty_string(indent + 1)}" if value

            result
          end

          private def escape_json_string(str : String) : String
            str.gsub("\\", "\\\\").gsub("\"", "\\\"")
          end
        end
      end
    end
  end
end
