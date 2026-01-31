module Warp::Lang::Ruby::Annotations
  class RbsMethodSignature
    property params : Hash(String, String)
    property return_type : String?
    property is_void : Bool

    def initialize
      @params = {} of String => String
      @return_type = nil
      @is_void = false
    end
  end

  # Parse Sorbet sig blocks and convert types to RBS-compatible types.
  class SorbetRbsParser
    @sig_text : String

    def initialize(@sig_text : String)
    end

    def parse_sig : RbsMethodSignature
      sig = RbsMethodSignature.new
      content = extract_sig_content(@sig_text)
      return sig if content.empty?

      parse_params(content, sig)
      parse_return_type(content, sig)
      sig
    end

    private def extract_sig_content(sig_text : String) : String
      text = sig_text.strip
      if text.starts_with?("sig {") && text.ends_with?("}")
        text = text[5..-2].strip
      elsif text.starts_with?("sig do") && text.ends_with?("end")
        text = text[6..-4].strip
      end
      text
    end

    private def parse_params(content : String, sig : RbsMethodSignature) : Void
      params_match = content.match(/params\s*\(\s*/)
      return if params_match.nil?
      start_idx = params_match[0].size

      depth = 1
      params_end = start_idx
      content[start_idx..-1].each_char_with_index do |char, idx|
        case char
        when '('
          depth += 1
        when ')'
          depth -= 1
          if depth == 0
            params_end = start_idx + idx
            break
          end
        end
      end

      params_str = content[start_idx...params_end].strip
      current = ""
      paren_depth = 0
      bracket_depth = 0

      params_str.each_char do |char|
        case char
        when '('
          paren_depth += 1
          current += char
        when ')'
          paren_depth -= 1
          current += char
        when '['
          bracket_depth += 1
          current += char
        when ']'
          bracket_depth -= 1
          current += char
        when ','
          if paren_depth == 0 && bracket_depth == 0
            parse_single_param(current, sig)
            current = ""
          else
            current += char
          end
        else
          current += char
        end
      end

      parse_single_param(current, sig) if !current.empty?
    end

    private def parse_single_param(param_str : String, sig : RbsMethodSignature) : Void
      p = param_str.strip
      return if p.empty?
      colon_idx = p.index(':')
      return if colon_idx.nil?
      name = p[0...colon_idx].strip
      type_str = p[(colon_idx + 1)..-1].strip
      sig.params[name] = convert_type_to_rbs(type_str)
    end

    private def parse_return_type(content : String, sig : RbsMethodSignature) : Void
      if content.includes?(".void") || content.includes?("void")
        sig.is_void = true
        return
      end

      returns_start = content.index(/\.?returns\s*\(/)
      return if returns_start.nil?

      paren_start = content.index('(', returns_start)
      return if paren_start.nil?

      depth = 1
      pos = paren_start + 1
      paren_end = pos
      while pos < content.size && depth > 0
        case content[pos]
        when '('
          depth += 1
        when ')'
          depth -= 1
          if depth == 0
            paren_end = pos
            break
          end
        end
        pos += 1
      end

      if paren_end > paren_start + 1
        return_type_str = content[paren_start + 1...paren_end].strip
        sig.return_type = convert_type_to_rbs(return_type_str)
      end
    end

    private def convert_type_to_rbs(type_str : String) : String
      t = type_str.strip
      return "untyped" if t == "T.untyped"

      if t.starts_with?("T.nilable(")
        inner = extract_parens_content(t, "T.nilable(")
        return inner ? "#{convert_type_to_rbs(inner)}?" : "untyped"
      end

      if t.starts_with?("T.any(")
        inner = extract_parens_content(t, "T.any(")
        return "untyped" unless inner
        parts = split_args(inner)
        return parts.map { |p| convert_type_to_rbs(p) }.join(" | ")
      end

      if t.starts_with?("T.all(")
        inner = extract_parens_content(t, "T.all(")
        return "untyped" unless inner
        parts = split_args(inner)
        return parts.map { |p| convert_type_to_rbs(p) }.join(" & ")
      end

      if t.starts_with?("T::Array[")
        inner = extract_bracket_content(t)
        return "Array[#{convert_type_to_rbs(inner)}]"
      end

      if t.starts_with?("T::Hash[")
        inner = extract_bracket_content(t)
        key, value = split_hash_types(inner)
        return "Hash[#{convert_type_to_rbs(key)}, #{convert_type_to_rbs(value)}]"
      end

      if t == "T::Boolean"
        return "bool"
      end

      case t
      when "Integer", "String", "Symbol", "Float", "Regexp"
        t
      when "NilClass"
        "nil"
      else
        t
      end
    end

    private def extract_parens_content(text : String, prefix : String) : String?
      return nil unless text.starts_with?(prefix)
      start_idx = prefix.size
      depth = 1
      current = ""
      text[start_idx..-1].each_char do |char|
        case char
        when '('
          depth += 1
          current += char
        when ')'
          depth -= 1
          break if depth == 0
          current += char
        else
          current += char
        end
      end
      depth == 0 ? current : nil
    end

    private def extract_bracket_content(type_str : String) : String
      start_idx = type_str.index('[')
      return "" if start_idx.nil?
      end_idx = type_str.rindex(']')
      return "" if end_idx.nil?
      type_str[(start_idx + 1)...end_idx]
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

    private def split_hash_types(inner : String) : {String, String}
      depth = 0
      key_part = ""
      value_part = ""
      found_comma = false
      inner.each_char do |char|
        case char
        when '(', '[', '{'
          depth += 1
          found_comma ? (value_part += char) : (key_part += char)
        when ')', ']', '}'
          depth -= 1
          found_comma ? (value_part += char) : (key_part += char)
        when ','
          if depth == 0 && !found_comma
            found_comma = true
          else
            found_comma ? (value_part += char) : (key_part += char)
          end
        else
          found_comma ? (value_part += char) : (key_part += char)
        end
      end
      {key_part.strip, value_part.strip}
    end
  end
end
