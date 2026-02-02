module Warp
  module Lang
    module Crystal
      # CST-driven transpiler: Crystal → Ruby
      # Properly transforms CST nodes instead of using regex substitutions
      class CrystalToRubyTranspiler
        struct Result
          property output : String
          property error : Warp::Core::ErrorCode
          property diagnostics : Array(String)
          property tokens : Array(Token)?

          def initialize(@output, @error, @diagnostics = [] of String, @tokens = nil)
          end
        end

        def self.transpile(bytes : Bytes, path : String? = nil) : Result
          # Step 1: Lex Crystal source
          tokens, lex_error, lex_pos = Lexer.scan(bytes)
          if lex_error != Warp::Core::ErrorCode::Success
            diag = Warp::Diagnostics.lex_error("lex error", bytes, lex_pos, path)
            return Result.new("", lex_error, [diag.to_s], tokens)
          end

          # Step 2: Parse Crystal to CST
          crystal_root, parse_error = CST::Parser.parse(bytes, tokens)
          if parse_error != Warp::Core::ErrorCode::Success
            return Result.new("", parse_error, ["parse error"])
          end
          return Result.new("", Warp::Core::ErrorCode::UnexpectedError, ["nil CST root"]) if crystal_root.nil?

          # Step 3: Transform Crystal CST to Ruby output via visitor
          transformer = CrystalToRubyTransformer.new(bytes)
          ruby_output = transformer.visit(crystal_root)

          Result.new(ruby_output, Warp::Core::ErrorCode::Success, [] of String)
        end
      end

      # CST Visitor: Traverses Crystal CST and generates Ruby output
      class CrystalToRubyTransformer
        @bytes : Bytes

        def initialize(@bytes : Bytes)
        end

        def visit(node : CST::GreenNode) : String
          case node.kind
          when CST::NodeKind::Root
            visit_root(node)
          when CST::NodeKind::RawText
            visit_raw_text(node)
          when CST::NodeKind::MethodDef
            visit_method_def(node)
          when CST::NodeKind::ClassDef
            visit_class_def(node)
          when CST::NodeKind::ModuleDef
            visit_module_def(node)
          when CST::NodeKind::StructDef
            visit_struct_def(node)
          when CST::NodeKind::EnumDef
            visit_enum_def(node)
          when CST::NodeKind::MacroDef
            visit_macro_def(node)
          when CST::NodeKind::MethodCall
            visit_method_call(node)
          when CST::NodeKind::Identifier
            visit_identifier(node)
          when CST::NodeKind::StringLiteral
            visit_string_literal(node)
          when CST::NodeKind::Block
            visit_block(node)
          else
            node.text || ""
          end
        end

        private def visit_root(node : CST::GreenNode) : String
          parts = [] of String
          node.children.each do |child|
            output = visit(child)
            parts << output unless output.empty?
          end
          parts.join
        end

        private def visit_raw_text(node : CST::GreenNode) : String
          text = node.text || ""
          # Post-process: normalize require statements
          text = text.gsub(%r{\brequire(?!_relative)\s+(['"])\.\./}, "require_relative \\1../")
          text = text.gsub(%r{\brequire(?!_relative)\s+(['"])\./}, "require_relative \\1./")
          # Normalize duplicate slashes: ".//" → "./"
          text = text.gsub(/require_relative\s+(['"])\.\/+/, "require_relative \\1./")
          # Transform &.method to &:method
          text = text.gsub(/&\.([a-zA-Z_][a-zA-Z0-9_]*[!?]?)/, "&:\\1")
          text
        end

        private def visit_method_def(node : CST::GreenNode) : String
          payload = node.method_payload
          return "" unless payload

          # If we have the original source, use it to preserve indentation
          if original_source = payload.original_source
            # Extract leading whitespace from the original source
            leading_ws_match = original_source.match(/^(\s*)/)
            leading_ws = leading_ws_match ? leading_ws_match[1] : ""

            # Check if we have type annotations
            has_types = payload.params.any? { |p| !p.type.nil? } || payload.return_type

            if has_types
              # Generate Sorbet sig and reconstruct without types
              sig = build_sorbet_sig(payload)
              def_line = build_ruby_def_line(payload, leading_ws)
              body = transform_body(payload.body)

              output = String.build do |io|
                io << sig if sig
                io << def_line
                io << body
                io << leading_ws << "end\n"
              end
              output
            else
              # No types - just apply body transformations
              body = transform_body(payload.body)

              # Reconstruct preserving original structure
              lines = original_source.lines(chomp: false)
              def_idx = nil
              lines.each_with_index { |l, i| def_idx = i if l.match(/\bdef\b/) }

              if def_idx
                output_lines = lines[0..def_idx]
                output_lines.concat(body.lines(chomp: false))

                if output_lines.last && !output_lines.last.match(/^\s*end\s*$/)
                  output_lines << "#{leading_ws}end\n"
                end
                output_lines.join
              else
                transform_body(original_source)
              end
            end
          else
            # Fallback: regenerate from payload
            sig = build_sorbet_sig(payload)
            def_line = build_ruby_def_line(payload)
            body = transform_body(payload.body)
            indent = extract_indent_from_body(body)

            output = String.build do |io|
              io << sig if sig
              io << def_line
              io << body
              io << indent << "end\n"
            end
            output
          end
        end

        private def transform_body(body : String) : String
          # Transform &.method to &:method
          body = body.gsub(/&\.([a-zA-Z_][a-zA-Z0-9_]*[!?]?)/, "&:\\1")
          body
        end

        private def build_sorbet_sig(payload : CST::MethodDefPayload) : String?
          # Only emit sig if there are type annotations or return type
          has_types = payload.params.any? { |p| !p.type.nil? } || payload.return_type

          return nil unless has_types

          indent = extract_indent_from_body(payload.body)
          param_sigs = payload.params.map do |param|
            if param_type = param.type
              ruby_type = translate_crystal_type_to_ruby(param_type)
              "#{param.name}: #{ruby_type}"
            else
              "#{param.name}: Object"
            end
          end

          return_sig = if return_type = payload.return_type
                         ruby_return = translate_crystal_type_to_ruby(return_type)
                         ".returns(#{ruby_return})"
                       else
                         ""
                       end

          param_str = param_sigs.empty? ? "" : "params(#{param_sigs.join(", ")})"
          sig_content = if param_str.empty?
                          if return_sig.empty?
                            "Object"
                          else
                            return_sig.lstrip.sub(".", "")
                          end
                        elsif return_sig.empty?
                          param_str
                        else
                          "#{param_str}#{return_sig}"
                        end

          "#{indent}sig { #{sig_content} }\n"
        end

        private def extract_indent_from_body(body : String) : String
          lines = body.lines
          if lines.size > 0 && lines[0].match(/^(\s+)/)
            lines[0].match(/^(\s+)/).not_nil![1]
          else
            "  "
          end
        end

        private def build_ruby_def_line(payload : CST::MethodDefPayload, indent : String? = nil) : String
          param_names = payload.params.map(&.name).join(", ")
          indent = indent || extract_indent_from_body(payload.body)
          header = "def #{payload.name}"

          if payload.had_parens || payload.params.size > 0
            header += "(#{param_names})"
          end

          "#{indent}#{header}\n"
        end

        private def translate_crystal_type_to_ruby(crystal_type : String) : String
          stripped = crystal_type.strip

          # Handle nilable types first
          if stripped.ends_with?("?")
            base_type = stripped.chomp("?")
            inner_type = translate_crystal_type_to_ruby(base_type)
            return "T.nilable(#{inner_type})"
          end

          # For generic types like Array(String), just capitalize and replace inner types recursively
          if stripped.includes?("(") && stripped.ends_with?(")")
            # Extract the base type and inner types
            if match = stripped.match(/^([A-Za-z][a-zA-Z0-9_]*)\((.*)\)$/)
              base = match[1]
              inner = match[2]

              base_translated = case base.downcase
                                when "string"
                                  "String"
                                when "int", "int32", "int64"
                                  "Integer"
                                when "float", "float32", "float64"
                                  "Float"
                                when "bool"
                                  "T::Boolean"
                                when "array"
                                  "Array"
                                when "hash"
                                  "Hash"
                                when "nil", "void"
                                  "NilClass"
                                else
                                  base
                                end

              # Translate inner types
              if inner && !inner.empty?
                inner_parts = inner.split(/,\s*/).map { |t| translate_crystal_type_to_ruby(t) }
                "#{base_translated}(#{inner_parts.join(", ")})"
              else
                base_translated
              end
            else
              stripped
            end
          else
            # Non-generic types
            case stripped.downcase
            when "string"
              "String"
            when "int", "int32", "int64", "integer"
              "Integer"
            when "float", "float32", "float64"
              "Float"
            when "bool", "boolean"
              "T::Boolean"
            when "array"
              "Array"
            when "hash"
              "Hash"
            when "nil", "void"
              "NilClass"
            else
              stripped
            end
          end
        end

        private def visit_class_def(node : CST::GreenNode) : String
          text = node.text || ""
          transform_body(text)
        end

        private def visit_module_def(node : CST::GreenNode) : String
          text = node.text || ""
          transform_body(text)
        end

        private def visit_struct_def(node : CST::GreenNode) : String
          text = node.text || ""
          transform_body(text)
        end

        private def visit_enum_def(node : CST::GreenNode) : String
          text = node.text || ""
          transform_body(text)
        end

        private def visit_macro_def(node : CST::GreenNode) : String
          text = node.text || ""
          transform_body(text)
        end

        private def visit_method_call(node : CST::GreenNode) : String
          text = node.text || ""
          text.gsub(/&\.(\w+)/, "&:\\1")
        end

        private def visit_identifier(node : CST::GreenNode) : String
          node.text || ""
        end

        private def visit_string_literal(node : CST::GreenNode) : String
          node.text || ""
        end

        private def visit_block(node : CST::GreenNode) : String
          node.text || ""
        end
      end
    end
  end
end
