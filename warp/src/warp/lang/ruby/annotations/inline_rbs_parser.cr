module Warp::Lang::Ruby::Annotations
  # Parses inline RBS comments of the form:
  #   # @rbs (String, Integer) -> String
  # and associates them with the next method definition line.
  class InlineRbsParser
    INLINE_REGEX = /^\s*#\s*@rbs\s*\((.*)\)\s*->\s*(.+)\s*$/

    def parse(source : String) : Hash(String, RbsMethodSignature)
      signatures = {} of String => RbsMethodSignature
      lines = source.lines
      i = 0
      while i < lines.size
        line = lines[i]
        if (md = line.match(INLINE_REGEX))
          params_str = md[1]
          return_str = md[2]
          method_name = find_next_method_name(lines, i + 1)
          if method_name
            sig = RbsMethodSignature.new
            sig.is_void = return_str.strip == "void"
            sig.return_type = sig.is_void ? nil : return_str.strip
            parse_params(params_str, sig)
            signatures[method_name] = sig
          end
        end
        i += 1
      end
      signatures
    end

    private def find_next_method_name(lines : Array(String), start_idx : Int32) : String?
      i = start_idx
      while i < lines.size
        line = lines[i].strip
        if (md = line.match(/^def\s+(self\.)?([A-Za-z0-9_!?=]+)/))
          prefix = md[1]?
          name = md[2]
          return prefix ? "self.#{name}" : name
        end
        i += 1
      end
      nil
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
