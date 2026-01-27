# frozen_string_literal: true

require 'json'

module WireGram
  module Languages
    module Ucl
      # Universal Object Model (UOM) for normalized UCL representation
      class UOM
        # Represents a configuration section in UCL
        class Section
          attr_accessor :name, :items

          def initialize(name = nil)
            @name = name
            @items = []
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return '...' if depth > max_depth

            indent = '  ' * depth
            result = "#{indent}#<WireGram::Languages::Ucl::UOM::Section:0xXXXXXXXX @name=#{@name.inspect}, @items=#{@items.length}>"

            if @items.any?
              @items.each do |item|
                if item.is_a?(Assignment)
                  result += "\n#{indent}  #<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{item.key.inspect}, @priority=#{item.priority.inspect}>"
                  result += "\n#{item.value.to_detailed_string(depth + 2, max_depth)}" if item.value
                else
                  result += "\n#{indent}  #{item.inspect}"
                end
              end
            end

            result
          end

          # Pretty-print UOM section for snapshots
          def to_pretty_string(indent = 0)
            indent_str = '  ' * indent
            result = "#{indent_str}#<WireGram::Languages::Ucl::UOM::Section:0xXXXXXXXX @name=#{@name.inspect}, @items=#{@items.length}>"

            if @items.any?
              @items.each do |item|
                if item.is_a?(Assignment)
                  result += "\n#{indent_str}  #<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{item.key.inspect}, @priority=#{item.priority.inspect}>"
                  result += "\n#{item.value.to_pretty_string(indent + 2)}" if item.value
                else
                  result += "\n#{indent_str}  #{item.inspect}"
                end
              end
            end

            result
          end

          # Convert UOM section to JSON format
          def to_json(*_args)
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

          # Simplified JSON format for snapshots - grouped key => values arrays
          def to_simple_json
            grouped = {}

            @items.each do |item|
              next unless item.is_a?(Assignment)

              key = item.key
              val = item.value

              grouped[key] ||= []

              grouped[key] << if val.is_a?(Value)
                                case val.type
                                when :string
                                  val.value
                                when :number
                                  # Convert string numbers to numeric types
                                  if val.value.include?('.') || val.value.include?('e') || val.value.include?('E')
                                    val.value.to_f
                                  else
                                    val.value.to_i
                                  end
                                when :boolean
                                  val.value
                                when :null
                                  nil
                                else
                                  val.value
                                end
                              elsif val.respond_to?(:to_simple_json)
                                val.to_simple_json
                              else
                                val.to_s
                              end
            end

            # Unwrap single-value arrays like UOM#to_simple_json
            result = {}
            grouped.each do |k, values|
              result[k] = values.length == 1 ? values[0] : values
            end
            result
          end

          # Pretty JSON for snapshots
          def to_pretty_json
            JSON.pretty_generate(to_simple_json, indent: '  ')
          end
        end

        # Represents a key-value assignment in UCL
        class Assignment
          attr_accessor :key, :value, :priority, :seq

          def initialize(key, value, priority = nil, seq = nil)
            @key = key
            @value = value
            @priority = priority
            @seq = seq
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return '...' if depth > max_depth

            indent = '  ' * depth
            result = "#{indent}#<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{@key.inspect}, @priority=#{@priority.inspect}>"

            result += "\n#{@value.to_detailed_string(depth + 1, max_depth)}" if @value

            result
          end

          # Pretty-print UOM assignment for snapshots
          def to_pretty_string(indent = 0)
            indent_str = '  ' * indent
            result = "#{indent_str}#<WireGram::Languages::Ucl::UOM::Assignment:0xXXXXXXXX @key=#{@key.inspect}, @priority=#{@priority.inspect}>"

            result += "\n#{@value.to_pretty_string(indent + 1)}" if @value

            result
          end

          # Convert UOM assignment to JSON format
          def to_json(*_args)
            {
              type: :assignment,
              key: @key,
              priority: @priority,
              value: @value.to_json
            }
          end
        end

        # Represents an array value in UCL
        class ArrayValue
          attr_accessor :items

          def initialize(items = [])
            @items = items
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return '...' if depth > max_depth

            indent = '  ' * depth
            result = "#{indent}#<WireGram::Languages::Ucl::UOM::ArrayValue:0xXXXXXXXX @items=#{@items.length}>"

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
            indent_str = '  ' * indent
            result = "#{indent_str}#<WireGram::Languages::Ucl::UOM::ArrayValue:0xXXXXXXXX @items=#{@items.length}>"

            if @items.any?
              @items.each_with_index do |item, index|
                result += "\n#{indent_str}  [#{index}]"
                result += "\n#{item.to_pretty_string(indent + 2)}" if item
              end
            end

            result
          end

          # Convert UOM array to JSON format
          def to_json(*_args)
            {
              type: :array,
              items: @items.map(&:to_json)
            }
          end

          # Simplified JSON format for snapshots - convert each item to simple JSON
          def to_simple_json
            @items.map do |item|
              if item.respond_to?(:to_simple_json)
                item.to_simple_json
              elsif item.respond_to?(:to_json)
                item.to_json
              else
                item.to_s
              end
            end
          end

          # Pretty JSON for snapshots
          def to_pretty_json
            JSON.pretty_generate(to_json)
          end
        end

        # Represents a scalar value in UCL
        class Value
          attr_accessor :type, :value

          def initialize(type, value)
            @type = type
            @value = value
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return '...' if depth > max_depth

            indent = '  ' * depth
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
            indent_str = '  ' * indent
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
          def to_json(*_args)
            {
              type: @type,
              value: @value
            }
          end

          # Simplified JSON format for snapshots - just the value
          def to_simple_json
            case @type
            when :string
              @value
            when :number
              # Convert numeric strings to Integer or Float
              if @value.include?('.') || @value.include?('e') || @value.include?('E')
                @value.to_f
              else
                @value.to_i
              end
            when :boolean
              @value
            when :null
              nil
            else
              @value
            end
          end

          # Pretty JSON for snapshots
          def to_pretty_json
            JSON.pretty_generate(to_simple_json, indent: '  ')
          end

          private

          def escape_ucl_string(str)
            str.to_s.gsub('\\') { '\\\\' }
               .gsub('"') { '\\"' }
          end
        end

        # Build a UOM from a simple Ruby structure (Hash or Array) typically produced by JSON.parse.
        def self.from_simple_json(obj)
          u = UOM.new

          # If top-level is a single-item array with an object (common test format), use the first item
          obj = obj[0] if obj.is_a?(Array) && obj.length == 1 && obj[0].is_a?(Hash)

          if obj.is_a?(Hash)
            obj.each do |k, v|
              u.add_assignment(u.root, k.to_s, convert_value_to_uom(v))
            end
          elsif obj.is_a?(Array)
            # Convert array into a single assignment named 'items'
            arr = ArrayValue.new(obj.map { |e| convert_value_to_uom(e) })
            u.add_assignment(u.root, 'items', arr)
          else
            # For primitives, store under key 'value'
            u.add_assignment(u.root, 'value', convert_value_to_uom(obj))
          end

          u
        end

        def self.convert_value_to_uom(val)
          case val
          when Hash
            sec = Section.new(nil)
            val.each do |kk, vv|
              # Use a temporary UOM to add assignment with sorting
              temp_uom = UOM.new
              temp_uom.add_assignment(temp_uom.root, kk.to_s, convert_value_to_uom(vv))
              # Copy the assignment to our section
              sec.items.concat(temp_uom.root.items)
            end
            # Re-sort after all assignments
            sec.items.sort_by! do |item|
              item.key.to_s
            end
            sec
          when Array
            ArrayValue.new(val.map { |e| convert_value_to_uom(e) })
          when String
            Value.new(:string, val)
          when Integer, Float
            Value.new(:number, val.to_s)
          when TrueClass, FalseClass
            Value.new(:boolean, val)
          when NilClass
            Value.new(:null, nil)
          else
            Value.new(:string, val.to_s)
          end
        end

        def initialize
          @root = Section.new(nil)
        end

        attr_reader :root

        def add_assignment(section, key, value, priority = nil)
          # Maintain a sequence counter on the UOM for stable ordering
          @__assign_seq ||= 0

          # If there is an existing assignment with same key and priority rules
          existing = section.items.find { |i| i.is_a?(Assignment) && i.key == key }

          if existing && priority && existing.priority
            # Both have priority: keep the higher priority
            if priority > existing.priority
              # replace existing, retain original sequence
              section.items.map! do |itm|
                if itm == existing
                  Assignment.new(key, value, priority, existing.seq)
                else
                  itm
                end
              end
            end
          elsif existing && priority && !existing.priority
            # New one has priority, override existing (retain seq)
            section.items.map! do |itm|
              if itm == existing
                Assignment.new(key, value, priority, existing.seq)
              else
                itm
              end
            end
          elsif existing && !priority
            # No priority: append duplicate (preserve history) with new sequence
            section.items << Assignment.new(key, value, nil, @__assign_seq += 1)
          else
            # First time assignment for this key
            section.items << Assignment.new(key, value, priority, @__assign_seq += 1)
          end

          # Sort items by key and sequence for consistent output and stable ordering of duplicates
          section.items.sort_by! { |item| [item.key.to_s, item.seq || 0] }
        end

        # Render normalized string; this is where formatting rules live
        def to_normalized_string
          if @root.items.empty?
            # Top-level empty object should render as an empty object
            return '{}'
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
            next unless item.is_a?(Assignment)

            key = item.key
            value = item.value

            # Initialize array for this key if it doesn't exist
            grouped[key] ||= []

            # Convert UOM value to appropriate JSON type
            grouped[key] << case value
                            when Value
                              case value.type
                              when :string
                                value.value
                              when :number
                                # Convert string numbers to actual numbers
                                if value.value.include?('.') || value.value.include?('e') || value.value.include?('E')
                                  value.value.to_f
                                else
                                  value.value.to_i
                                end
                              when :boolean
                                value.value
                              when :null
                                nil
                              else
                                value.value
                              end
                            else
                              # Handle other types (sections, arrays, etc.)
                              if value.respond_to?(:to_simple_json)
                                value.to_simple_json
                              else
                                value.to_s
                              end
                            end
          end

          # Unwrap single-value arrays - UCL typically returns single values not wrapped
          result = {}
          grouped.each do |key, values|
            result[key] = if values.length == 1
                            values[0]
                          else
                            values
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
              { key: item.key, priority: item.priority, value: value, seq: (item.seq if item.respond_to?(:seq)) }
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
              item.value.items

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

        def render_value(val, indent = 0)
          indent_str = '    ' * indent

          # Handle nested UOM types
          if val.is_a?(Section)
            inner = render_section(val, indent + 1)
            # Represent as a block
            "{\n#{inner}\n#{indent_str}}"
          elsif val.is_a?(ArrayValue)
            arr_lines = []
            arr_lines << '['
            val.items.each do |item|
              item_lines = render_value(item, indent + 1).lines.map(&:chomp)
              item_lines.each_with_index do |line, i|
                suffix = i == item_lines.length - 1 ? ',' : ''
                arr_lines << "#{indent_str}    #{line}#{suffix}"
              end
            end
            arr_lines << "#{indent_str}]"
            arr_lines.join("\n")
          elsif defined?(Value) && val.is_a?(Value)
            case val.type
            when :string
              quote_string(val.value)
            when :number
              # For numbers, check if they need formatting
              # Keep scientific notation as-is
              num_str = val.value.to_s
              if num_str.include?('e') || num_str.include?('E')
                # Scientific notation - keep as-is
                num_str
              elsif num_str.include?('.')
                # Decimal notation - format with 6 decimal places only for some cases
                parts = num_str.split('.')
                if parts.length == 2 && parts[1].length == 1
                  # One decimal place: check if it's non-zero
                  last_digit = parts[1][0].to_i
                  if last_digit.zero?
                    # Zero last digit like "1.0" - keep as-is
                    num_str
                  else
                    # Non-zero last digit like "123.2" - format to 6 places
                    float_val = num_str.to_f
                    format('%.6f', float_val)
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
              val.value ? 'true' : 'false'
            when :null
              'null'
            else
              quote_string(val.value.to_s)
            end
          else
            # Fallback - stringify
            quote_string(val.to_s)
          end
        end

        def quote_string(value)
          # Need to escape backslashes and quotes for output
          # Use gsub with block to avoid replacement string interpretation issues
          escaped = value.to_s
                         .gsub('\\') { '\\\\' }  # Escape backslashes first
                         .gsub('"') { '\\"' }    # Then escape quotes
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
