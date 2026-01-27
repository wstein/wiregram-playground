# frozen_string_literal: true

require "json"

module WireGram
  module Languages
    module Ucl
      # Universal Object Model (UOM) for normalized UCL representation
      class UOM
        struct RawNumber
          getter raw : String

          def initialize(@raw : String)
          end

          def to_json(builder : JSON::Builder)
            builder.raw(@raw)
          end
        end

        alias JsonValue = String | Int32 | Int64 | Float64 | Bool | Nil | RawNumber | Array(JsonValue) | Hash(String, JsonValue)
        alias UomValue = Value | Section | ArrayValue

        # Represents a configuration section in UCL
        class Section
          property name : String?
          property items : Array(Assignment)

          def initialize(@name : String? = nil)
            @items = [] of Assignment
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<WireGram::Languages::Ucl::UOM::Section:0xXXXXXXXX @name=#{@name.inspect}, @items=#{@items.size}>"

            if @items.any?
              @items.each do |item|
                result += "\n#{indent}  #<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{item.key.inspect}, @priority=#{item.priority.inspect}>"
                result += "\n#{item.value.to_detailed_string(depth + 2, max_depth)}" if item.value
              end
            end

            result
          end

          # Pretty-print UOM section for snapshots
          def to_pretty_string(indent = 0)
            indent_str = "  " * indent
            result = "#{indent_str}#<WireGram::Languages::Ucl::UOM::Section:0xXXXXXXXX @name=#{@name.inspect}, @items=#{@items.size}>"

            if @items.any?
              @items.each do |item|
                result += "\n#{indent_str}  #<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{item.key.inspect}, @priority=#{item.priority.inspect}>"
                result += "\n#{item.value.to_pretty_string(indent + 2)}" if item.value
              end
            end

            result
          end

          # Convert UOM section to JSON format
          def to_json(builder : JSON::Builder)
            builder.object do
              builder.field "type", "section"
              builder.field "name", @name
              builder.field "items" do
                builder.array do
                  @items.each do |item|
                    item.to_json(builder)
                  end
                end
              end
            end
          end

          # Simplified JSON format for snapshots - grouped key => values arrays
          def to_simple_json : Hash(String, JsonValue)
            grouped = {} of String => Array(JsonValue)

            @items.each do |item|
              key = item.key
              val = item.value

              grouped[key] ||= [] of JsonValue

              grouped[key] << case val
                              when Value
                                val.to_simple_json
                              when Section
                                val.to_simple_json
                              when ArrayValue
                                val.to_simple_json
                              else
                                val.to_s
                              end
            end

            result = {} of String => JsonValue
            grouped.each do |k, values|
              result[k] = values.size == 1 ? values[0] : values
            end
            result
          end

          # Pretty JSON for snapshots
          def to_pretty_json
            UOM.pretty_json(to_simple_json)
          end
        end

        # Represents a key-value assignment in UCL
        class Assignment
          property key : String
          property value : UomValue
          property priority : Int32?
          property seq : Int32?

          def initialize(@key : String, @value : UomValue, @priority : Int32? = nil, @seq : Int32? = nil)
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{@key.inspect}, @priority=#{@priority.inspect}>"
            result += "\n#{@value.to_detailed_string(depth + 1, max_depth)}" if @value
            result
          end

          # Pretty-print UOM assignment for snapshots
          def to_pretty_string(indent = 0)
            indent_str = "  " * indent
            result = "#{indent_str}#<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{@key.inspect}, @priority=#{@priority.inspect}>"
            result += "\n#{@value.to_pretty_string(indent + 1)}" if @value
            result
          end

          # Convert UOM assignment to JSON format
          def to_json(builder : JSON::Builder)
            builder.object do
              builder.field "type", "assignment"
              builder.field "key", @key
              builder.field "priority", @priority
              builder.field "value" do
                @value.to_json(builder)
              end
            end
          end
        end

        # Represents an array value in UCL
        class ArrayValue
          property items : Array(UomValue)

          def initialize(items = [] of UomValue)
            @items = items
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<WireGram::Languages::Ucl::UOM::ArrayValue:0xXXXXXXXX @items=#{@items.size}>"

            if @items.any?
              @items.each_with_index do |item, index|
                result += "\n#{indent}  [#{index}]"
                result += "\n#{item.to_detailed_string(depth + 2, max_depth)}" if item
              end
            end

            result
          end

          # Pretty-print UOM array for snapshots
          def to_pretty_string(indent = 0)
            indent_str = "  " * indent
            result = "#{indent_str}#<WireGram::Languages::Ucl::UOM::ArrayValue:0xXXXXXXXX @items=#{@items.size}>"

            if @items.any?
              @items.each_with_index do |item, index|
                result += "\n#{indent_str}  [#{index}]"
                result += "\n#{item.to_pretty_string(indent + 2)}" if item
              end
            end

            result
          end

          # Convert UOM array to JSON format
          def to_json(builder : JSON::Builder)
            builder.object do
              builder.field "type", "array"
              builder.field "items" do
                builder.array do
                  @items.each { |item| item.to_json(builder) }
                end
              end
            end
          end

          # Simplified JSON format for snapshots - convert each item to simple JSON
          def to_simple_json : Array(JsonValue)
            items = [] of JsonValue
            @items.each do |item|
              items << item.to_simple_json
            end
            items
          end

          # Pretty JSON for snapshots
          def to_pretty_json
            UOM.pretty_json(to_simple_json)
          end
        end

        # Represents a scalar value in UCL
        class Value
          property type : Symbol
          property value : String | Bool | Nil

          def initialize(@type : Symbol, value)
            @value = case @type
                     when :string, :number
                       value.to_s
                     when :boolean
                       value ? true : false
                     else
                       nil
                     end
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return "..." if depth > max_depth

            indent = "  " * depth
            case @type
            when :string
              "#{indent}#<WireGram::Languages::Ucl::UOM::Value:0xXXXXXXXX @type=:string, @value=\"#{escape_ucl_string(@value)}\">"
            when :number, :boolean, :null
              "#{indent}#<WireGram::Languages::Ucl::UOM::Value:0xXXXXXXXX @type=#{@type}, @value=#{@value.inspect}>"
            else
              "#{indent}#<WireGram::Languages::Ucl::UOM::Value:0xXXXXXXXX @type=#{@type}, @value=#{@value.inspect}>"
            end
          end

          # Pretty-print UOM value for snapshots
          def to_pretty_string(indent = 0)
            indent_str = "  " * indent
            case @type
            when :string
              "#{indent_str}#<WireGram::Languages::Ucl::UOM::Value:0xXXXXXXXX @type=:string, @value=\"#{escape_ucl_string(@value)}\">"
            when :number, :boolean, :null
              "#{indent_str}#<WireGram::Languages::Ucl::UOM::Value:0xXXXXXXXX @type=#{@type}, @value=#{@value.inspect}>"
            else
              "#{indent_str}#<WireGram::Languages::Ucl::UOM::Value:0xXXXXXXXX @type=#{@type}, @value=#{@value.inspect}>"
            end
          end

          def to_json(builder : JSON::Builder)
            builder.object do
              builder.field "type", @type.to_s
              builder.field "value", @value
            end
          end

          # Simplified JSON format for snapshots - just the value
          def to_simple_json : JsonValue
            case @type
            when :string
              @value.to_s
            when :number
              num_str = @value.to_s
              if num_str.includes?("e") || num_str.includes?("E")
                RawNumber.new(num_str)
              elsif num_str.includes?(".")
                num_str.to_f
              else
                num_str.to_i64
              end
            when :boolean
              @value ? true : false
            when :null
              nil
            else
              @value
            end
          end

          # Pretty JSON for snapshots
          def to_pretty_json
            UOM.pretty_json(to_simple_json)
          end

          private def escape_ucl_string(str)
            str.to_s.gsub("\\") { "\\\\" }
              .gsub("\"") { "\\\"" }
          end
        end

        def initialize
          @root = Section.new(nil)
          @assign_seq = 0
        end

        getter root : Section

        def add_assignment(section : Section, key : String, value : UomValue, priority : Int32? = nil)
          @assign_seq += 1

          existing = section.items.find { |i| i.key == key }

          if existing && priority && (existing_priority = existing.priority)
            if priority > existing_priority
              section.items.map! do |itm|
                itm == existing ? Assignment.new(key, value, priority, existing.seq) : itm
              end
            end
          elsif existing && priority && !existing.priority
            section.items.map! do |itm|
              itm == existing ? Assignment.new(key, value, priority, existing.seq) : itm
            end
          elsif existing && !priority
            section.items << Assignment.new(key, value, nil, @assign_seq)
          else
            section.items << Assignment.new(key, value, priority, @assign_seq)
          end

          section.items.sort_by! { |item| {item.key, item.seq || 0} }
        end

        # Render normalized string; this is where formatting rules live
        def to_normalized_string
          return "{}" if @root.items.empty?

          render_section(@root, 0).strip
        end

        def to_simple_json
          @root.to_simple_json
        end

        def to_h
          { "root" => section_to_h(@root) }
        end

        def self.pretty_json(value)
          JSON.build(indent: "  ") do |json|
            write_json(json, value)
          end
        end

        def self.write_json(json : JSON::Builder, value : JsonValue)
          case value
          when RawNumber
            json.raw(value.raw)
          when Hash
            json.object do
              value.each do |k, v|
                json.field k do
                  write_json(json, v)
                end
              end
            end
          when Array
            json.array do
              value.each { |v| write_json(json, v) }
            end
          else
            json.scalar(value)
          end
        end

        private def section_to_h(section : Section)
          section.items.map do |item|
            value = case item.value
                    when Section
                      { "section" => section_to_h(item.value) }
                    when ArrayValue
                      { "array" => item.value.items.map { |v| { "type" => v.type.to_s, "value" => v.value } } }
                    when Value
                      { "type" => item.value.type.to_s, "value" => item.value.value }
                    else
                      item.value
                    end
            { "key" => item.key, "priority" => item.priority, "value" => value, "seq" => item.seq }
          end
        end

        def render_section(section : Section, indent : Int32)
          indent_str = "    " * indent
          lines = [] of String

          section.items.each do |item|
            value = item.value
            if value.is_a?(Section)
              inner = render_section(value, indent + 1)
              if inner.strip.empty?
                lines << "#{indent_str}#{item.key} {\n#{indent_str}}"
              else
                lines << "#{indent_str}#{item.key} {"
                lines << inner
                lines << "#{indent_str}}"
              end
            elsif value.is_a?(ArrayValue)
              lines << "#{indent_str}#{item.key} ["
              value.items.each do |v|
                lines << "#{indent_str}    #{render_value(v)},"
              end
              lines << "#{indent_str}]"
            else
              lines << "#{indent_str}#{item.key} = #{render_value(value)};"
            end
          end

          lines.join("\n")
        end

        def render_value(val, indent = 0)
          indent_str = "    " * indent

          case val
          when Section
            inner = render_section(val, indent + 1)
            "{\n#{inner}\n#{indent_str}}"
          when ArrayValue
            arr_lines = [] of String
            arr_lines << "["
            val.items.each do |item|
              item_lines = render_value(item, indent + 1).lines.map(&.chomp)
              item_lines.each_with_index do |line, idx|
                suffix = idx == item_lines.size - 1 ? "," : ""
                arr_lines << "#{indent_str}    #{line}#{suffix}"
              end
            end
            arr_lines << "#{indent_str}]"
            arr_lines.join("\n")
          when Value
            case val.type
            when :string
              quote_string(val.value.to_s)
            when :number
              num_str = val.value.to_s
              if num_str.includes?("e") || num_str.includes?("E")
                num_str
              elsif num_str.includes?(".")
                parts = num_str.split(".")
                if parts.size == 2 && parts[1].size == 1
                  last_digit = parts[1][0].to_i
                  if last_digit.zero?
                    num_str
                  else
                    float_val = num_str.to_f
                    sprintf("%.6f", float_val)
                  end
                else
                  num_str
                end
              else
                num_str
              end
            when :boolean
              val.value ? "true" : "false"
            when :null
              "null"
            else
              quote_string(val.value.to_s)
            end
          else
            quote_string(val.to_s)
          end
        end

        def quote_string(value : String)
          escaped = value
                    .gsub("\\") { "\\\\" }
                    .gsub("\"") { "\\\"" }
                    .gsub("\n", "\\n")
                    .gsub("\r", "\\r")
                    .gsub("\t", "\\t")
                    .gsub("\b", "\\b")
                    .gsub("\f", "\\f")
          "\"#{escaped}\""
        end
      end
    end
  end
end
