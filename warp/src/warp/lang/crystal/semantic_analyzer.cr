# Crystal Semantic Analyzer (Phase 3 core)
# Extracts method signatures from Crystal source

module Warp
  module Lang
    module Crystal
      class SemanticAnalyzer
        def initialize(@bytes : Bytes, @tokens : Array(Token))
        end

        def extract_method_sigs : Array(Warp::Lang::Ruby::Annotations::CrystalMethodSig)
          sigs = [] of Warp::Lang::Ruby::Annotations::CrystalMethodSig
          idx = 0
          source = String.new(@bytes)

          while idx < @tokens.size
            tok = @tokens[idx]
            if tok.kind == TokenKind::Def
              def_start = tok.start
              line_start = find_line_start(source, def_start)
              line_end = find_line_end(source, def_start)
              line_text = source.byte_slice(line_start, line_end - line_start)
              indent = line_text[/^\s*/].to_s

              sig = parse_method_signature(line_text, def_start, indent)
              sigs << sig if sig
            end
            idx += 1
          end

          sigs
        end

        private def parse_method_signature(line_text : String, def_start : Int32, indent : String) : Warp::Lang::Ruby::Annotations::CrystalMethodSig?
          return nil unless line_text.includes?("def ")

          # Match def with optional self.
          # def foo(x : Int32, y : String) : Bool
          if (md = line_text.match(/^\s*def\s+((self\.)?([A-Za-z0-9_!?=]+))\s*(\(([^)]*)\))?\s*(?::\s*([^#;]+))?/))
            name = md[2]? ? "self.#{md[3]}" : md[3]
            params_raw = md[5]?
            return_type = md[6]?.try(&.strip)

            params = params_raw ? parse_param_list(params_raw) : [] of Warp::Lang::Ruby::Annotations::CrystalMethodParam

            Warp::Lang::Ruby::Annotations::CrystalMethodSig.new(
              name,
              params,
              return_type.nil? || return_type.empty? ? nil : return_type,
              return_type.nil? || return_type.empty?,
              def_start,
              indent,
            )
          else
            nil
          end
        end

        private def parse_param_list(params_raw : String) : Array(Warp::Lang::Ruby::Annotations::CrystalMethodParam)
          params = [] of Warp::Lang::Ruby::Annotations::CrystalMethodParam
          return params if params_raw.strip.empty?

          parts = split_params(params_raw)
          parts.each do |raw|
            name, type = split_param_and_type(raw)
            next if name.empty?
            params << Warp::Lang::Ruby::Annotations::CrystalMethodParam.new(name, type)
          end

          params
        end

        private def split_params(params_raw : String) : Array(String)
          parts = [] of String
          current = ""
          depth = 0

          params_raw.each_char do |ch|
            case ch
            when '(', '[', '{'
              depth += 1
              current += ch
            when ')', ']', '}'
              depth -= 1
              current += ch
            when ','
              if depth == 0
                parts << current
                current = ""
              else
                current += ch
              end
            else
              current += ch
            end
          end

          parts << current unless current.empty?
          parts
        end

        private def split_param_and_type(raw : String) : {String, String?}
          text = raw.strip
          return {"", nil} if text.empty?

          # remove default values for type parsing
          before_default = text.split("=", 2)[0].strip

          # handle splats and blocks
          name_part = before_default
          type_part = nil

          if (md = before_default.match(/^(\*\*?|&)?([A-Za-z0-9_@]+)\s*:\s*(.+)$/))
            prefix = md[1]? || ""
            name = md[2]
            type_part = md[3].strip
            name_part = "#{prefix}#{name}"
          end

          {name_part, type_part}
        end

        private def find_line_start(source : String, pos : Int32) : Int32
          i = pos - 1
          while i >= 0 && source[i] != '\n'
            i -= 1
          end
          i + 1
        end

        private def find_line_end(source : String, pos : Int32) : Int32
          i = pos
          while i < source.size && source[i] != '\n'
            i += 1
          end
          i
        end
      end
    end
  end
end
