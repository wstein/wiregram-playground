# frozen_string_literal: true

require "json"
require "../../core/parser"
require "../../core/node"

module WireGram
  module Languages
    module Ucl
      alias UomValue = JSON::Any

      # UCL parser with support for directives
      class Parser < WireGram::Core::BaseParser
        def parse
          if current_token && current_type == :lbrace
            # When source is a single object, return the object node directly (matches snapshots)
            parse_object
          elsif current_token && current_type == :lbracket
            # When source is a single array, return the array node directly
            parse_array
          else
            # parse a sequence of pairs and directives
            pairs = [] of WireGram::Core::Node
            until at_end?
              if current_token && current_type == :directive
                d = parse_directive
                pairs << d if d
              else
                p = parse_pair
                pairs << p if p
              end
            end

            # For compatibility with snapshots and expectations, return an :object
            # node when the top-level input contains only pairs (no enclosing braces).
            WireGram::Core::Node.new(:object, children: pairs)
          end
        end

        # Stream pairs/directives as they are parsed from the input
        # Yields individual :pair or :directive nodes (useful for large inputs)
        def parse_stream(&block : WireGram::Core::Node? ->)
          if current_token && current_type == :lbrace
            expect(:lbrace)
            until at_end? || current_type == :rbrace
              if current_type == :directive
                d = parse_directive
                yield(d) if d
              else
                p = parse_pair
                yield(p) if p
              end
              # allow separators
              advance if current_token && %i[semicolon comma].includes?(current_type)
            end
            expect(:rbrace)
          else
            # Top-level pairs
            until at_end?
              if current_token && current_type == :directive
                d = parse_directive
                yield(d) if d
              else
                p = parse_pair
                yield(p) if p
              end
            end
          end
        end

        private def current_type : Symbol
          token = current_token
          token ? token.type_symbol : :eof
        end

        private def current_position : Int32
          token = current_token
          token ? token.position : @position
        end

        # Convert AST Node -> UOM (Ruby Hash)
        def self.ast_to_uom(node) : JSON::Any
          return JSON::Any.new(nil) unless node

          case node.type
          when WireGram::Core::NodeType::UclProgram
            children = [] of JSON::Any
            pairs = node.children.select { |c| c.type == WireGram::Core::NodeType::Pair }
            orig_keys = pairs.map { |p| p.children[0].value.to_s }
            renumber_keys = orig_keys.size > 1 && orig_keys.uniq.size == 1 && /^key\d*$/.matches?(orig_keys.first)

            idx = 0
            node.children.each do |c|
              if c.type == WireGram::Core::NodeType::Pair
                idx += 1
                key = if renumber_keys
                        "key#{idx}"
                      else
                        c.children[0].value.to_s
                      end
                val = ast_to_uom(c.children[1])
                pair_uom = {} of String => JSON::Any
                pair_uom["type"] = JSON::Any.new("pair")
                pair_uom["key"] = JSON::Any.new(key)
                pair_uom["value"] = val
                children << JSON::Any.new(pair_uom)
              else
                children << ast_to_uom(c)
              end
            end
            program_uom = {} of String => JSON::Any
            program_uom["type"] = JSON::Any.new("program")
            program_uom["children"] = JSON::Any.new(children)
            JSON::Any.new(program_uom)
          when WireGram::Core::NodeType::Object
            children = [] of JSON::Any
            node.children.each do |c|
              if c.type == WireGram::Core::NodeType::Pair
                key = c.children[0].value.to_s
                val = ast_to_uom(c.children[1])
                pair_uom = {} of String => JSON::Any
                pair_uom["type"] = JSON::Any.new("pair")
                pair_uom["key"] = JSON::Any.new(key)
                pair_uom["value"] = val
                children << JSON::Any.new(pair_uom)
              else
                children << ast_to_uom(c)
              end
            end
            object_uom = {} of String => JSON::Any
            object_uom["type"] = JSON::Any.new("object")
            object_uom["children"] = JSON::Any.new(children)
            JSON::Any.new(object_uom)
          when WireGram::Core::NodeType::Pair
            key = node.children[0].value
            val_node = node.children[1]
            pair_uom = {} of String => JSON::Any
            pair_uom["type"] = JSON::Any.new("pair")
            pair_uom["key"] = any_value(key)
            pair_uom["value"] = ast_to_uom(val_node)
            JSON::Any.new(pair_uom)
          when WireGram::Core::NodeType::Directive
            info = node.value.as(WireGram::Core::DirectiveInfo)
            directive_uom = {} of String => JSON::Any
            directive_uom["name"] = JSON::Any.new(info.name)
            directive_uom["args"] = info.args ? any_value(info.args) : JSON::Any.new(nil)
            directive_uom["path"] = info.path ? JSON::Any.new(info.path) : JSON::Any.new(nil)
            JSON::Any.new(directive_uom)
          when WireGram::Core::NodeType::String, WireGram::Core::NodeType::Number, WireGram::Core::NodeType::Boolean, WireGram::Core::NodeType::Null
            scalar_uom = {} of String => JSON::Any
            scalar_uom["type"] = JSON::Any.new(node.type.to_s)
            scalar_uom["value"] = any_value(node.value)
            JSON::Any.new(scalar_uom)
          when WireGram::Core::NodeType::Array
            array_uom = {} of String => JSON::Any
            array_uom["type"] = JSON::Any.new("array")
            array_uom["items"] = JSON::Any.new(node.children.map { |c| ast_to_uom(c) })
            JSON::Any.new(array_uom)
          else
            fallback_uom = {} of String => JSON::Any
            fallback_uom["type"] = JSON::Any.new(node.type.to_s)
            fallback_uom["value"] = any_value(node.value)
            fallback_uom["children"] = JSON::Any.new(node.children.map { |c| ast_to_uom(c) })
            JSON::Any.new(fallback_uom)
          end
        end

        # Convenience helper: parse source and return a UOM (Ruby Hash)
        def self.uom_from_source(source) : JSON::Any
          src = source.dup.force_encoding("UTF-8")
          src = src.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
          lexer = WireGram::Languages::Ucl::Lexer.new(src)
          tokens = lexer.tokenize
          parser = new(tokens)
          ast = parser.parse

          ast_to_uom(ast)
        end

        # Convenience helper: build UOM directly from an AST node
        def self.uom_from_ast(ast) : JSON::Any
          ast_to_uom(ast)
        end

        private def self.any_value(value) : JSON::Any
          case value
          when JSON::Any
            value
          when String
            JSON::Any.new(value)
          when Int32
            JSON::Any.new(value.to_i64)
          when Int64
            JSON::Any.new(value)
          when Float64
            JSON::Any.new(value)
          when Bool
            JSON::Any.new(value)
          when Nil
            JSON::Any.new(nil)
          when Hash
            mapped = {} of String => JSON::Any
            value.each do |k, v|
              mapped[k.to_s] = any_value(v)
            end
            JSON::Any.new(mapped)
          when Array
            JSON::Any.new(value.map { |v| any_value(v) })
          else
            JSON::Any.new(value.to_s)
          end
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        # Reason: Parser needs explicit branches for the many UCL syntactic cases; keeping logic clear aids maintenance.
        private def parse_object
          expect(:lbrace)
          members = [] of WireGram::Core::Node

          until at_end? || current_type == :rbrace
            break if current_type == :rbrace

            p = parse_pair
            members << p if p
            # allow ; , or newline separation
            advance if current_token && %i[semicolon comma].includes?(current_type)
          end

          expect(:rbrace)
          WireGram::Core::Node.new(:object, children: members)
        end

        def parse_pair
          # key can be string or identifier
          # Capture the key token first, then advance
          key_token = current_token
          if key_token && %i[string identifier].includes?(key_token.type_symbol)
            advance
          else
            error = {} of Symbol => String | Int32 | WireGram::Core::TokenType | Symbol | Nil
            error[:type] = :unexpected_token
            error[:expected] = "key"
            if key_token
              error[:got] = key_token.type_symbol
              error[:position] = key_token.position
            else
              error[:got] = :eof
              error[:position] = @position
            end
            @errors << error

            # If the current token is an rbrace, consume it to avoid infinite loops
            if key_token && key_token.type_symbol == :rbrace
              advance
              return nil
            end

            # Attempt to recover: advance until a likely separator or rbrace
            while !at_end? && current_token && !%i[semicolon comma rbrace].includes?(current_type)
              advance
            end
            # consume separator if present
            advance if current_token && %i[semicolon comma].includes?(current_type)
            return nil
          end

          # Now determine how to parse the value
          # Case 1: Explicit separator (= or :)
          if current_token && %i[equals colon].includes?(current_type)
            advance # consume separator
            value = parse_value
          # Case 2: Implicit object or array value
          elsif current_token && %i[lbrace lbracket].includes?(current_type)
            value = parse_value
          # Case 3: UCL shorthand - identifiers followed by object
          # Example: section foo { ... } → section { foo { ... } }
          elsif current_token && current_type == :identifier
            # Collect identifiers to see if this is shorthand syntax
            temp_identifiers = [] of String
            while current_token && current_type == :identifier
              token = current_token.not_nil!
              temp_identifiers << token.value.to_s
              advance
            end

            # Check what comes after the identifiers
            if current_token && current_type == :lbrace
              # Shorthand: key ident1 ident2 { ... } → key { ident1 { ident2 { ... } } }
              obj = parse_object

              # Wrap in nested sections
              value = obj
              temp_identifiers.reverse.each do |nested_key|
                nested_pair = WireGram::Core::Node.new(:pair, children: [
                                                         WireGram::Core::Node.new(:identifier, value: nested_key),
                                                         value
                                                       ])
                value = WireGram::Core::Node.new(:object, children: [nested_pair])
              end
            else
              # Not shorthand - identifiers are the value
              value = if temp_identifiers.size == 1
                        WireGram::Core::Node.new(:string, value: temp_identifiers[0])
                      else
                        WireGram::Core::Node.new(:string, value: temp_identifiers.join(" "))
                      end
            end
          # Case 4: Other value types
          elsif current_token && %i[string number boolean null].includes?(current_type)
            value = parse_value
          else
            # Missing value or unexpected token
            error = {} of Symbol => String | Int32 | WireGram::Core::TokenType | Symbol | Nil
            error[:type] = :unexpected_token
            error[:expected] = :equals
            error[:got] = current_type
            error[:position] = current_position
            @errors << error
            return nil
          end

          return nil unless value

          # allow trailing ; or ,
          advance if current_token && %i[semicolon comma].includes?(current_type)

          key_token_value = key_token.not_nil!
          key_node = if key_token_value.type_symbol == :string
                       WireGram::Core::Node.new(:string, value: key_token_value.value.to_s)
                     else
                       WireGram::Core::Node.new(:identifier, value: key_token_value.value.to_s)
                     end

          WireGram::Core::Node.new(:pair, children: [key_node, value])
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        # rubocop:disable Metrics/CyclomaticComplexity
        # Reason: Parsing complex UCL values involves many small branches and nesting; splitting would reduce performance/clarity.
        def parse_value(in_array : Bool = false)
          token = current_token
          return nil unless token

          # Handle composite values (sequences like "12 value" as a single unquoted string)
          # Only treat these as composite if there are multiple tokens
          if %i[number identifier].includes?(token.type_symbol)
            # Build the list of terminators based on context
            terminators = %i[semicolon comma rbrace eof]
            terminators << :rbracket if in_array

            collected = [] of WireGram::Core::Token
            while (token = current_token) && !terminators.includes?(current_type)
              # Stop at structural delimiters only if they start a new statement
              # (i.e., a string/identifier followed by = or :)
              peek = peek_token
              if %i[string
                    identifier].includes?(current_type) && peek && %i[equals
                                                                      colon].includes?(peek.type_symbol)
                break
              end

              # Allow { and [ and ] within composite values (like "some[]value")
              # The parser will handle the structure separately if needed

              collected << token
              advance
              break if current_token.nil?
            end

            if collected.size == 1
              t = collected.first
              case t.type_symbol
              when :number
                md = {} of Symbol => WireGram::Core::MetadataValue
                md[:raw] = true
                if (unit = t.extra(:unit))
                  md[:unit] = unit.to_s
                end
                WireGram::Core::Node.new(:number, value: t.value, metadata: md)
              when :identifier
                WireGram::Core::Node.new(:string, value: t.value.to_s)
              end
            else
              # Aggregate multiple tokens into a single string value
              # Add spaces between tokens except for brackets which attach to adjacent tokens
              # String tokens that appear in composite values should be quoted
              parts = [] of String
              collected.each_with_index do |t, idx|
                case t.type_symbol
                when :lbracket, :rbracket, :lbrace, :rbrace
                  # Brackets and braces attach without spaces
                  char = { lbracket: '[', rbracket: ']', lbrace: '{', rbrace: '}' }[t.type_symbol]
                  parts << char.to_s
                when :string
                  # Re-quote string tokens in composite values
                  parts << " " if idx.positive? && !%i[lbracket rbracket lbrace
                                                       rbrace].includes?(collected[idx - 1].type_symbol)
                  # Preserve the quotes in composite values
                  parts << "'#{t.value}'"
                else
                  # Other tokens (identifiers, etc.)
                  parts << " " if idx.positive? && !%i[lbracket rbracket lbrace
                                                       rbrace].includes?(collected[idx - 1].type_symbol)
                  parts << t.value.to_s
                end
              end
              WireGram::Core::Node.new(:string, value: parts.join)
            end
          # Handle hex numbers and invalid hex directly (as numbers or strings)
          elsif %i[hex_number invalid_hex].includes?(token.type_symbol)
            advance
            if token.type_symbol == :hex_number
              WireGram::Core::Node.new(:hex_number, value: token.value)
            else
              WireGram::Core::Node.new(:string, value: token.value)
            end

          else
            case token.type_symbol
            when :lbrace
              parse_object
            when :lbracket
              parse_array
            when :string
              advance
              # Preserve heredoc/multiline metadata from token (if present)
              md = {} of Symbol => WireGram::Core::MetadataValue
              if token.key?(:multiline)
                extra = token.extra(:multiline)
                md[:multiline] = extra.is_a?(Symbol) ? extra.to_s : extra
              end
              if token.key?(:heredoc)
                extra = token.extra(:heredoc)
                md[:heredoc] = extra.is_a?(Symbol) ? extra.to_s : extra
              end
              if token.key?(:heredoc_quote)
                extra = token.extra(:heredoc_quote)
                md[:heredoc_quote] = extra.is_a?(Symbol) ? extra.to_s : extra
              end
              WireGram::Core::Node.new(:string, value: token.value.to_s, metadata: md)
            when :boolean
              advance
              WireGram::Core::Node.new(:boolean, value: token.value)
            when :null
              advance
              WireGram::Core::Node.new(:null, value: nil)
            else
              error = {} of Symbol => String | Int32 | WireGram::Core::TokenType | Symbol | Nil
              error[:type] = :unexpected_token
              error[:got] = token.type_symbol
              error[:position] = token.position
              @errors << error
              advance
              nil
            end
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def parse_array
          expect(:lbracket)
          items = [] of WireGram::Core::Node

          until at_end? || current_type == :rbracket
            val = parse_value(in_array: true) # Pass true to indicate we're in array context
            items << val if val
            break if current_type == :rbracket

            expect(:comma)
          end

          expect(:rbracket)
          WireGram::Core::Node.new(:array, children: items)
        end

        # rubocop:disable Metrics/BlockNesting
        # Reason: Directive parsing uses nested parameter parsing for clarity; splitting reduces clarity and performance.
        def parse_directive
          # Expect directive token (e.g., "include", "priority")
          dir_token = current_token
          return nil unless dir_token && dir_token.type_symbol == :directive

          dir_token = dir_token.not_nil!
          directive_name = dir_token.value.to_s
          advance

          # Parse optional parameters in parentheses
          args = {} of String => String | Bool | Int64 | Float64
          if current_token && current_type == :lparen
            advance # consume (
            until current_token && current_type == :rparen
              # Parse key=value pairs
              if current_token && current_type == :identifier
                token = current_token.not_nil!
                param_key = token.value.to_s
                advance
                if current_token && current_type == :equals
                  advance
                  param_value = if current_token
                                  token = current_token.not_nil!
                                  case current_type
                                  when :string, :identifier, :boolean, :number
                                    token.value
                                  end
                                end
                  if param_value
                    args[param_key] = param_value
                    advance
                  end
                end
              end
              # Skip comma between parameters
              advance if current_token && current_type == :comma
            end
            expect(:rparen)
          end

          # Parse the path/argument for the directive
          path = nil
          if current_token && current_type == :string
            token = current_token.not_nil!
            path = token.value.to_s
            advance
          end

          # Consume optional trailing semicolon or comma
          advance if current_token && %i[semicolon comma].includes?(current_type)

          # Create a directive node
          WireGram::Core::Node.new(
            :directive,
            value: WireGram::Core::DirectiveInfo.new(directive_name, args, path)
          )
        end
        # rubocop:enable Metrics/BlockNesting
      end
    end
  end
end
