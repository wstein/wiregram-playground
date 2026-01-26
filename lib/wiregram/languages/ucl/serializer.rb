# frozen_string_literal: true

module WireGram
  module Languages
    module Ucl
      # Serializer for UCL output
      module Serializer
        module_function

        def escape_string(str)
          # Use double-quoted strings in canonical output and escape control chars
          str = str.to_s
          # Double backslashes first (use block to avoid gsub replacement escaping pitfalls)
          str = str.gsub('\\') { '\\\\' }
          str = str.gsub('"', '\\"')
          str = str.gsub("\n", '\\n')
          str = str.gsub("\r", '\\r')
          str = str.gsub("\t", '\\t')
          str = str.gsub("\b", '\\b')
          str = str.gsub("\f", '\\f')
          str.gsub("\0", '\\0')
          # Leave other UTF-8 chars as-is
        end

        def indent_str(level)
          ' ' * level
        end

        def format_pair_inline(pair_node, indent = 0, override_key = nil)
          key_node = pair_node.children[0]
          val_node = pair_node.children[1]
          # canonicalize key to lowercase for normalized output
          key_text = override_key || key_node.value.to_s.downcase

          if val_node && %i[object array].include?(val_node.type)
            # object- or array-valued pair prints as: key { ... } or key [ ... ]
            inner = format_value(val_node, indent)
            "#{indent_str(indent)}#{key_text} #{inner}"
          else
            "#{indent_str(indent)}#{key_text} = #{format_value(val_node, indent)};"
          end
        end

        def format_value(node, indent = 0)
          return 'null' if node.nil? || node.type == :null

          case node.type
          when :string
            # If this string came from a heredoc, emit <<DELIM style
            if node.metadata && node.metadata[:multiline] && (delim = node.metadata[:heredoc])
              # Ensure the content ends with a newline so closing delimiter sits on its own line
              content = node.value.to_s
              content += "\n" unless content.end_with?("\n")
              "<<#{delim}\n#{content}#{delim}"
            else
              "\"#{escape_string(node.value.to_s)}\""
            end
          when :number
            if node.value.is_a?(Integer)
              node.value.to_s
            elsif node.value.is_a?(Float)
              # special-case formatting for certain unit-derived floats
              if node.metadata && node.metadata[:unit]
                case node.metadata[:unit]
                when 'ms'
                  # format with fixed 6 decimals for millisecond conversions
                  format('%.6f', node.value)
                else
                  # Preserve a single decimal for floats that are integer-valued (1.0)
                  if node.value == node.value.to_i
                    format('%.1f', node.value)
                  else
                    format('%.15g', node.value)
                  end
                end
              elsif node.value == node.value.to_i
                # Preserve a single decimal for floats that are integer-valued (1.0)
                format('%.1f', node.value)
              else
                format('%.15g', node.value)
              end
            else
              node.value.to_s
            end
          when :boolean
            node.value ? 'true' : 'false'
          when :array
            if node.children.empty?
              '[]'
            else
              items = node.children.map do |c|
                formatted = format_value(c, indent + 4)
                "#{indent_str(indent + 4)}#{formatted},"
              end
              "[\n#{items.join("\n")}\n#{indent_str(indent)}]"
            end
          when :object
            if node.children.empty?
              "{\n#{indent_str(indent)} }"
            else
              inner = node.children.map do |p|
                format_pair_inline(p, indent + 4)
              end
              "{\n#{inner.join("\n")}\n#{indent_str(indent)}}"
            end
          else
            # fallback
            node.value.nil? ? '' : node.value.to_s
          end
        end

        def serialize_program(node)
          lines = []

          pair_index = 0

          node.children.each do |child|
            case child.type
            when :pair
              pair_index += 1
              lines << format_pair_inline(child, 0)
            when :object
              # if an object is a direct child (top-level brace), print its members
              child.children.each do |p|
                lines << format_pair_inline(p, 0)
              end
            else
              # unknown child types: attempt to stringify
              lines << (child.value ? child.value.to_s : '')
            end
          end

          out = lines.join("\n")
          out += "\n\n" unless out.end_with?("\n\n")

          # Ensure the output is valid UTF-8 (replace invalid/undef bytes)
          begin
            out.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
          rescue StandardError
            out
          end
        end

        # Format a UOM hash (produced by Parser.uom_from_ast) into canonical textual form
        def format_uom(uom)
          return "{}\n" unless uom && (uom[:type] || uom['type'])

          children = uom[:children] || uom['children'] || []
          lines = []

          children.each do |child|
            next unless child && (child[:type] || child['type']).to_s == 'pair'

            key = child[:key] || child['key']
            val = child[:value] || child['value']

            val_str = format_uom_value(val)
            lines << "  \"#{key}\": #{val_str};"
          end

          "{\n#{lines.join("\n")}\n}\n"
        end

        def format_uom_value(val)
          return 'null' if val.nil?

          t = (val[:type] || val['type']).to_s
          v = val[:value] || val['value']

          case t
          when 'string'
            "\"#{escape_string(v.to_s)}\""
          when 'number'
            if v.is_a?(Integer)
              v.to_s
            elsif v.is_a?(Float)
              if v == v.to_i
                format('%.1f', v)
              else
                format('%.15g', v)
              end
            else
              v.to_s
            end
          when 'boolean'
            v ? 'true' : 'false'
          when 'array'
            # basic array formatting
            if (items = val[:items] || val['items']).nil? || items.empty?
              '[]'
            else
              inner = items.map { |it| "  #{format_uom_value(it)}" }
              "[\n#{inner.join("\n")}\n]"
            end
          when 'object'
            # Not fully supported; fallback to {}
            '{ }'
          else
            v.to_s
          end
        end
      end
    end
  end
end
