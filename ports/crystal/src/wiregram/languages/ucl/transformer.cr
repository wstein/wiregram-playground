# frozen_string_literal: true

require "set"
require "./uom"

module WireGram
  module Languages
    module Ucl
      # Transformer to convert UCL AST to UOM
      class Transformer
        # Transform AST to UOM (normalization ready)
        def self.transform(ast, base_dir : String? = nil, visited = Set(String).new, vars = {} of String => String)
          uom = UOM.new
          visitor = new(uom, base_dir, visited, vars)
          visitor.visit_program(ast)
          uom
        end

        def initialize(@uom : UOM, @base_dir : String? = nil, @visited = Set(String).new, @vars = {} of String => String)
        end

        def visit_program(node)
          node.children.each do |child|
            process_child(@uom.root, child)
          end
        end

        private def process_child(section, node)
          return if node.nil?

          case node.type
          when WireGram::Core::NodeType::Assign, WireGram::Core::NodeType::Pair
            key_node = node.children[0]
            value_node = node.children[1]

            return if value_node.nil?

            key = extract_key(key_node)

            case value_node.type
            when WireGram::Core::NodeType::Object
              sub = UOM::Section.new(key)
              value_node.children.each do |c|
                process_child(sub, c)
              end
              @uom.add_assignment(section, key, sub)
            when WireGram::Core::NodeType::Array
              arr = UOM::ArrayValue.new
              value_node.children.each do |el|
                arr.items << convert_value(el)
              end
              @uom.add_assignment(section, key, arr)
            else
              @uom.add_assignment(section, key, convert_value(value_node))
            end
          when WireGram::Core::NodeType::Object
            # Anonymous object at top-level: flatten into parent section
            node.children.each do |c|
              process_child(section, c)
            end
          when WireGram::Core::NodeType::Directive
            # Handle directives from parser
            directive_info = node.value.as(WireGram::Core::DirectiveInfo)
            resolve_include(section, directive_info) if directive_info.name == "include"
          end
        end

        def extract_key(node)
          case node.type
          when WireGram::Core::NodeType::Identifier, WireGram::Core::NodeType::String
            key = node.value.to_s
            # Normalize uppercase section names (e.g., ALIAS -> alias)
            key = key.downcase if /^[A-Z][A-Z0-9_-]*$/.matches?(key)
            key
          else
            "unknown"
          end
        end

        def resolve_include(section, include_info : WireGram::Core::DirectiveInfo)
          args = include_info.args || {} of String => String | Bool | Int64 | Float64 | Nil
          path = include_info.path

          return unless path

          try_value = args["try"]?
          if ["true", true].includes?(try_value) && !(path.includes?("${CURDIR}") || path.starts_with?("$"))
            return
          end

          # Expand variables like ${CURDIR}
          resolved = expand_vars(path)

          # resolved should now be an absolute path (if ${CURDIR} was used) or relative
          # If it's relative, make it absolute relative to base_dir
          if Path[resolved].absolute?
            abs_path = resolved
          else
            abs_base = File.expand_path(@base_dir || Dir.current)
            abs_path = File.join(abs_base, resolved)
          end

          # If path contains wildcard and glob=true, expand
          glob_value = args["glob"]?
          candidates = if ["true", true].includes?(glob_value) || abs_path.includes?("*")
                         Dir.glob(abs_path)
                       else
                         [abs_path]
                       end

          candidates.each do |p|
            next unless File.exists?(p)
            next if @visited.includes?(p)

            @visited << p
            content = File.read(p)
            # Re-process included file through the pipeline, preserving base_dir for nested includes
            result = WireGram::Languages::Ucl.process(content, source_path: p)
            included_uom = result[:uom].as(UOM)

            # Merge included assignments into current section. For now, append in order.
            included_uom.root.items.each do |item|
              # Propagate priority from include args if provided
              priority = args["priority"]?
              if priority
                pr = priority.to_s.to_i
                if item.is_a?(UOM::Assignment)
                  @uom.add_assignment(section, item.key, item.value, pr)
                else
                  # non-assignment items (sections/arrays) are appended directly
                  section.items << item
                end
              else
                # No include priority specified - append items as-is
                section.items << item
              end
            end
          end
        end

        def expand_vars(str : String)
          s = str.dup
          # Replace ${CURDIR} with the absolute base directory path
          abs_base = File.expand_path(@base_dir || Dir.current)
          s = s.gsub("${CURDIR}", abs_base)

          expand_vars_in_string(s)
        end

        def expand_vars_in_string(str : String)
          out = String::Builder.new
          i = 0
          while i < str.size
            ch = str[i]
            if ch != '$'
              out << ch
              i += 1
              next
            end

            # Count consecutive dollars
            j = i
            while j < str.size && str[j] == '$'
              j += 1
            end
            count = j - i

            next_char = str[j]?
            unless next_char && (next_char == '{' || /[A-Z_]/.matches?(next_char.to_s))
              # Special-case: at end-of-string, if preceding character is UPPERCASE, collapse pairs
              if next_char.nil? && i.positive? && /[A-Z]/.matches?(str[i - 1].to_s)
                out << ("$" * (count // 2))
                out << ("$" * (count % 2))
                i = j
                next
              end

              out << ("$" * count)
              i = j
              next
            end

            # Emit literal dollars for each pair (when followed by UPPERCASE var/braces)
            out << ("$" * (count // 2))

            # If count is even, all dollars consumed as literals
            if count.even?
              i = j
              next
            end

            # Single active dollar left
            i = j
            if i < str.size && str[i] == '{'
              k = str.index('}', i + 1)
              if k.nil?
                out << '$'
                next
              end
              inner = str[(i + 1)...k]
              if inner.starts_with?("$")
                inner_var = inner[1..]
                expanded = resolve_var(inner_var)
                out << "${#{expanded}}"
              elsif inner.empty?
                out << "${}"
              else
                out << if /^[A-Z][A-Z0-9_]*$/.matches?(inner)
                         resolve_var(inner)
                       else
                         "${#{inner}}"
                       end
              end
              i = k + 1
            else
              # $VAR form
              m = str[i..].match(/^([A-Za-z_][A-Za-z0-9_]*)/)
              if m
                var = m[1]
                if /^([A-Z]+)([a-z].*)$/.matches?(var)
                  prefix = var.gsub(/^([A-Z]+)([a-z].*)$/, "\\1")
                  rest = var.gsub(/^([A-Z]+)([a-z].*)$/, "\\2")
                  out << resolve_var(prefix)
                  out << rest
                elsif /^[A-Z][A-Z0-9_]*$/.matches?(var)
                  out << resolve_var(var)
                else
                  out << "$#{var}"
                end
                i += var.size
              else
                out << '$'
              end
            end
          end

          out.to_s
        end

        def resolve_var(name : String)
          return "unknown" if name.empty?

          @vars[name]? || ENV[name]? || "unknown"
        end

        def convert_value(node)
          case node.type
          when WireGram::Core::NodeType::String
            # Perform variable expansion in strings and trim accidental trailing spaces
            expanded = expand_vars(node.value.to_s).rstrip
            UOM::Value.new(:string, expanded)
          when WireGram::Core::NodeType::Number
            UOM::Value.new(:number, node.value)
          when WireGram::Core::NodeType::HexNumber
            val = node.value.to_s
            begin
              if val.starts_with?("-")
                sign = -1_i64
                hex = val[3..]
              else
                sign = 1_i64
                hex = val[2..]
              end
              if hex.includes?(".")
                UOM::Value.new(:string, val)
              else
                dec = (sign * hex.to_i64(16)).to_s
                UOM::Value.new(:number, dec)
              end
            rescue
              UOM::Value.new(:string, val)
            end
          when WireGram::Core::NodeType::Boolean
            UOM::Value.new(:boolean, node.value)
          when WireGram::Core::NodeType::Null
            UOM::Value.new(:null, nil)
          when WireGram::Core::NodeType::Identifier
            UOM::Value.new(:string, node.value.to_s)
          when WireGram::Core::NodeType::Object
            sub = UOM::Section.new(nil)
            node.children.each do |c|
              process_child(sub, c)
            end
            sub
          when WireGram::Core::NodeType::Array
            arr = UOM::ArrayValue.new
            node.children.each do |el|
              arr.items << convert_value(el)
            end
            arr
          else
            UOM::Value.new(:string, node.value.to_s)
          end
        end
      end
    end
  end
end
