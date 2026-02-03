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

        def self.transpile(bytes : Bytes, path : String? = nil, config : Warp::Lang::Ruby::TranspilerConfig? = nil) : Result
          # Create debug context from config
          debug = DebugContext.from_config(config)

          # Step 1: Lex Crystal source
          tokens, lex_error, lex_pos = Lexer.scan(bytes)
          if lex_error != Warp::Core::ErrorCode::Success
            debug.report_lexer_error("scanning failed at position #{lex_pos}", lex_pos)
            diag = Warp::Diagnostics.lex_error("lex error", bytes, lex_pos, path)
            return Result.new("", lex_error, [diag.to_s] + debug.diagnostics, tokens)
          end

          # Step 2: Parse Crystal to CST
          crystal_root, parse_error = CST::Parser.parse(bytes, tokens, debug)
          if parse_error != Warp::Core::ErrorCode::Success
            debug.report_parser_error("failed to parse Crystal source")
            return Result.new("", parse_error, ["parse error"] + debug.diagnostics)
          end
          return Result.new("", Warp::Core::ErrorCode::UnexpectedError, ["nil CST root"] + debug.diagnostics) if crystal_root.nil?

          # Step 3: Transform Crystal CST to Ruby output via visitor
          cfg = config || Warp::Lang::Ruby::TranspilerConfig.new
          transformer = CrystalToRubyTransformer.new(bytes, cfg)
          ruby_output = transformer.visit(crystal_root)

          # Step 4: Remove Crystal numeric type suffixes from the final output
          ruby_output = remove_numeric_suffixes(ruby_output)

          Result.new(ruby_output, Warp::Core::ErrorCode::Success, debug.diagnostics)
        end

        private def self.remove_numeric_suffixes(text : String) : String
          # Remove Crystal numeric type suffixes (_u8, _i32, _f64, etc.)
          # Handles: decimal (42_u64), hex (0xC2_u8), octal (0o77_u8), binary (0b1010_u8), float (3.14_f64)
          # Pattern: optional underscore (for formatting) followed by type suffix
          text.gsub(/_?(?:[ui](?:8|16|32|64|size)|f(?:32|64))(?![a-zA-Z0-9_])/, "")
        end
      end

      # CST Visitor: Traverses Crystal CST and generates Ruby output
      class CrystalToRubyTransformer
        @bytes : Bytes
        @config : Warp::Lang::Ruby::TranspilerConfig

        def initialize(@bytes : Bytes, @config : Warp::Lang::Ruby::TranspilerConfig)
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
          apply_token_mappings(text)
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
          # 1. Remove Crystal numeric suffixes (_u64, _i32, _f64, etc.)
          # Handles: decimal (42_u64), hex (0xC2_u8), octal (0o77_u8), binary (0b1010_u8), float (3.14_f64)
          # Pattern: optional underscore (for formatting) followed by type suffix
          # Examples: 0xC2_u8, 42_u64, 0b1010_i32, 3.14_f64, 1_000_000_u64
          body = body.gsub(/_?(?:[ui](?:8|16|32|64|size)|f(?:32|64))(?![a-zA-Z0-9_])/, "")

          # 2. Transform {} of Key => Value to {} (remove Crystal-style hash type annotations)
          # MUST come before tuple transformation to avoid double-matching
          # Matches: {} of String => Int32, etc.
          body = body.gsub(/\{\}\s+of\s+[A-Za-z_][A-Za-z0-9_:]*\s*=>\s*[A-Za-z_][A-Za-z0-9_:]*/, "{}")

          # 3. Transform [] of Type to [] (remove Crystal-style array type annotations)
          # Matches: [] of SomeType, [] of String, etc.
          body = body.gsub(/\[\]\s+of\s+[A-Za-z_][A-Za-z0-9_:]*(?:\([^)]*\))?\b/, "[]")

          # 4. Transform tuple literals {a, b} to array literals [a, b]
          # This is more complex because we need to preserve content but not catch hash literals
          # Tuple pattern: {expr, expr} but NOT {key: value} or {key => value}
          # We use a simple heuristic to avoid matching hash literals with =>
          body = body.gsub(/\{([^}]*?)\}/) do |match|
            inner = match[1...-1] # Remove outer braces
            # Check if this looks like a hash (contains =>) or named args (contains :)
            # Also check if it's empty {} (likely a hash, not a tuple)
            # Simple heuristic: if it contains => or key: value pattern, or is empty, keep as-is
            if inner.empty? || inner.includes?("=>") || inner.match(/\w+\s*:/)
              match # Keep hash/named args/empty braces as-is
            else
              # This is likely a tuple or regular braces - convert to array brackets
              "[#{inner}]"
            end
          end

          # 5. Transform block shorthand &.method to explicit Ruby block when used as argument
          apply_token_mappings(body)
        end

        private struct Edit
          getter start : Int32
          getter end_pos : Int32
          getter text : String

          def initialize(@start : Int32, @end_pos : Int32, @text : String)
          end
        end

        # Transform path by replacing directory names based on folder mappings
        # Uses Path library to handle path components properly
        # Example: "../../otherproject/src/test/src/test" with mapping {"src/" => "lib/"}
        #          becomes "../../otherproject/lib/test/src/test" (only first matching directory)
        private def transform_path_with_mappings(path : String, mappings : Hash(String, String)) : String
          return path if mappings.empty?

          # Parse the path into parts
          path_obj = Path.new(path)
          parts = path_obj.parts.dup

          # Try each mapping
          mappings.each do |src_dir, dst_dir|
            # Remove trailing slash for comparison if present
            src_name = src_dir.rstrip('/')
            dst_name = dst_dir.rstrip('/')

            # Find and replace the first occurrence of the directory name
            parts.each_with_index do |part, idx|
              if part == src_name
                parts[idx] = dst_name
                # Only replace the first occurrence per mapping
                break
              end
            end
          end

          # Reconstruct path from parts
          if parts.empty?
            return path
          end

          # Preserve leading "./" or "../" patterns
          if path.starts_with?("../")
            # Count leading ../
            leading_ups = 0
            temp = path
            while temp.starts_with?("../")
              leading_ups += 1
              temp = temp[3..-1]
            end
            # Rebuild with leading ../
            result = "../" * leading_ups
            result += parts[leading_ups..-1].join("/") if leading_ups < parts.size
            return result
          elsif path.starts_with?("./")
            return "./" + parts[1..-1].join("/")
          else
            return parts.join("/")
          end
        end

        private def apply_token_mappings(text : String) : String
          bytes = text.to_slice
          tokens, error, _ = Lexer.scan(bytes)
          return text unless error == Warp::Core::ErrorCode::Success

          edits = [] of Edit
          prev_kind : TokenKind? = nil
          folder_mappings = @config.get_folder_mappings

          i = 0
          while i < tokens.size
            tok = tokens[i]

            if tok.kind == TokenKind::Require
              j = i + 1
              # Skip newlines and whitespace to find the string
              while j < tokens.size && (tokens[j].kind == TokenKind::Newline || tokens[j].kind == TokenKind::Whitespace)
                j += 1
              end
              if j < tokens.size && tokens[j].kind == TokenKind::String
                raw = String.new(bytes[tokens[j].start, tokens[j].length])
                quote = raw[0]
                content = raw[1...-1] # Remove quotes

                # Check for relative requires (require_relative)
                if content.starts_with?("./") || content.starts_with?("../")
                  edits << Edit.new(tok.start, tok.start + tok.length, "require_relative")

                  # Transform paths based on folder mappings using Path library
                  new_content = transform_path_with_mappings(content, folder_mappings)

                  # If path was changed, create an edit
                  if new_content != content
                    new_raw = "#{quote}#{new_content}#{quote}"
                    edits << Edit.new(tokens[j].start, tokens[j].start + tokens[j].length, new_raw)
                  end
                end
              end
            end

            if tok.kind == TokenKind::Ampersand && i + 2 < tokens.size
              if tokens[i + 1].kind == TokenKind::Dot && tokens[i + 2].kind == TokenKind::Identifier
                if prev_kind == TokenKind::LParen || prev_kind == TokenKind::Comma
                  method_name = String.new(bytes[tokens[i + 2].start, tokens[i + 2].length])
                  # Use symbol-to-proc syntax (&:method) which is valid in all contexts
                  # This is the idiomatic Ruby way and works with parentheses: arr.map(&:kind)
                  replacement = "&:#{method_name}"
                  start_pos = tok.start
                  end_pos = tokens[i + 2].start + tokens[i + 2].length
                  edits << Edit.new(start_pos, end_pos, replacement)
                end
              end
            end

            prev_kind = tok.kind unless tok.kind == TokenKind::Newline
            i += 1
          end

          apply_edits(bytes, edits)
        end

        private def apply_edits(bytes : Bytes, edits : Array(Edit)) : String
          return String.new(bytes) if edits.empty?
          sorted = edits.sort_by(&.start)
          output = String::Builder.new
          pos = 0
          sorted.each do |edit|
            if edit.start > pos
              output.write(bytes[pos...edit.start])
            end
            output << edit.text
            pos = edit.end_pos
          end
          if pos < bytes.size
            output.write(bytes[pos..-1])
          end
          output.to_s
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
          # Visit children to ensure inner defs and nested blocks are transformed
          parts = [] of String
          node.children.each do |child|
            parts << visit(child)
          end
          parts.join
        end

        private def visit_module_def(node : CST::GreenNode) : String
          parts = [] of String
          node.children.each do |child|
            parts << visit(child)
          end
          parts.join
        end

        private def visit_struct_def(node : CST::GreenNode) : String
          parts = [] of String
          node.children.each do |child|
            parts << visit(child)
          end
          parts.join
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
          # Transform &.method to &:method (symbol-to-proc syntax which is idiomatic Ruby)
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
