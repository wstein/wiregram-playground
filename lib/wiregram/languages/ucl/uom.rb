# frozen_string_literal: true
require 'json'

module WireGram
  module Languages
    module Ucl
      # Universal Object Model (UOM) for normalized UCL representation
      class UOM
        class Section
          attr_accessor :name, :items

          def initialize(name = nil)
            @name = name
            @items = []
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<WireGram::Languages::Ucl::UOM::Section:0xXXXXXXXX @name=#{@name.inspect}, @items=#{@items.length}>"

            if @items.any?
              @items.each do |item|
                if item.is_a?(Assignment)
                  result += "\n#{indent}  #<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{item.key.inspect}, @priority=#{item.priority.inspect}>"
                  if item.value
                    result += "\n#{item.value.to_detailed_string(depth + 2, max_depth)}"
                  end
                else
                  result += "\n#{indent}  #{item.inspect}"
                end
              end
            end

            result
          end

          # Pretty-print UOM section for snapshots
          def to_pretty_string(indent = 0)
            indent_str = "  " * indent
            result = "#{indent_str}#<WireGram::Languages::Ucl::UOM::Section:0xXXXXXXXX @name=#{@name.inspect}, @items=#{@items.length}>"

            if @items.any?
              @items.each do |item|
                if item.is_a?(Assignment)
                  result += "\n#{indent_str}  #<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{item.key.inspect}, @priority=#{item.priority.inspect}>"
                  if item.value
                    result += "\n#{item.value.to_pretty_string(indent + 2)}"
                  end
                else
                  result += "\n#{indent_str}  #{item.inspect}"
                end
              end
            end

            result
          end

          # Convert UOM section to JSON format
          def to_json
            {
              type: :section,
              name: @name,
              items: @items.map do |item|
                if item.is_a?(Assignment)
                  {
                    type: :assignment,
                    key: item.key,
                    priority: item.priority,
                    value: item.value.to_json
                  }
                else
                  item.to_json
                end
              end
            }
          end

          # Simplified JSON format for snapshots - just key-value pairs
          def to_simple_json
            result = {}
            @items.each do |item|
              if item.is_a?(Assignment)
                result[item.key] = item.value.to_simple_json
              end
            end
            result
          end

          # Pretty JSON for snapshots
          def to_pretty_json
            JSON.pretty_generate(to_simple_json, indent: "    ")
          end
        end

        class Assignment
          attr_accessor :key, :value, :priority

          def initialize(key, value, priority = nil)
            @key = key
            @value = value
            @priority = priority
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{@key.inspect}, @priority=#{@priority.inspect}>"

            if @value
              result += "\n#{@value.to_detailed_string(depth + 1, max_depth)}"
            end

            result
          end

          # Pretty-print UOM assignment for snapshots
          def to_pretty_string(indent = 0)
            indent_str = "  " * indent
            result = "#{indent_str}#<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{@key.inspect}, @priority=#{@priority.inspect}>"

            if @value
              result += "\n#{@value.to_pretty_string(indent + 1)}"
            end

            result
          end

          # Convert UOM assignment to JSON format
          def to_json
            {
              type: :assignment,
              key: @key,
              priority: @priority,
              value: @value.to_json
            }
          end
        end

        class ArrayValue
          attr_accessor :items

          def initialize(items = [])
            @items = items
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return "..." if depth > max_depth

            indent = "  " * depth
            result = "#{indent}#<WireGram::Languages::Ucl::UOM::ArrayValue:0xXXXXXXXX @items=#{@items.length}>"

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
            result = "#{indent_str}#<WireGram::Languages::Ucl::UOM::ArrayValue:0xXXXXXXXX @items=#{@items.length}>"

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

          # Convert UOM array to JSON format
          def to_json
            {
              type: :array,
              items: @items.map(&:to_json)
            }
          end

          # Pretty JSON for snapshots
          def to_pretty_json
            JSON.pretty_generate(to_json)
          end
        end

        class Value
          attr_accessor :type, :value

          def initialize(type, value)
            @type = type
            @value = value
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

          # Convert UOM value to JSON format
          def to_json
            {
              type: @type,
              value: @value
            }
          end

          # Simplified JSON format for snapshots - just the value
          def to_simple_json
            case @type
            when :string, :number, :boolean, :null
              @value
            else
              @value
            end
          end

          # Pretty JSON for snapshots
          def to_pretty_json
            JSON.pretty_generate(to_simple_json)
          end

          private

          def escape_ucl_string(str)
            str.to_s.gsub(/\\/) { '\\\\' }
                     .gsub(/"/) { '\\"' }
          end
        end

        def initialize
          @root = Section.new(nil)
        end

        def root
          @root
        end

        def add_assignment(section, key, value, priority = nil)
          # If there is an existing assignment with same key and priority rules
          existing = section.items.find { |i| i.is_a?(Assignment) && i.key == key }

          if existing && priority && existing.priority
            # Both have priority: keep the higher priority
            if priority > existing.priority
              # replace existing
              section.items.map! do |itm|
                if itm == existing
                  Assignment.new(key, value, priority)
                else
                  itm
                end
              end
            else
              # keep existing
            end
          elsif existing && priority && !existing.priority
            # New one has priority, override existing
            section.items.map! do |itm|
              if itm == existing
                Assignment.new(key, value, priority)
              else
                itm
              end
            end
          elsif existing && !priority
            # No priority: append duplicate (preserve history)
            section.items << Assignment.new(key, value, nil)
          else
            section.items << Assignment.new(key, value, priority)
          end

          # Sort items by key for consistent output
          section.items.sort_by! { |item| item.key.to_s }
        end

        # Render normalized string; this is where formatting rules live
        def to_normalized_string
          if @root.items.empty?
            # Top-level empty object should render as an empty object
            return "{}"
          end

          render_section(@root, 0).strip
        end

        # Export UOM as a Hash for debugging / JSON serialization
        def to_h
          { root: section_to_h(@root) }
        end

        # Export UOM as simplified JSON format (grouped by key)
        def to_simple_json
          grouped = {}

          # Collect all assignments from root section
          @root.items.each do |item|
            if item.is_a?(Assignment)
              key = item.key
              value = item.value

              # Initialize array for this key if it doesn't exist
              grouped[key] ||= []

              # Convert UOM value to appropriate JSON type
              case value
              when Value
                case value.type
                when :string
                  grouped[key] << value.value
                when :number
                  # Convert string numbers to actual numbers
                  if value.value.include?('.') || value.value.include?('e') || value.value.include?('E')
                    grouped[key] << value.value.to_f
                  else
                    grouped[key] << value.value.to_i
                  end
                when :boolean
                  grouped[key] << value.value
                when :null
                  grouped[key] << nil
                else
                  grouped[key] << value.value
                end
              else
                # Handle other types (sections, arrays, etc.)
                grouped[key] << value.to_s
              end
            end
          end

          # Unwrap single-value arrays - UCL typically returns single values not wrapped
          result = {}
          grouped.each do |key, values|
            if values.length == 1
              result[key] = values[0]
            else
              result[key] = values
            end
          end
          result
        end

        def section_to_h(section)
          section.items.map do |item|
            if item.is_a?(Assignment)
              value = case item.value
                      when Section
                        { section: section_to_h(item.value) }
                      when ArrayValue
                        { array: item.value.items.map { |v| { type: v.type, value: v.value } } }
                      when Value
                        { type: item.value.type, value: item.value.value }
                      else
                        item.value
                      end
              { key: item.key, priority: item.priority, value: value }
            else
              { node: item }
            end
          end
        end

        private

        def render_section(section, indent)
          indent_str = '    ' * indent
          lines = []

          section.items.each do |item|
            if item.value.is_a?(Section)
              # Named subsection
              inner = render_section(item.value, indent + 1)
              if inner.strip.empty?
                # empty section: render compactly
                lines << "#{indent_str}#{item.key} {\n#{indent_str}}"
              else
                lines << "#{indent_str}#{item.key} {"
                lines << inner
                lines << "#{indent_str}}"
              end
            elsif item.value.is_a?(ArrayValue)
              values = item.value.items

              # libucl CONFIG format always uses multi-line block arrays with trailing commas
              lines << "#{indent_str}#{item.key} ["
              item.value.items.each do |v|
                lines << "#{indent_str}    #{render_value(v)},"
              end
              lines << "#{indent_str}]"

            else
              lines << "#{indent_str}#{item.key} = #{render_value(item.value)};"
            end
          end

          lines.join("\n")
        end

        def render_value(v)
          case v.type
          when :string
            quote_string(v.value)
          when :number
            # For numbers, check if they need formatting
            # Keep scientific notation as-is
            num_str = v.value.to_s
            if num_str.include?('e') || num_str.include?('E')
              # Scientific notation - keep as-is
              num_str
            elsif num_str.include?('.')
              # Decimal notation - format with 6 decimal places only for some cases
              parts = num_str.split('.')
              if parts.length == 2 && parts[1].length == 1
                # One decimal place: check if it's non-zero
                last_digit = parts[1][0].to_i
                if last_digit != 0
                  # Non-zero last digit like "123.2" - format to 6 places
                  float_val = num_str.to_f
                  sprintf("%.6f", float_val)
                else
                  # Zero last digit like "1.0" - keep as-is
                  num_str
                end
              else
                # Other decimal formats - keep as-is
                num_str
              end
            else
              # Integer
              num_str
            end
          when :boolean
            v.value ? 'true' : 'false'
          when :null
            'null'
          else
            quote_string(v.value.to_s)
          end
        end

        def quote_string(value)
          # Need to escape backslashes and quotes for output
          # Use gsub with block to avoid replacement string interpretation issues
          escaped = value.to_s
            .gsub(/\\/) { '\\\\' }  # Escape backslashes first
            .gsub(/"/) { '\\"' }    # Then escape quotes
            .gsub("\n", '\\n')      # Use string literals for control chars
            .gsub("\r", '\\r')
            .gsub("\t", '\\t')
            .gsub("\b", '\\b')      # backspace character
            .gsub("\f", '\\f')
          "\"#{escaped}\""
        end
      end
    end
  end
end
