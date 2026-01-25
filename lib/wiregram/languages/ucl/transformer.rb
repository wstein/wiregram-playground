# frozen_string_literal: true

require_relative 'uom'

module WireGram
  module Languages
    module Ucl
      class Transformer
        # Transform AST to UOM (normalization ready)
        require 'set'

        def self.transform(ast, base_dir = nil, visited = Set.new, vars = {})
          uom = UOM.new
          visitor = new(uom, base_dir, visited, vars)
          visitor.visit_program(ast)
          uom
        end

        def initialize(uom, base_dir = nil, visited = Set.new, vars = {})
          @uom = uom
          @base_dir = base_dir
          @visited = visited
          @vars = vars || {}
        end

        def visit_program(node)
          node.children.each do |child|
            process_child(@uom.root, child)
          end
        end

        private

        def process_child(section, node)
          return if node.nil?

          case node.type
          when :assignment, :pair
            # Handle both :assignment and :pair node types
            key_node = node.children[0]
            value_node = node.children[1]

            return if value_node.nil?  # Skip if value failed to parse
            key = extract_key(key_node)

            if value_node.type == :object
              sub = UOM::Section.new(key)
              value_node.children.each do |c|
                process_child(sub, c)
              end
              @uom.add_assignment(section, key, sub)
            elsif value_node.type == :array
              arr = UOM::ArrayValue.new
              value_node.children.each do |el|
                arr.items << convert_value(el)
              end
              @uom.add_assignment(section, key, arr)
            else
              @uom.add_assignment(section, key, convert_value(value_node))
            end
          when :object
            # Anonymous object at top-level: flatten into parent section
            node.children.each do |c|
              process_child(section, c)
            end
          when :include
            include_info = node.value
            resolve_include(section, include_info)
          when :directive
            # Handle directives from parser
            directive_info = node.value
            if directive_info.is_a?(Hash) && directive_info[:name] == 'include'
              resolve_include(section, directive_info)
            end
            # Other directives (.priority, .inherit, etc.) can be handled here later
          end
        end

        def extract_key(node)
          case node.type
          when :identifier, :string
            key = node.value
            # Normalize uppercase section names (e.g., ALIAS -> alias)
            if key =~ /^[A-Z][A-Z0-9_\-]*$/
              key = key.downcase
            end
            key
          else
            'unknown'
          end
        end

        def resolve_include(section, include_info)
          name = include_info[:name]
          args = include_info[:args] || {}
          path = include_info[:path]

          return unless path

          # If try=true and path is a simple relative path without ${CURDIR} or env var, skip (libucl "try" semantics)
          if (args['try'] == 'true' || args['try'] == true) && !(path.include?('${CURDIR}') || path.start_with?('$'))
            return
          end

          # Expand variables like ${CURDIR}
          resolved = expand_vars(path)

          # resolved should now be an absolute path (if ${CURDIR} was used) or relative
          # If it's relative, make it absolute relative to base_dir
          if File.absolute_path?(resolved)
            abs_path = resolved
          else
            abs_base = File.expand_path(@base_dir || Dir.pwd)
            abs_path = File.join(abs_base, resolved)
          end

          # If path contains wildcard and glob=true, expand
          candidates = if (args['glob'] == 'true' || args['glob'] == true) || abs_path.include?('*')
                         Dir.glob(abs_path)
                       else
                         [abs_path]
                       end

          candidates.each do |p|
            next unless File.exist?(p)
            next if @visited.include?(p)

            @visited << p
            content = File.read(p)
            # Re-process included file through the pipeline, preserving base_dir for nested includes
            result = WireGram::Languages::Ucl.process(content, source_path: p)
            included_uom = result[:uom]

            # Merge included assignments into current section. For now, append in order.
            included_uom.root.items.each do |item|
              # Propagate priority from include args if provided
              if args['priority']
                pr = args['priority'].to_i
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

        def expand_vars(str)
          return str unless str.is_a?(String)

          s = str.dup
          # Replace ${CURDIR} with the absolute base directory path
          abs_base = File.expand_path(@base_dir || Dir.pwd)
          s = s.gsub('${CURDIR}', abs_base)

          expand_vars_in_string(s)
        end

        def expand_vars_in_string(s)
          out = String.new
          i = 0
          while i < s.length
            ch = s[i]
            if ch != '$'
              out << ch
              i += 1
              next
            end

            # Count consecutive dollars
            j = i
            j += 1 while j < s.length && s[j] == '$'
            count = j - i

            next_char = s[j]
            # If the sequence isn't followed by a brace or an UPPERCASE letter (i.e., not a var or ${}),
            # then usually keep the dollar sequence verbatim (do not interpret pairs as escapes).
            unless next_char && (next_char == '{' || next_char.match(/[A-Z_]/))
              # Special-case: at end-of-string, if preceding character is UPPERCASE, collapse pairs
              if next_char.nil? && i > 0 && s[i - 1].match(/[A-Z]/)
                out << ('$' * (count / 2))
                out << ('$' * (count % 2))
                i = j
                next
              end

              out << ('$' * count)
              i = j
              next
            end

            # Emit literal dollars for each pair (when followed by UPPERCASE var/braces)
            out << ('$' * (count / 2))

            # If count is even, all dollars consumed as literals
            if count.even?
              i = j
              next
            end

            # Single active dollar left
            i = j
            if i < s.length && s[i] == '{'
              # find closing brace
              k = s.index('}', i + 1)
              if k.nil?
                out << '$'
                next
              end
              inner = s[(i + 1)...k]
              if inner.start_with?('$')
                # ${$VAR} -> keep braces, expand inner var
                inner_var = inner[1..]
                expanded = resolve_var(inner_var)
                out << "${#{expanded}}"
              elsif inner.empty?
                out << '${}'
              else
                # ${VAR} -> expand only for all-uppercase variable names, otherwise keep literal
                if inner =~ /^[A-Z][A-Z0-9_]*$/
                  out << resolve_var(inner)
                else
                  out << "${#{inner}}"
                end
              end
              i = k + 1
            else
              # $VAR form
              m = s[i..].match(/^([A-Za-z_][A-Za-z0-9_]*)/)
              if m
                var = m[1]
                # If var is mixed-case with uppercase prefix followed by lowercase, split
                if var =~ /^([A-Z]+)([a-z].*)$/
                  prefix = $1
                  rest = $2
                  out << resolve_var(prefix)
                  out << rest
                  i += var.length
                elsif var =~ /^[A-Z][A-Z0-9_]*$/
                  # all uppercase -> expand
                  out << resolve_var(var)
                  i += var.length
                else
                  # lowercase or mixed (non-uppercase) -> keep as literal $var
                  out << "$#{var}"
                  i += var.length
                end
              else
                # Nothing valid, output single $
                out << '$'
              end
            end
          end

          out
        end

        def resolve_var(name)
          return 'unknown' if name.nil? || name.empty?
          @vars[name] || ENV[name] || 'unknown'
        end

        def convert_value(node)
          case node.type
          when :string
            # Perform variable expansion in strings and trim accidental trailing spaces
            expanded = expand_vars(node.value.to_s).rstrip
            UOM::Value.new(:string, expanded)
          when :number
            UOM::Value.new(:number, node.value)
          when :hex_number
            # Convert hex to decimal where possible; invalid hex handled by parser as string
            val = node.value
            begin
              if val.start_with?('-')
                sign = -1
                hex = val[3..-1]
              else
                sign = 1
                hex = val[2..-1]
              end
              # invalid hex (with dot) will raise or be nonsense; default to string
              if hex.include?('.')
                UOM::Value.new(:string, val)
              else
                dec = (sign * hex.to_i(16)).to_s
                UOM::Value.new(:number, dec)
              end
            rescue
              UOM::Value.new(:string, val)
            end
          when :boolean
            UOM::Value.new(:boolean, node.value)
          when :null
            UOM::Value.new(:null, nil)
          when :identifier
            # treat unquoted identifiers as strings (could be variables/macro refs)
            UOM::Value.new(:string, node.value)
          when :object
            # Convert object node into a UOM::Section
            sub = UOM::Section.new(nil)
            node.children.each do |c|
              process_child(sub, c)
            end
            sub
          when :array
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
