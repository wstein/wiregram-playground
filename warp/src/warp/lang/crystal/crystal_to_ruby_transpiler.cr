module Warp
  module Lang
    module Crystal
      class CrystalToRubyTranspiler
        struct Result
          property output : String
          property error : Warp::Core::ErrorCode
          property diagnostics : Array(String)

          def initialize(@output, @error, @diagnostics = [] of String)
          end
        end

        def self.transpile(bytes : Bytes) : Result
          tokens, lex_error = Lexer.scan(bytes)
          return Result.new("", lex_error, ["lex error"]) unless lex_error == Warp::Core::ErrorCode::Success

          analyzer = SemanticAnalyzer.new(bytes, tokens)
          sigs = analyzer.extract_method_sigs

          source = String.new(bytes)
          output = apply_sigs_and_strip_types(source, sigs)

          Result.new(output, Warp::Core::ErrorCode::Success, [] of String)
        end

        private def self.apply_sigs_and_strip_types(source : String, sigs : Array(Warp::Lang::Ruby::Annotations::CrystalMethodSig)) : String
          return source if sigs.empty?

          lines = source.lines
          inserts = [] of {Int32, String}

          sigs.each do |sig|
            line_idx = line_index_for(source, sig.def_start)
            next if line_idx < 0

            # Build Sorbet sig and insert before def
            sig_text = Warp::Lang::Ruby::Annotations::CrystalSigBuilder.sorbet_sig_text(sig)
            inserts << {line_idx, "#{sig.def_indent}#{sig_text}"}

            # Strip types from def line
            def_line = lines[line_idx]
            lines[line_idx] = strip_types_from_def(def_line)
          end

          inserts.sort_by! { |i| i[0] }
          offset = 0
          inserts.each do |idx, text|
            insert_at = idx + offset
            lines.insert(insert_at, text)
            offset += 1
          end

          lines.join("\n")
        end

        private def self.strip_types_from_def(line : String) : String
          return line unless line.includes?("def")

          # Handle return type: "def foo(...) : Type" -> "def foo(...)"
          line = line.gsub(/\)\s*:\s*[^#;]+$/, ")")

          # Handle params with types inside parentheses
          if (md = line.match(/^(\s*def\s+[^\(]*\()([^)]*)(\).*)$/))
            head = md[1]
            params = md[2]
            tail = md[3]

            cleaned = params.split(",").map { |p| strip_param_type(p) }.join(", ")
            return "#{head}#{cleaned}#{tail}"
          end

          line
        end

        private def self.strip_param_type(param : String) : String
          text = param.strip
          return text if text.empty?

          # Split default value safely
          parts = text.split("=", 2)
          before_default = parts[0]? || ""
          default_value = parts[1]?
          before_default = before_default.strip

          # Remove type annotations: name : Type
          if (md = before_default.match(/^(\*\*?|&)?([A-Za-z0-9_@]+)\s*:\s*.+$/))
            prefix = md[1]? || ""
            name = md[2]?
            if name
              base = "#{prefix}#{name}"
            else
              base = before_default
            end
          else
            base = before_default
          end

          if default_value
            "#{base} = #{default_value.strip}"
          else
            base
          end
        end

        private def self.line_index_for(source : String, pos : Int32) : Int32
          return -1 if pos < 0
          count = 0
          i = 0
          while i < source.size && i < pos
            count += 1 if source[i] == '\n'
            i += 1
          end
          count
        end
      end
    end
  end
end
