# frozen_string_literal: true

module WireGram
  module Languages
    module Ucl
      # Serializer for UCL output
      module Serializer
        def self.escape_string(str : String)
          # Use double-quoted strings in canonical output and escape control chars
          out = str
          out = out.gsub("\\") { "\\\\" }
          out = out.gsub("\"", "\\\"")
          out = out.gsub("\n", "\\n")
          out = out.gsub("\r", "\\r")
          out = out.gsub("\t", "\\t")
          out = out.gsub("\b", "\\b")
          out = out.gsub("\f", "\\f")
          out.gsub("\0", "\\0")
        end

        def self.indent_str(level : Int32)
          " " * level
        end

        def self.format_pair_inline(pair_node, indent = 0, override_key = nil)
          key_node = pair_node.children[0]
          val_node = pair_node.children[1]
          # canonicalize key to lowercase for normalized output
          key_text = override_key || key_node.value.to_s.downcase

          if val_node && [WireGram::Core::NodeType::Object, WireGram::Core::NodeType::Array].includes?(val_node.type)
            # object- or array-valued pair prints as: key { ... } or key [ ... ]
            inner = format_value(val_node, indent)
            "#{indent_str(indent)}#{key_text} #{inner}"
          else
            "#{indent_str(indent)}#{key_text} = #{format_value(val_node, indent)};"
          end
        end

        def self.format_value(node, indent = 0)
          return "null" if node.nil? || node.type == WireGram::Core::NodeType::Null

          case node.type
          when WireGram::Core::NodeType::String
            if (md = node.metadata) && md[:multiline]? && (delim = md[:heredoc]?)
              content = node.value.to_s
              content += "\n" unless content.ends_with?("\n")
              "<<#{delim}\n#{content}#{delim}"
            else
              "\"#{escape_string(node.value.to_s)}\""
            end
          when WireGram::Core::NodeType::Number
            if node.value.is_a?(Int64)
              node.value.to_s
            elsif node.value.is_a?(Float64)
              if (md = node.metadata) && (unit = md[:unit]?)
                case unit.to_s
                when "ms"
                  format("%.6f", node.value.as(Float64))
                else
                  if node.value.as(Float64) == node.value.as(Float64).to_i
                    format("%.1f", node.value.as(Float64))
                  else
                    format("%.15g", node.value.as(Float64))
                  end
                end
              elsif node.value.as(Float64) == node.value.as(Float64).to_i
                format("%.1f", node.value.as(Float64))
              else
                format("%.15g", node.value.as(Float64))
              end
            else
              node.value.to_s
            end
          when WireGram::Core::NodeType::Boolean
            node.value.as(Bool) ? "true" : "false"
          when WireGram::Core::NodeType::Array
            if node.children.empty?
              "[]"
            else
              items = node.children.map do |c|
                formatted = format_value(c, indent + 4)
                "#{indent_str(indent + 4)}#{formatted},"
              end
              "[\n#{items.join("\n")}\n#{indent_str(indent)}]"
            end
          when WireGram::Core::NodeType::Object
            if node.children.empty?
              "{\n#{indent_str(indent)} }"
            else
              inner = node.children.map do |p|
                format_pair_inline(p, indent + 4)
              end
              "{\n#{inner.join("\n")}\n#{indent_str(indent)}}"
            end
          else
            node.value.nil? ? "" : node.value.to_s
          end
        end

        def self.serialize_program(node, renumber : Bool = false)
          lines = [] of String

          pair_index = 0

          node.children.each do |child|
            case child.type
            when WireGram::Core::NodeType::Pair
              pair_index += 1
              lines << format_pair_inline(child, 0)
            when WireGram::Core::NodeType::Object
              # if an object is a direct child (top-level brace), print its members
              child.children.each do |p|
                lines << format_pair_inline(p, 0)
              end
            else
              lines << (child.value ? child.value.to_s : "")
            end
          end

          out = lines.join("\n")
          out += "\n\n" unless out.ends_with?("\n\n")
          out
        end
      end
    end
  end
end
