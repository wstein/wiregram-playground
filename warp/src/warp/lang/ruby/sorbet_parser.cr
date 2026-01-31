module Warp::Lang::Ruby
  # SorbetParser extracts type information from Sorbet sig blocks
  # Converts Ruby type syntax to Crystal type syntax
  class SorbetParser
    class MethodSignature
      property params : Hash(String, String) # param_name => crystal_type
      property return_type : String?
      property is_void : Bool

      def initialize
        @params = {} of String => String
        @return_type = nil
        @is_void = false
      end
    end

    # Utility: convert a raw Sorbet type string to Crystal using the parser logic
    def self.convert_type_str(type_str : String) : String
      # Use an instance to call the existing conversion logic (keeps it DRY)
      parser = SorbetParser.new("")
      parser.convert_type_to_crystal(type_str)
    end

    # Utility: convert a Sorbet type string to Crystal, with optional generic context
    # When in_generic_context=true, T.untyped becomes T (the generic parameter)
    def self.convert_type_str(type_str : String, in_generic_context : Bool) : String
      parser = SorbetParser.new("")
      parser.convert_type_to_crystal(type_str, in_generic_context)
    end

    @source : String

    def initialize(@source : String)
    end

    # Parse a sig block and extract type information
    # Returns MethodSignature with Crystal-compatible types
    def parse_sig(sig_text : String, in_generic_context : Bool = false) : MethodSignature
      sig = MethodSignature.new

      # Remove sig wrapper: "sig { ... }" or "sig do ... end"
      content = extract_sig_content(sig_text)
      return sig if content.empty?

      # Parse params and return type
      parse_params(content, sig, in_generic_context)
      parse_return_type(content, sig, in_generic_context)

      sig
    end

    private def extract_sig_content(sig_text : String) : String
      # Remove "sig {" and "}" or "sig do" and "end"
      text = sig_text.strip

      if text.starts_with?("sig {") && text.ends_with?("}")
        text = text[5..-2].strip
      elsif text.starts_with?("sig do") && text.ends_with?("end")
        text = text[6..-4].strip
      end

      text
    end

    private def parse_params(content : String, sig : MethodSignature, in_generic_context : Bool = false) : Void
      # Find "params(...)" section
      params_match = content.match(/params\s*\(\s*/)
      return if params_match.nil?

      # Find the start of params content
      start_idx = (params_match[0].size)

      # Find the closing paren for params() by tracking depth
      depth = 1 # We're already inside one paren
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

      # Parse individual parameters, respecting nested parens and brackets
      current_param = ""
      paren_depth = 0
      bracket_depth = 0

      params_str.each_char do |char|
        case char
        when '('
          paren_depth += 1
          current_param += char
        when ')'
          paren_depth -= 1
          current_param += char
        when '['
          bracket_depth += 1
          current_param += char
        when ']'
          bracket_depth -= 1
          current_param += char
        when ','
          if paren_depth == 0 && bracket_depth == 0
            parse_single_param(current_param, sig, in_generic_context)
            current_param = ""
          else
            current_param += char
          end
        else
          current_param += char
        end
      end

      parse_single_param(current_param, sig, in_generic_context) if !current_param.empty?
    end

    private def parse_single_param(param_str : String, sig : MethodSignature, in_generic_context : Bool = false) : Void
      param_str = param_str.strip
      return if param_str.empty?

      # Format: name: Type
      # Find the first colon (parameter name separator)
      colon_idx = param_str.index(':')
      return if colon_idx.nil?

      name = param_str[0...colon_idx].strip
      type_str = param_str[(colon_idx + 1)..-1].strip

      crystal_type = convert_type_to_crystal(type_str, in_generic_context)
      sig.params[name] = crystal_type
    end

    private def parse_return_type(content : String, sig : MethodSignature, in_generic_context : Bool = false) : Void
      # Check for .void or void
      if content.includes?(".void") || content.includes?("void")
        sig.is_void = true
        return
      end

      # Find returns(...) section (with or without leading dot)
      # Handle nested parentheses in the type: T.nilable(String) etc.
      returns_start = content.index(/\.?returns\s*\(/)
      if returns_start.nil?
        return
      end

      # Find the opening paren
      paren_start = content.index('(', returns_start)
      return if paren_start.nil?

      # Count parentheses to find the matching closing paren
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

      # Extract and convert the type
      if paren_end > paren_start + 1
        return_type_str = content[paren_start + 1...paren_end].strip
        sig.return_type = convert_type_to_crystal(return_type_str, in_generic_context)
      end
    end

    # Convert Sorbet type syntax to Crystal type syntax
    def convert_type_to_crystal(type_str : String, in_generic_context : Bool = false) : String
      type_str = type_str.strip

      # Consult config-driven type mappings first
      begin
        config = TranspilerConfig.new
        mappings = config.get_type_mapping(:crystal)
        if mappings.has_key?(type_str)
          return mappings[type_str]
        end
      rescue
        # If config load fails for any reason, fall back to built-in mapping
      end

      # Handle T.proc.* forms (block types)
      if type_str.starts_with?("T.proc")
        # T.proc.params(...).void / T.proc.params(...).returns(...)
        if type_str.includes?(".params(")
          params_inner = extract_parens_content(type_str, "T.proc.params(")
          param_types = params_inner ? extract_proc_param_types(params_inner) : [] of String

          return_type = "Nil"
          if match = type_str.match(/\.returns\((.+)\)/)
            return_type = convert_type_to_crystal(match[1])
          end

          return param_types.empty? ? "Proc(#{return_type})" : "Proc(#{param_types.join(", ")}, #{return_type})"
        end

        # T.proc.bind(...).void / returns(...)
        if type_str.includes?(".bind(")
          if match = type_str.match(/\.returns\((.+)\)/)
            return "Proc(#{convert_type_to_crystal(match[1])})"
          end
          return "Proc(Nil)"
        end

        # T.proc.void or T.proc.returns(...)
        if type_str.includes?(".void")
          return "Proc(Nil)"
        elsif match = type_str.match(/\.returns\((.+)\)/)
          return "Proc(#{convert_type_to_crystal(match[1])})"
        end

        return "Proc"
      end

      # Handle T.nilable first (before checking for other T. prefixed types)
      if type_str.starts_with?("T.nilable(")
        # Extract what's inside T.nilable(...)
        inner = extract_parens_content(type_str, "T.nilable(")
        if inner
          inner_type = convert_type_to_crystal(inner)
          return "#{inner_type}?"
        end
      end

      # Handle other T. prefixed types
      if type_str.starts_with?("T.")
        rest = type_str[2..-1]
        case rest
        when /^any\((.+)\)$/
          types = $1.split(",").map { |t| convert_type_to_crystal(t.strip) }
          return types.join(" | ")
        when /^all\((.+)\)$/
          # T.all() represents intersection types - Crystal doesn't support these directly
          # Convert to Object as a fallback
          return "Object"
        when "untyped"
          # T.untyped in a generic class context becomes the generic parameter T
          # Otherwise it's an escape hatch for Object
          return in_generic_context ? "T" : "Object"
        when "proc", /^proc\./
          return "Proc"
        else
          # Unknown T.* type, return as-is
          return type_str
        end
      end

      # Handle T::Boolean and other T:: types
      if type_str.starts_with?("T::")
        case type_str
        when "T::Boolean"
          return "Bool"
        when /^T::Array\[/
          # Extract content between [...]: T::Array[String] -> String
          inner = extract_bracket_content(type_str)
          inner_type = convert_type_to_crystal(inner)
          return "Array(#{inner_type})"
        when /^T::Hash\[/
          # Extract content and split on top-level comma
          inner = extract_bracket_content(type_str)
          # Split on the comma that separates key and value types
          key_type, value_type = split_hash_types(inner)
          key_crystal = convert_type_to_crystal(key_type)
          value_crystal = convert_type_to_crystal(value_type)
          return "Hash(#{key_crystal}, #{value_crystal})"
        when /^T::Set\[/
          inner = extract_bracket_content(type_str)
          inner_type = convert_type_to_crystal(inner)
          return "Set(#{inner_type})"
        when /^T::Range\[/
          inner = extract_bracket_content(type_str)
          inner_type = convert_type_to_crystal(inner)
          return "Range(#{inner_type}, #{inner_type})"
        when /^T::Enumerator\[/
          inner = extract_bracket_content(type_str)
          inner_type = convert_type_to_crystal(inner)
          return "Enumerable(#{inner_type})"
        else
          return type_str
        end
      end

      case type_str
      # Basic types
      when "Integer"
        "Int32"
      when "String"
        "String"
      when "Boolean"
        "Bool"
      when "Float"
        "Float64"
      when "Array"
        "Array"
      when "Hash"
        "Hash"
      when "Symbol"
        "Symbol"
      when "True"
        "Bool"
      when "False"
        "Bool"
      when "NilClass"
        "Nil"
      when "void"
        "Nil"
      when "Object"
        "Object"
        # Default: return as-is
      else
        type_str
      end
    end

    private def extract_proc_param_types(params_str : String) : Array(String)
      types = [] of String
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
            type = extract_proc_param_type(current)
            types << type if !type.empty?
            current = ""
          else
            current += char
          end
        else
          current += char
        end
      end

      type = extract_proc_param_type(current)
      types << type if !type.empty?
      types
    end

    private def extract_proc_param_type(param_str : String) : String
      param_str = param_str.strip
      return "" if param_str.empty?

      colon_idx = param_str.index(':')
      return "" if colon_idx.nil?

      type_str = param_str[(colon_idx + 1)..-1].strip
      convert_type_to_crystal(type_str)
    end

    # Extract content from inside parentheses
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

    # Generate Crystal method signature from extracted types
    def generate_crystal_signature(method_name : String, params_ruby : String, sig : MethodSignature) : String
      # Extract parameter names from Ruby signature: def method(x, y:) -> [x, y]
      param_names = extract_param_names(params_ruby)
      param_defaults = extract_param_defaults(params_ruby)
      block_params = extract_block_param_names(params_ruby)

      # Build Crystal signature with types
      crystal_params = param_names.map do |name|
        default = param_defaults[name]?
        param_name = block_params.includes?(name) ? "&#{name}" : name
        if sig.params.has_key?(name)
          type = sig.params[name]
          if type == "untyped"
            default ? "#{param_name} = #{default}" : param_name
          else
            default ? "#{param_name} : #{type} = #{default}" : "#{param_name} : #{type}"
          end
        else
          default ? "#{param_name} = #{default}" : param_name
        end
      end

      # Build signature - only add parentheses if there are parameters or if params_ruby contains parentheses
      if crystal_params.empty? && params_ruby.empty?
        # No parameters and no parens in original - don't add them
        signature = "def #{method_name}"
      elsif crystal_params.empty?
        # No parameters but had parens in original
        signature = "def #{method_name}()"
      else
        # Has parameters
        signature = "def #{method_name}(#{crystal_params.join(", ")})"
      end

      # Add return type if present
      if sig.is_void
        signature += " : Nil"
      elsif sig.return_type && sig.return_type != "untyped"
        signature += " : #{sig.return_type}"
      end

      signature
    end

    private def extract_param_names(params_ruby : String) : Array(String)
      names = [] of String

      # Parse Ruby parameter list
      # Handles: (x, y), (x, y = nil), (x:, y:), (&block)
      current = ""
      depth = 0

      params_ruby.each_char do |char|
        case char
        when '('
          depth += 1
          next if depth == 1
          current += char
        when ')'
          depth -= 1
          next if depth == 0
          current += char
        when ','
          if depth > 1
            current += char
          else
            name = extract_name_from_param(current)
            names << name if !name.empty?
            current = ""
          end
        else
          current += char
        end
      end

      name = extract_name_from_param(current)
      names << name if !name.empty?

      names
    end

    private def extract_param_defaults(params_ruby : String) : Hash(String, String)
      defaults = {} of String => String

      current = ""
      depth = 0

      params_ruby.each_char do |char|
        case char
        when '('
          depth += 1
          next if depth == 1
          current += char
        when ')'
          depth -= 1
          next if depth == 0
          current += char
        when ','
          if depth > 1
            current += char
          else
            store_param_default(current, defaults)
            current = ""
          end
        else
          current += char
        end
      end

      store_param_default(current, defaults)
      defaults
    end

    private def extract_block_param_names(params_ruby : String) : Set(String)
      names = Set(String).new

      current = ""
      depth = 0

      params_ruby.each_char do |char|
        case char
        when '('
          depth += 1
          next if depth == 1
          current += char
        when ')'
          depth -= 1
          next if depth == 0
          current += char
        when ','
          if depth > 1
            current += char
          else
            store_block_param(current, names)
            current = ""
          end
        else
          current += char
        end
      end

      store_block_param(current, names)
      names
    end

    private def store_block_param(param : String, names : Set(String)) : Void
      param = param.strip
      return if param.empty?
      return unless param.starts_with?("&")

      name = extract_name_from_param(param)
      names.add(name) unless name.empty?
    end

    private def store_param_default(param : String, defaults : Hash(String, String)) : Void
      param = param.strip
      return if param.empty?

      name = extract_name_from_param(param)
      return if name.empty?

      if param.includes?("=")
        default = param.split("=")[1].strip
        defaults[name] = default unless default.empty?
      end
    end

    private def extract_bracket_content(type_str : String) : String
      # Extract content between [...]: T::Array[String] -> String
      start_idx = type_str.index('[')
      return "" if start_idx.nil?

      end_idx = type_str.rindex(']')
      return "" if end_idx.nil?

      type_str[(start_idx + 1)...end_idx]
    end

    private def split_hash_types(inner : String) : {String, String}
      # Split "Symbol, Integer" into ["Symbol", "Integer"]
      # But respect nested types like "T.nilable(String), Integer"
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

    private def extract_name_from_param(param : String) : String
      param = param.strip

      # Remove & prefix (block parameters)
      param = param[1..-1] if param.starts_with?("&")

      # Handle: name = default_value
      param = param.split("=")[0] if param.includes?("=")

      # Handle: name: for keyword args
      param = param.rstrip(":")

      param.strip
    end
  end
end
