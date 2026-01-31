module Warp::Lang::Ruby::Annotations
  # Minimal RBS parser for method signatures.
  # Supports:
  #   def foo: (String, Integer) -> String
  #   def self.bar: () -> void
  class RbsFileParser
    def parse(source : String) : Hash(String, RbsMethodSignature)
      signatures = {} of String => RbsMethodSignature
      namespace = [] of String

      source.lines.each do |line|
        stripped = line.strip
        next if stripped.empty? || stripped.starts_with?("#")

        if (md = stripped.match(/^class\s+([A-Za-z0-9_:]+)/))
          namespace << md[1]
          next
        end

        if (md = stripped.match(/^module\s+([A-Za-z0-9_:]+)/))
          namespace << md[1]
          next
        end

        if stripped == "end"
          namespace.pop?
          next
        end

        if (md = stripped.match(/^def\s+(self\.)?([A-Za-z0-9_!?=]+):\s*\((.*)\)\s*->\s*(.+)$/))
          is_self = !md[1]?.nil?
          name = md[2]
          params_str = md[3]
          return_str = md[4]
          full_name = namespace.empty? ? name : "#{namespace.join("::")}.#{name}"
          full_name = "self.#{full_name}" if is_self

          sig = RbsMethodSignature.new
          sig.is_void = return_str.strip == "void"
          sig.return_type = sig.is_void ? nil : return_str.strip
          parse_params(params_str, sig)
          signatures[full_name] = sig
        end
      end

      signatures
    end

    private def parse_params(params_str : String, sig : RbsMethodSignature)
      return if params_str.strip.empty?
      parts = split_args(params_str)
      parts.each_with_index do |p, idx|
        part = p.strip
        if part.includes?(":")
          key, type = part.split(":", 2)
          sig.params[key.strip] = type.strip
        else
          sig.params["arg#{idx}"] = part
        end
      end
    end

    private def split_args(text : String) : Array(String)
      parts = [] of String
      current = ""
      depth = 0
      text.each_char do |char|
        case char
        when '(', '[', '{'
          depth += 1
          current += char
        when ')', ']', '}'
          depth -= 1
          current += char
        when ','
          if depth == 0
            parts << current.strip
            current = ""
          else
            current += char
          end
        else
          current += char
        end
      end
      parts << current.strip unless current.strip.empty?
      parts
    end
  end
end
