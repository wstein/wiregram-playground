module Warp
  module Lang
    module Crystal
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
          tokens, lex_error, lex_pos = Lexer.scan(bytes)
          if lex_error != Warp::Core::ErrorCode::Success
            diag = Warp::Diagnostics.lex_error("lex error", bytes, lex_pos, path)
            return Result.new("", lex_error, [diag.to_s], tokens)
          end

          # Parse Crystal CST
          crystal_root, parse_error = CST::Parser.parse(bytes, tokens)
          if parse_error != Warp::Core::ErrorCode::Success
            # We don't have parse position in this primitive prototype yet
            return Result.new("", parse_error, ["parse error"])
          end
          return Result.new("", Warp::Core::ErrorCode::UnexpectedError, ["nil CST root"]) if crystal_root.nil?

          # Transform Crystal CST to Ruby CST (language mapping)
          source = String.new(bytes)
          output = transform_cst_to_ruby(crystal_root, source, bytes)

          Result.new(output, Warp::Core::ErrorCode::Success, [] of String)
        end

        private def self.transform_cst_to_ruby(node : CST::GreenNode, source : String, bytes : Bytes) : String
          case node.kind
          when CST::NodeKind::Root
            # Transform all children and reconstruct
            transform_children(node, source, bytes)
          else
            # For now, simple text replacement of 'require' to 'require_relative'
            source
          end
        end

        private def self.transform_children(node : CST::GreenNode, source : String, bytes : Bytes) : String
          output = source

          # Simple text-based transformation for 'require' -> 'require_relative'
          # Also translate Crystal '&.method' shorthand to Ruby '&:method' (Proc shorthand)
          # This is a basic implementation; a full CST-based approach would traverse the tree
          output = output.gsub(/(\brequire\s+["'])\.\./, "require_relative \"..")
          output = output.gsub(/(\brequire\s+["'])\./, "require_relative \"./")

          # Convert '&.ident' (Crystal method-to-proc shorthand) to Ruby '&:ident'
          output = output.gsub(/&\.(\w+)/, "&:\\1")

          # Insert Sorbet sigs for typed Crystal method definitions and strip types
          lines = output.lines
          transformed = [] of String
          lines.each do |line|
            if (md = line.match(/^([ \t]*)def\s+([A-Za-z0-9_!?=]+)\s*(?:\(([^)]*)\))?\s*(?:\:\s*([^\s]+))?/))
              captures = md.captures
              indent = captures[0] || ""
              method_name = captures[1].to_s
              params_str = captures[2] || ""
              return_type = captures[3]

              params = [] of Warp::Lang::Ruby::Annotations::CrystalMethodParam
              params_str.split(",").each do |p|
                p = p.strip
                next if p.empty?
                if (m2 = p.match(/^@?([A-Za-z0-9_]+)\s*:\s*(.+)$/))
                  pname = m2[1]
                  ptype = m2[2].strip
                elsif (m3 = p.match(/^([A-Za-z0-9_]+)\s*$/))
                  pname = m3[1]
                  ptype = nil
                else
                  next
                end
                params << Warp::Lang::Ruby::Annotations::CrystalMethodParam.new(pname, ptype)
              end

              has_typed_params = params.any? { |pp| !pp.type.nil? }
              next unless has_typed_params || !return_type.nil?

              is_void = return_type.nil? || return_type.strip == "Void"
              sig_struct = Warp::Lang::Ruby::Annotations::CrystalMethodSig.new(method_name, params, return_type, is_void, 0, indent)
              sig_text = Warp::Lang::Ruby::Annotations::CrystalSigBuilder.sorbet_sig_text(sig_struct)

              # Add sig line and stripped def line
              transformed << "#{indent}#{sig_text}\n"
              param_names = params.map(&.name).join(", ")
              transformed << "#{indent}def #{method_name}(#{param_names})\n"
            else
              transformed << line
            end
          end

          output = transformed.join

          output
        end
      end
    end
  end
end
