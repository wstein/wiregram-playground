# frozen_string_literal: true
require 'json'

module WireGram
  module Languages
    module Json
      # Universal Object Model for JSON
      # Represents JSON data in a normalized, language-agnostic format
      class UOM
        attr_reader :root

        def initialize(root = nil)
          @root = root
        end

        def root=(value)
          @root = value
        end

        def to_normalized_string
          return '' if @root.nil?
          @root.to_json
        end

        def to_simple_json
          return nil if @root.nil?
          @root.to_simple_json
        end

        # JSON Value base class
        class Value
          attr_reader :type, :value

          def initialize(type, value)
            @type = type
            @value = value
            freeze
          end

          def to_json
            case @type
            when :string
              "\"#{escape_json_string(@value)}\""
            when :number
              @value.to_s
            when :boolean
              @value.to_s
            when :null
              'null'
            else
              @value.to_s
            end
          end

          def to_simple_json
            case @type
            when :string, :number, :boolean, :null
              @value
            else
              @value
            end
          end

          def ==(other)
            other.is_a?(Value) && other.type == @type && other.value == @value
          end

      def inspect
        "#<#{self.class.name} #{to_h.inspect}>"
      end

          # Convert UOM value to JSON format
          def to_json_format
            {
              type: @type,
              value: @value
            }
          end

          # Pretty JSON for snapshots
          def to_pretty_json
            JSON.pretty_generate(to_simple_json, indent: '    ')
          rescue JSON::GeneratorError
            to_pretty_string
          end

      # Pretty-print UOM for snapshots
      def to_pretty_string(indent = 0)
        indent_str = "  " * indent
        case self
        when ObjectValue
          result = "#{indent_str}#<WireGram::Languages::Json::UOM::ObjectValue:0xXXXXXXXX @items=#{@items.length}>"
          if @items.any?
            @items.each do |key, value|
              result += "\n#{indent_str}  [#{key.inspect}]"
              if value
                result += "\n#{value.to_pretty_string(indent + 2)}"
              end
            end
          end
          result
        when ArrayValue
          result = "#{indent_str}#<WireGram::Languages::Json::UOM::ArrayValue:0xXXXXXXXX @items=#{@items.length}>"
          if @items.any?
            @items.each_with_index do |item, index|
              result += "\n#{indent_str}  [#{index}]"
              if item
                result += "\n#{item.to_pretty_string(indent + 2)}"
              end
            end
          end
          result
        when Value
          "#{indent_str}#<WireGram::Languages::Json::UOM::Value:0xXXXXXXXX @type=#{@type}, @value=#{@value.inspect}>"
        else
          "#{indent_str}#<#{self.class.name}:0xXXXXXXXX>"
        end
      end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return "..." if depth > max_depth

            indent = "  " * depth
            case @type
            when :string
              "#{indent}#<Json::UOM::Value type=#{@type} value=\"#{escape_json_string(@value)}\">"
            when :number, :boolean, :null
              "#{indent}#<Json::UOM::Value type=#{@type} value=#{@value.inspect}>"
            else
              "#{indent}#<Json::UOM::Value type=#{@type} value=#{@value.inspect}>"
            end
          end

          private

          def escape_json_string(str)
            str.to_s.gsub(/\\/) { '\\\\' }
                     .gsub(/"/) { '\\"' }
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
          def initialize(value)
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
        class ObjectValue
          attr_reader :items

          def initialize(items = [])
            @items = items.freeze
            freeze
          end

          def to_json
            if @items.empty?
              '{}'
            else
              pairs = @items.map do |item|
                next if item.value.nil?
                "\"#{escape_json_string(item.key)}\": #{item.value.to_json}"
              end.compact
              "{#{pairs.join(', ')}}"
            end
          end

          def to_simple_json
            result = {}
            @items.each do |item|
              next if item.value.nil?
              result[item.key] = item.value.to_simple_json
            end
            result
          end

          def ==(other)
            other.is_a?(ObjectValue) && other.items == @items
          end

          def inspect
            "#<Json::UOM::ObjectValue items=#{@items.length}>"
          end

          # Convert UOM object to JSON format
          def to_json_format
            {
              type: :object,
              items: @items.map(&:to_json_format)
            }
          end

          # Pretty JSON for snapshots (render as actual JSON data structure)
          def to_pretty_json
            JSON.pretty_generate(sanitize_for_json(to_simple_json), indent: '    ')
          rescue JSON::GeneratorError
            to_pretty_string
          end

          # Deep serialization for snapshots - shows actual content

          private

          def sanitize_for_json(obj)
            case obj
            when Hash
              obj.transform_values { |v| sanitize_for_json(v) }
            when Array
              obj.map { |v| sanitize_for_json(v) }
            when Float
              if obj.infinite?
                obj.positive? ? "Infinity" : "-Infinity"
              else
                obj
              end
            else
              obj
            end
          end
          def to_detailed_string(depth = 0, max_depth = 3)
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<Json::UOM::ObjectValue items=#{@items.length}>"

            if @items.any?
              @items.each do |item|
                result += "\n#{indent}  #<Json::UOM::ObjectItem key=\"#{escape_json_string(item.key)}\">"
                if item.value
                  result += "\n#{item.value.to_detailed_string(depth + 2, max_depth)}"
                end
              end
            end

            result
          end

          # Pretty-print UOM object for snapshots
          def to_pretty_string(indent = 0)
            indent_str = "  " * indent
            result = "#{indent_str}#<WireGram::Languages::Json::UOM::ObjectValue:0xXXXXXXXX @items=#{@items.length}>"

            if @items.any?
              @items.each do |item|
                result += "\n#{indent_str}  #<WireGram::Languages::Json::UOM::ObjectItem:0xXXXXXXXX @key=\"#{escape_json_string(item.key)}\">"
                if item.value
                  result += "\n#{item.value.to_pretty_string(indent + 2)}"
                end
              end
            end

            result
          end

          private

          def escape_json_string(str)
            str.to_s.gsub(/\\/) { '\\\\' }
                     .gsub(/"/) { '\\"' }
          end
        end

        # JSON Array
        class ArrayValue
          attr_reader :items

          def initialize(items = [])
            @items = items.freeze
            freeze
          end

          def to_json
            if @items.empty?
              '[]'
            else
              elements = @items.map(&:to_json)
              "[#{elements.join(', ')}]"
            end
          end

          def to_simple_json
            @items.map(&:to_simple_json)
          end

          def ==(other)
            other.is_a?(ArrayValue) && other.items == @items
          end

          def inspect
            "#<Json::UOM::ArrayValue items=#{@items.length}>"
          end

          # Convert UOM array to JSON format
          def to_json_format
            {
              type: :array,
              items: @items.map(&:to_json_format)
            }
          end

          # Pretty JSON for snapshots (render as actual JSON data structure)
          def to_pretty_json
            JSON.pretty_generate(sanitize_for_json(to_simple_json), indent: '    ')
          rescue JSON::GeneratorError
            to_pretty_string
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<Json::UOM::ArrayValue items=#{@items.length}>"

            if @items.any?
              @items.each_with_index do |item, index|
                result += "\n#{indent}  [#{index}]"
                if item
                  result += "\n#{item.to_detailed_string(depth + 2, max_depth)}"
                end
              end
            end

            result
          end

          # Pretty-print UOM array for snapshots
          def to_pretty_string(indent = 0)
            indent_str = "  " * indent
            result = "#{indent_str}#<WireGram::Languages::Json::UOM::ArrayValue:0xXXXXXXXX @items=#{@items.length}>"

            if @items.any?
              @items.each_with_index do |item, index|
                result += "\n#{indent_str}  [#{index}]"
                if item
                  result += "\n#{item.to_pretty_string(indent + 2)}"
                end
              end
            end

            result
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
                obj.positive? ? "Infinity" : "-Infinity"
              else
                obj
              end
            else
              obj
            end
          end
        end

        # JSON Object Item (key-value pair)
        class ObjectItem
          attr_reader :key, :value

          def initialize(key, value)
            @key = key.to_s
            @value = value
            freeze
          end

          def to_json
            "\"#{escape_json_string(@key)}\": #{@value.to_json}"
          end

          def to_simple_json
            [@key, @value.to_simple_json]
          end

          def ==(other)
            other.is_a?(ObjectItem) && other.key == @key && other.value == @value
          end

          def inspect
            "#<Json::UOM::ObjectItem key=#{@key.inspect} value=#{@value.inspect}>"
          end

          # Convert UOM object item to JSON format
          def to_json_format
            {
              type: :object_item,
              key: @key,
              value: @value.to_json_format
            }
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<Json::UOM::ObjectItem key=\"#{escape_json_string(@key)}\">"

            if @value
              result += "\n#{@value.to_detailed_string(depth + 1, max_depth)}"
            end

            result
          end

          # Pretty-print UOM object item for snapshots
          def to_pretty_string(indent = 0)
            indent_str = "  " * indent
            result = "#{indent_str}#<WireGram::Languages::Json::UOM::ObjectItem:0xXXXXXXXX @key=\"#{escape_json_string(@key)}\">"

            if @value
              result += "\n#{@value.to_pretty_string(indent + 1)}"
            end

            result
          end

          private

          def escape_json_string(str)
            str.to_s.gsub(/\\/) { '\\\\' }
                     .gsub(/"/) { '\\"' }
          end
        end
      end
    end
  end
end
