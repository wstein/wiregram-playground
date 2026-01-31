module Warp::Lang::Ruby
  # Analyzer identifies transformation targets in the CST
  # For Ruby→Crystal: finds sig blocks to remove and method signatures to add types
  # For Ruby→Ruby: finds Sorbet sigs to convert to RBS annotations
  class Analyzer
    enum TransformKind
      RemoveSig       # Remove a Sorbet sig block
      AddMethodType   # Add type annotation to method definition
      ConvertToRBS    # Convert Sorbet sig to RBS annotation (Ruby→Ruby)
      CommentOutLine  # Comment out a line (e.g., require 'sorbet-runtime')
      RemoveLine      # Remove a line entirely
      RemoveCast      # Remove a Sorbet cast (T.let, T.must, etc.)
      ReplaceVariable # Replace a variable reference (e.g., @var with @@var in class methods)
      InsertText      # Insert text at a given position
    end

    struct Transformation
      property kind : TransformKind
      property start : Int32
      property end_pos : Int32
      property replacement : String?

      def initialize(@kind, @start, @end_pos, @replacement = nil)
      end
    end

    @bytes : Bytes
    @tokens : Array(Token)
    @cst : CST::GreenNode
    @target_lang : Symbol # :crystal or :ruby
    @source : String
    @pending_sig : Hash(String, String)? # Store sig info for next method
    @last_sig_text : String?
    @config : TranspilerConfig

    def initialize(@bytes, @tokens, @cst, @target_lang = :crystal, @config = TranspilerConfig.new)
      @source = String.new(@bytes)
      @pending_sig = nil
      @last_sig_text = nil
    end

    # Analyze the CST and return list of transformations
    def analyze : Array(Transformation)
      transformations = [] of Transformation

      # First pass: handle library imports based on config
      analyze_library_imports(transformations)

      # Second pass: find sig blocks and method definitions
      analyze_node(@cst, transformations)

      # Third pass: handle Sorbet constructs in method bodies
      analyze_sorbet_constructs(transformations)

      # Fourth pass: apply CST/token-based cleanup transforms
      analyze_literal_and_runtime_cleanups(transformations)

      transformations
    end

    # Apply library-specific transformations from config
    private def analyze_library_imports(transformations : Array(Transformation)) : Void
      source = @source

      # Handle sorbet-runtime require
      if source.includes?("require 'sorbet-runtime'") || source.includes?("require \"sorbet-runtime\"")
        rule = @config.get_library_rule(@target_lang, "sorbet-runtime")
        if rule && rule.action == "comment_out"
          # Find the exact position and apply transformation
          if match = source.match(/require\s+['\"]sorbet-runtime['\"]/m)
            start_pos = match.begin
            end_pos = match.end

            # Find the end of line
            line_end = source.index('\n', end_pos) || source.size

            replacement = rule.replacement || "# Sorbet runtime removed (Ruby-specific)"
            transformations << Transformation.new(
              TransformKind::CommentOutLine,
              start_pos,
              line_end,
              replacement
            )
          end
        end
      end

      # Handle extend T::* declarations - remove all Sorbet-specific extends
      # This includes T::Sig, T::Generic, T::Helpers, etc.
      pattern = Regex.new("^\\s*extend\\s+T::\\w+\\s*$", Regex::Options::MULTILINE)
      source.scan(pattern) do |match|
        line_start_pos = match.begin(0)

        # For all Sorbet extends, remove them
        # Find the actual start of the line (including leading whitespace)
        line_start = line_start_pos
        j = line_start_pos - 1
        while j >= 0 && source[j] != '\n'
          j -= 1
        end
        line_start = j + 1

        # Find line end including newline
        line_end = source.index('\n', match.end(0)) || source.size
        if line_end < source.size && source[line_end] == '\n'
          line_end += 1
        end

        # Remove the entire line completely
        transformations << Transformation.new(
          TransformKind::RemoveLine,
          line_start,
          line_end
        )
      end

      # Remove Ruby-only DSL helpers like attr_reader, attr_writer, attr_accessor
      # For attr_reader, convert to getter methods
      attr_pattern = Regex.new("^(\\s*)attr_reader\\s+:(\\w+)", Regex::Options::MULTILINE)
      source.scan(attr_pattern) do |match|
        line_start_pos = match.begin(0)
        indent = match[1]
        attr_name = match[2]

        line_start = line_start_pos
        j = line_start_pos - 1
        while j >= 0 && source[j] != '\n'
          j -= 1
        end
        line_start = j + 1

        line_end = source.index('\n', match.end(0)) || source.size
        if line_end < source.size && source[line_end] == '\n'
          line_end += 1
        end

        # Replace with getter method
        getter_method = "#{indent}def #{attr_name}\n#{indent}  @#{attr_name}\n#{indent}end"
        transformations << Transformation.new(
          TransformKind::RemoveCast,
          line_start,
          line_end,
          getter_method
        )
      end

      # Remove attr_writer and attr_accessor (not converting for now)
      other_attr_pattern = Regex.new("^\\s*(attr_writer|attr_accessor)\\s+", Regex::Options::MULTILINE)
      source.scan(other_attr_pattern) do |match|
        line_start_pos = match.begin(0)
        line_start = line_start_pos
        j = line_start_pos - 1
        while j >= 0 && source[j] != '\n'
          j -= 1
        end
        line_start = j + 1

        line_end = source.index('\n', match.end(0)) || source.size
        if line_end < source.size && source[line_end] == '\n'
          line_end += 1
        end

        transformations << Transformation.new(
          TransformKind::RemoveLine,
          line_start,
          line_end
        )
      end

      # Remove standalone Sorbet type expressions (orphaned types not in assignments)
      sorbet_type_pattern = Regex.new("^\\s*T::(Array|Hash|Set|Range|Enumerator)\\[", Regex::Options::MULTILINE)
      source.scan(sorbet_type_pattern) do |match|
        line_start_pos = match.begin(0)
        line_start = line_start_pos
        j = line_start_pos - 1
        while j >= 0 && source[j] != '\n'
          j -= 1
        end
        line_start = j + 1

        line_end = source.index('\n', match.end(0)) || source.size
        if line_end < source.size && source[line_end] == '\n'
          line_end += 1
        end

        # Check if this is a standalone expression (not part of assignment)
        line_text = source.byte_slice(line_start, line_end - line_start).strip
        if line_text !~ /=/
          transformations << Transformation.new(
            TransformKind::RemoveLine,
            line_start,
            line_end
          )
        end
      end
    end

    # Apply Sorbet construct transformations (T.let, T.must, etc.) using proper parsing
    # Skip constructs that are inside sig blocks (which will be removed entirely)
    private def analyze_sorbet_constructs(transformations : Array(Transformation)) : Void
      return unless @target_lang == :crystal

      # First, collect all sig block ranges that will be removed
      sig_block_ranges = [] of {start: Int32, end_pos: Int32}
      transformations.each do |t|
        if t.kind == TransformKind::RemoveSig
          sig_block_ranges << {start: t.start, end_pos: t.end_pos}
        end
      end

      # Use SorbetConstructParser to find all Sorbet constructs
      parser = SorbetConstructParser.new(@source)

      # Helper to check if a position is inside any sig block range
      is_in_sig_block = ->(pos : Int32) do
        sig_block_ranges.any? { |range| pos >= range[:start] && pos < range[:end_pos] }
      end

      # Handle T.let calls (but not in sig blocks)
      t_let_calls = parser.find_all_t_let_calls
      t_let_calls.each do |call|
        next if is_in_sig_block.call(call[:start])
        handle_parsed_t_let(call, transformations)
      end

      skip_ranges = t_let_calls.map { |c| {start: c[:start], end_pos: c[:end_pos]} }

      # Handle T.must calls
      parser.find_all_t_method_calls("must").each do |call|
        next if is_in_sig_block.call(call[:start])
        skip_ranges << {start: call[:start], end_pos: call[:end_pos]}
        transformations << Transformation.new(
          TransformKind::RemoveCast,
          call[:start],
          call[:end_pos],
          call[:value]
        )
      end

      # Handle T.unsafe calls
      parser.find_all_t_method_calls("unsafe").each do |call|
        next if is_in_sig_block.call(call[:start])
        skip_ranges << {start: call[:start], end_pos: call[:end_pos]}
        transformations << Transformation.new(
          TransformKind::RemoveCast,
          call[:start],
          call[:end_pos],
          call[:value]
        )
      end

      # Handle T.cast calls
      parser.find_all_t_method_calls("cast").each do |call|
        next if is_in_sig_block.call(call[:start])
        skip_ranges << {start: call[:start], end_pos: call[:end_pos]}
        transformations << Transformation.new(
          TransformKind::RemoveCast,
          call[:start],
          call[:end_pos],
          call[:value]
        )
      end

      # Handle advanced Sorbet types that don't have Crystal equivalents
      type_calls = parser.find_all_sorbet_types
      type_alias_ranges = type_calls
        .select { |c| c[:original].starts_with?("T.type_alias") }
        .map { |c| {start: c[:start], end_pos: c[:end_pos]} }

      skip_ranges.concat(type_alias_ranges)

      is_in_skip_range = ->(start_pos : Int32, end_pos : Int32) do
        skip_ranges.any? { |range| start_pos >= range[:start] && end_pos <= range[:end_pos] }
      end

      type_calls.each do |type_call|
        next if is_in_sig_block.call(type_call[:start])
        is_type_alias = type_call[:original].starts_with?("T.type_alias")
        next if !is_type_alias && is_in_skip_range.call(type_call[:start], type_call[:end_pos])
        transformations << Transformation.new(
          TransformKind::RemoveCast,
          type_call[:start],
          type_call[:end_pos],
          type_call[:replacement]
        )
      end

      # Handle rescue clause syntax conversion
      # Ruby: rescue ExceptionType => e  ->  Crystal: rescue e : ExceptionType
      analyze_rescue_clauses(transformations)

      # Remove Sorbet helper calls like interface! and abstract!
      analyze_sorbet_helper_calls(transformations)

      # Replace instance_eval(&blk) with blk.call for Crystal compatibility
      analyze_instance_eval_calls(transformations)

      # Replace Ruby reflection helpers for instance/class variables
      analyze_variable_reflection_calls(transformations)
    end

    private def analyze_literal_and_runtime_cleanups(transformations : Array(Transformation)) : Void
      return unless @target_lang == :crystal

      # Collect sig block ranges to avoid rewriting removed blocks
      sig_block_ranges = [] of {start: Int32, end_pos: Int32}
      transformations.each do |t|
        if t.kind == TransformKind::RemoveSig
          sig_block_ranges << {start: t.start, end_pos: t.end_pos}
        end
      end

      in_sig_block = ->(start_pos : Int32, end_pos : Int32) do
        sig_block_ranges.any? { |range| start_pos >= range[:start] && end_pos <= range[:end_pos] }
      end

      # Single-quoted string conversion is skipped because it can interfere with method receivers
      # (e.g., ENV['USER'] where the 'USER' is not a standalone string but part of an indexing operation)

      analyze_symbol_literals(transformations, in_sig_block)
      analyze_type_aliases(transformations, in_sig_block) # Re-enabled: proper CST-based analysis
      analyze_message_slicing(transformations, in_sig_block)
      analyze_main_guard(transformations, in_sig_block)
    end

    private def analyze_single_quoted_strings(
      transformations : Array(Transformation),
      in_sig_block : Proc(Int32, Int32, Bool),
    ) : Void
      @tokens.each do |tok|
        if tok.kind == TokenKind::String
          start_pos = tok.start
          end_pos = tok.start + tok.length
          unless in_sig_block.call(start_pos, end_pos)
            text = @source.byte_slice(start_pos, tok.length)
            if text.starts_with?("'") && text.ends_with?("'")
              content = text[1...-1]
              replacement = build_raw_string_literal(content)

              transformations << Transformation.new(
                TransformKind::RemoveCast,
                start_pos,
                end_pos,
                replacement
              )
            end
          end
        end
      end
    end

    private def build_raw_string_literal(content : String) : String
      delimiters = [
        {"(", ")"},
        {"[", "]"},
        {"{", "}"},
        {"<", ">"},
      ]

      delimiters.each do |pair|
        open_delim = pair[0]
        close_delim = pair[1]
        unless content.includes?(close_delim)
          return "%q#{open_delim}#{content}#{close_delim}"
        end
      end

      escaped = content.gsub("\\", "\\\\").gsub("\"", "\\\"")
      "\"#{escaped}\""
    end

    private def analyze_instance_eval_calls(transformations : Array(Transformation)) : Void
      source = @source
      pattern = /(\w+)\.instance_eval\s*\(&([a-zA-Z_]\w*)\)/
      source.scan(pattern) do |match|
        match_start = match.begin(0)
        match_end = match.end(0)
        block_name = match[2]
        replacement = "#{block_name}.call"

        transformations << Transformation.new(
          TransformKind::RemoveCast,
          match_start,
          match_end,
          replacement
        )
      end
    end

    private def analyze_variable_reflection_calls(transformations : Array(Transformation)) : Void
      source = @source

      instance_get = /\.instance_variable_get\(\s*:"@([a-zA-Z_]\w*)"\s*\)/
      source.scan(instance_get) do |match|
        start_pos = match.begin(0)
        end_pos = match.end(0)
        var_name = match[1]
        transformations << Transformation.new(
          TransformKind::RemoveCast,
          start_pos,
          end_pos,
          ".#{var_name}"
        )
      end

      class_set = /(\w+)\.class_variable_set\(\s*:"@@([a-zA-Z_]\w*)"\s*,\s*([^\)]+)\)/
      source.scan(class_set) do |match|
        start_pos = match.begin(0)
        end_pos = match.end(0)
        class_name = match[1]
        var_name = match[2]
        value = match[3]
        transformations << Transformation.new(
          TransformKind::RemoveCast,
          start_pos,
          end_pos,
          "#{class_name}.#{var_name} = #{value}"
        )
      end

      class_get = /(\w+)\.class_variable_get\(\s*:"@@([a-zA-Z_]\w*)"\s*\)/
      source.scan(class_get) do |match|
        start_pos = match.begin(0)
        end_pos = match.end(0)
        class_name = match[1]
        var_name = match[2]
        transformations << Transformation.new(
          TransformKind::RemoveCast,
          start_pos,
          end_pos,
          "#{class_name}.#{var_name}"
        )
      end
    end

    private def analyze_sorbet_helper_calls(transformations : Array(Transformation)) : Void
      source = @source
      pattern = Regex.new("^\\s*(interface!|abstract!)\\s*$", Regex::Options::MULTILINE)
      source.scan(pattern) do |match|
        line_start_pos = match.begin(0)
        line_start = line_start_pos
        j = line_start_pos - 1
        while j >= 0 && source[j] != '\n'
          j -= 1
        end
        line_start = j + 1

        line_end = source.index('\n', match.end(0)) || source.size
        if line_end < source.size && source[line_end] == '\n'
          line_end += 1
        end

        transformations << Transformation.new(
          TransformKind::RemoveLine,
          line_start,
          line_end
        )
      end
    end

    private def analyze_class_method_variables(transformations : Array(Transformation)) : Void
      # TODO: Implement this feature more carefully
      # The challenge is correctly identifying method boundaries and avoiding
      # converting instance variables in regular instance methods
      #
      # For now, we skip this transformation as it requires proper AST-level
      # analysis to correctly distinguish between class methods and instance methods
      # within the same class context.
    end

    private def analyze_rescue_clauses(transformations : Array(Transformation)) : Void
      source = @source

      # Match Ruby rescue syntax: rescue ExceptionType => var
      # Pattern: rescue followed by optional exception type and =>
      pattern = /rescue\s+(\w+(?:::\w+)*)\s*=>\s*(\w+)/
      source.scan(pattern) do |match|
        exception_type = match[1]
        variable_name = match[2]
        match_start = match.begin(0)
        match_end = match.end(0)

        # Convert to Crystal syntax: rescue var : ExceptionType
        # If NoMethodError isn't available, fall back to a generic rescue
        crystal_rescue = exception_type == "NoMethodError" ? "rescue #{variable_name}" : "rescue #{variable_name} : #{exception_type}"

        transformations << Transformation.new(
          TransformKind::RemoveCast,
          match_start,
          match_end,
          crystal_rescue
        )
      end
    end

    private def analyze_symbol_literals(
      transformations : Array(Transformation),
      in_sig_block : Proc(Int32, Int32, Bool),
    ) : Void
      idx = 0
      while idx < @tokens.size - 1
        tok = @tokens[idx]
        next_tok = @tokens[idx + 1]

        if tok.kind == TokenKind::Colon &&
           (next_tok.kind == TokenKind::InstanceVar || next_tok.kind == TokenKind::ClassVar || next_tok.kind == TokenKind::GlobalVar)
          # Ensure adjacency (no whitespace between ':' and the var token)
          if tok.start + tok.length == next_tok.start
            start_pos = tok.start
            end_pos = next_tok.start + next_tok.length
            unless in_sig_block.call(start_pos, end_pos)
              var_text = @source.byte_slice(next_tok.start, next_tok.length)
              replacement = ":\"#{var_text}\""

              transformations << Transformation.new(
                TransformKind::RemoveCast,
                start_pos,
                end_pos,
                replacement
              )
            end
          end
        end

        idx += 1
      end
    end

    private def analyze_freeze_calls(
      transformations : Array(Transformation),
      in_sig_block : Proc(Int32, Int32, Bool),
    ) : Void
      idx = 0
      while idx < @tokens.size - 1
        tok = @tokens[idx]
        next_tok = @tokens[idx + 1]

        if tok.kind == TokenKind::Dot && next_tok.kind == TokenKind::Identifier
          name = token_text(next_tok)
          if name == "freeze" && tok.start + tok.length == next_tok.start
            start_pos = tok.start
            end_pos = next_tok.start + next_tok.length
            unless in_sig_block.call(start_pos, end_pos)
              transformations << Transformation.new(
                TransformKind::RemoveCast,
                start_pos,
                end_pos,
                ""
              )
            end
          end
        end

        idx += 1
      end
    end

    private def analyze_type_aliases(
      transformations : Array(Transformation),
      in_sig_block : Proc(Int32, Int32, Bool),
    ) : Void
      idx = 0
      while idx < @tokens.size
        tok = @tokens[idx]
        if tok.kind == TokenKind::Identifier || tok.kind == TokenKind::Constant
          name_tok = tok
          name_text = token_text(name_tok)

          j = next_non_trivia_index(idx + 1)
          if j >= 0 && @tokens[j].kind == TokenKind::Equal
            j = next_non_trivia_index(j + 1)
            if j >= 0 && token_text(@tokens[j]) == "T"
              j = next_non_trivia_index(j + 1)
              if j >= 0 && @tokens[j].kind == TokenKind::Dot
                j = next_non_trivia_index(j + 1)
                if j >= 0 && @tokens[j].kind == TokenKind::Identifier && token_text(@tokens[j]) == "type_alias"
                  j = next_non_trivia_index(j + 1)
                  if j >= 0 && @tokens[j].kind == TokenKind::LBrace
                    brace_start = @tokens[j]
                    depth = 1
                    k = j + 1
                    while k < @tokens.size && depth > 0
                      case @tokens[k].kind
                      when TokenKind::LBrace
                        depth += 1
                      when TokenKind::RBrace
                        depth -= 1
                      end
                      k += 1
                    end
                    if depth == 0
                      brace_end = @tokens[k - 1]
                      inner_start = brace_start.start + brace_start.length
                      inner_end = brace_end.start
                      if inner_end >= inner_start
                        start_pos = name_tok.start
                        end_pos = brace_end.start + brace_end.length
                        unless in_sig_block.call(start_pos, end_pos)
                          inner_text = @source.byte_slice(inner_start, inner_end - inner_start).strip
                          converted = SorbetParser.convert_type_str(inner_text)
                          replacement = "alias #{name_text} = #{converted}"

                          transformations << Transformation.new(
                            TransformKind::RemoveCast,
                            start_pos,
                            end_pos,
                            replacement
                          )
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

        idx += 1
      end
    end

    private def analyze_message_slicing(
      transformations : Array(Transformation),
      in_sig_block : Proc(Int32, Int32, Bool),
    ) : Void
      idx = 0
      while idx < @tokens.size - 8
        recv = @tokens[idx]
        dot = @tokens[idx + 1]
        msg = @tokens[idx + 2]
        lbr = @tokens[idx + 3]
        num0 = @tokens[idx + 4]
        dot1 = @tokens[idx + 5]
        dot2 = @tokens[idx + 6]
        num50 = @tokens[idx + 7]
        rbr = @tokens[idx + 8]

        if (recv.kind == TokenKind::Identifier || recv.kind == TokenKind::Constant) &&
           dot.kind == TokenKind::Dot && msg.kind == TokenKind::Identifier && token_text(msg) == "message" &&
           lbr.kind == TokenKind::LBracket && num0.kind == TokenKind::Number && token_text(num0) == "0" &&
           dot1.kind == TokenKind::Dot && dot2.kind == TokenKind::Dot &&
           num50.kind == TokenKind::Number && token_text(num50) == "50" && rbr.kind == TokenKind::RBracket
          start_pos = recv.start
          end_pos = rbr.start + rbr.length
          next if in_sig_block.call(start_pos, end_pos)

          recv_text = @source.byte_slice(recv.start, recv.length)
          replacement = "#{recv_text}.message.to_s[0..50]"

          transformations << Transformation.new(
            TransformKind::RemoveCast,
            start_pos,
            end_pos,
            replacement
          )
        end

        idx += 1
      end
    end

    private def analyze_main_guard(
      transformations : Array(Transformation),
      in_sig_block : Proc(Int32, Int32, Bool),
    ) : Void
      idx = 0
      while idx < @tokens.size
        recv = @tokens[idx]

        # Check if this is Method.main (receiver, dot, method name "main")
        if recv.kind == TokenKind::Identifier || recv.kind == TokenKind::Constant
          j = next_non_trivia_index(idx + 1)
          if j >= 0 && @tokens[j].kind == TokenKind::Dot
            dot = @tokens[j]
            k = next_non_trivia_index(j + 1)
            if k >= 0 && @tokens[k].kind == TokenKind::Identifier && token_text(@tokens[k]) == "main"
              meth = @tokens[k]
              # Now look for: if __FILE__ == ($0 or $PROGRAM_NAME)
              m = next_non_trivia_index(k + 1)
              if m >= 0 && @tokens[m].kind == TokenKind::If
                kw_if = @tokens[m]
                n = next_non_trivia_index(m + 1)
                # __FILE__ can be Constant or Identifier  depending on context
                if n >= 0 && (token_text(@tokens[n]) == "__FILE__")
                  file_const = @tokens[n]
                  p_idx = next_non_trivia_index(n + 1)
                  if p_idx >= 0 && @tokens[p_idx].kind == TokenKind::Equal
                    eq = @tokens[p_idx]
                    q_idx = next_non_trivia_index(p_idx + 1)
                    if q_idx >= 0 && @tokens[q_idx].kind == TokenKind::GlobalVar
                      gvar = @tokens[q_idx]
                      if token_text(gvar) == "$0" || token_text(gvar) == "$PROGRAM_NAME"
                        start_pos = recv.start
                        end_pos = gvar.start + gvar.length
                        unless in_sig_block.call(start_pos, end_pos)
                          # Just remove the entire "if __FILE__ == $..." guard
                          transformations << Transformation.new(
                            TransformKind::RemoveCast,
                            start_pos,
                            end_pos,
                            nil # No replacement - just remove it
                          )
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

        idx += 1
      end
    end

    private def next_non_trivia_index(start_idx : Int32) : Int32
      idx = start_idx
      while idx < @tokens.size
        kind = @tokens[idx].kind
        if kind != TokenKind::Whitespace && kind != TokenKind::Newline && kind != TokenKind::CommentLine
          return idx
        end
        idx += 1
      end
      -1
    end

    private def token_text(token : Token) : String
      @source.byte_slice(token.start, token.length)
    end

    # Handle a parsed T.let call
    private def handle_parsed_t_let(call : NamedTuple(start: Int32, end_pos: Int32, value: String, type: String), transformations : Array(Transformation)) : Void
      value = call[:value]
      type_str = call[:type]

      # Special handling for empty arrays: T.let([], T::Array[Type]) -> [] of Type
      if value.strip == "[]" && type_str =~ /T::Array\s*\[\s*([^\]]+)\s*\]/
        element_type_raw = $1.strip
        # Use the central converter so config mappings are applied consistently
        element_type = SorbetParser.convert_type_str(element_type_raw)
        replacement = "[] of #{element_type}"
        transformations << Transformation.new(
          TransformKind::RemoveCast,
          call[:start],
          call[:end_pos],
          replacement
        )
        # Special handling for T.nilable types: T.let(value, T.nilable(Type)) -> just value (Crystal infers nilable types)
      elsif type_str =~ /T\.nilable\s*\(\s*([^)]+)\s*\)/
        # Convert single quotes in value to double quotes for Crystal
        crystal_value = value.gsub(/'([^']*)'/, "\"\\1\"")
        # Just keep the value - Crystal will infer the nilable type
        transformations << Transformation.new(
          TransformKind::RemoveCast,
          call[:start],
          call[:end_pos],
          crystal_value
        )
      else
        # Just keep the value part
        transformations << Transformation.new(
          TransformKind::RemoveCast,
          call[:start],
          call[:end_pos],
          value
        )
      end
    end

    private def analyze_node(node : CST::GreenNode, transformations : Array(Transformation))
      case node.kind
      when CST::NodeKind::SorbetSig
        handle_sig_block(node, transformations)
      when CST::NodeKind::MethodDef
        handle_method_def(node, transformations)
      else
        # Recurse into children
        node.children.each do |child|
          analyze_node(child, transformations)
        end
      end
    end

    # Store the last sig block text for the next method
    private def store_sig_for_next_method(sig_text : String) : Void
      @last_sig_text = sig_text
    end

    private def handle_sig_block(node : CST::GreenNode, transformations : Array(Transformation))
      token = node.token
      return if token.nil?

      # Extract the full sig text
      sig_start = token.start
      sig_end = find_sig_end_pos(node)
      sig_text = @source.byte_slice(sig_start, sig_end - sig_start)

      # Store for next method
      store_sig_for_next_method(sig_text)

      # For Ruby→Crystal: remove the entire sig block
      # For Ruby→Ruby: convert to RBS (future)
      if @target_lang == :crystal
        transformations << Transformation.new(
          TransformKind::RemoveSig,
          sig_start,
          sig_end
        )
      end
    end

    private def handle_method_def(node : CST::GreenNode, transformations : Array(Transformation))
      # If we have a pending sig block, apply type conversion
      if @target_lang == :crystal && @last_sig_text
        sig_text = @last_sig_text.not_nil!
        @last_sig_text = nil

        # Check if this method is inside a generic class (extend T::Generic)
        # by searching the source backwards from the method for "extend T::Generic"
        in_generic_class = false
        if node.token
          method_pos = node.token.not_nil!.start
          # Look backwards for "extend T::Generic", up to 500 bytes back
          search_start = {method_pos - 500, 0}.max
          search_text = @source.byte_slice(search_start, method_pos - search_start)

          # Check if there's "extend T::Generic" before this method
          if search_text.includes?("extend T::Generic")
            in_generic_class = true
          end
        end

        # Parse the sig and method to generate Crystal signature
        apply_sig_to_method(node, sig_text, transformations, in_generic_class)
      end

      # Convert instance variables to class variables inside class methods (def self.*)
      convert_class_method_instance_vars(node, transformations)
    end

    private def convert_class_method_instance_vars(node : CST::GreenNode, transformations : Array(Transformation)) : Void
      token = node.token
      return if token.nil?

      method_start = token.start
      method_end = find_method_end_pos(method_start)
      return if method_end <= method_start

      method_text = @source.byte_slice(method_start, method_end - method_start)
      return unless method_text.includes?("def self.")

      pattern = /@[a-zA-Z_]\w*/
      method_text.scan(pattern) do |match|
        if match.begin(0) > 0
          prev_char = method_text[match.begin(0) - 1]
          next if prev_char == ':' || prev_char == '"' || prev_char == '\'' || prev_char == '@'
        end
        start_pos = method_start + match.begin(0)
        end_pos = method_start + match.end(0)
        var_name = match[0]
        simple_name = var_name[1..]

        # If the enclosing class declares an instance variable assignment (@name = ...),
        # then this is a class instance variable and should remain `@name` inside
        # class methods. Only convert to a class variable (`@@name`) when no such
        # class-level ivar assignment is present.
        class_range = find_enclosing_class_range(method_start)
        if class_range
          class_start = class_range[0]
          class_end = class_range[1]
          class_text = @source.byte_slice(class_start, class_end - class_start)
          next if class_text =~ /@#{simple_name}\s*=/
        end

        # If this occurrence is part of an assignment (e.g., "@count = value"),
        # leave it as an ivar so setters remain `@count = value`.
        rest = method_text[match.end(0)..-1]
        if rest && rest.lstrip.starts_with?("=")
          next
        end

        replacement = "@@#{simple_name}"

        transformations << Transformation.new(
          TransformKind::ReplaceVariable,
          start_pos,
          end_pos,
          replacement
        )
      end
    end

    private def find_method_end_pos(method_start : Int32) : Int32
      pos = 0

      @tokens.each_with_index do |t, idx|
        if t.start == method_start
          pos = idx
          break
        end
      end

      depth = 0
      started = false

      while pos < @tokens.size
        token = @tokens[pos]

        case token.kind
        when TokenKind::Def
          depth += 1
          started = true
        when TokenKind::End
          depth -= 1
          if started && depth == 0
            return token.start + token.length
          end
        end

        pos += 1
      end

      method_start
    end

    private def apply_sig_to_method(method_node : CST::GreenNode, sig_text : String, transformations : Array(Transformation), in_generic_context : Bool = false) : Void
      # Extract method signature from the node
      token = method_node.token
      return if token.nil?

      # Get the full method signature line
      method_start = token.start
      method_line_end = find_method_signature_end(method_node)
      method_text = @source.byte_slice(method_start, method_line_end - method_start)

      # Check if this method is inside a generic class (extend T::Generic)
      in_generic_class = false
      if token
        if class_range = find_enclosing_class_range(token.start)
          class_start = class_range[0]
          class_end = class_range[1]
          class_text = @source.byte_slice(class_start, class_end - class_start)
          in_generic_class = class_text.includes?("extend T::Generic")
        end
      end

      # Parse types from sig block
      sorbet_parser = SorbetParser.new(@source)
      sig_info = sorbet_parser.parse_sig(sig_text, in_generic_class)

      # Extract method name and parameters
      # Handle: def method_name, def method_name(...), def self.method_name, def self.method_name(...)
      is_class_method = method_text.includes?("self.")

      method_name = ""
      params_text = ""

      # Determine the start of the whole line containing the method signature
      line_start = method_start
      while line_start > 0 && @source[line_start - 1] != '\n'
        line_start -= 1
      end
      line_indent = @source.byte_slice(line_start, method_start - line_start)

      # First try to match with parentheses
      match = method_text.match(/def\s+(?:self\.)?(\w+)\s*\(([^)]*)\)/)

      if match
        method_name = $1
        params_text = "(#{$2})"
      else
        # Try without parentheses
        match = method_text.match(/def\s+(?:self\.)?(\w+)\s*(?:$|\n|#)/)
        if match
          method_name = $1
          params_text = "" # No parentheses in the source, don't add them
        end
      end

      if !method_name.empty?
        # Generate Crystal signature body (no leading indentation)
        signature_body = sorbet_parser.generate_crystal_signature(method_name, params_text, sig_info)

        # Add back 'self.' prefix if it's a class method
        signature_body = signature_body.sub(/^def /, "def self.") if is_class_method

        # Prepend the original line indentation and replace the entire line
        crystal_sig = line_indent + signature_body

        # Add transformation to replace method signature starting at beginning of the line
        transformations << Transformation.new(
          TransformKind::AddMethodType,
          line_start,
          method_line_end,
          crystal_sig
        )
      end
    end

    private def find_method_signature_end(node : CST::GreenNode) : Int32
      # Find the end of "def name(params)" line or "def name" line (with no params)
      token = node.token
      return 0 if token.nil?

      start_pos = token.start

      # Search forward from start_pos to find the end of the method signature line
      # Look for the first newline after "def" and handle same-line "; end" cases
      pos = start_pos
      while pos < @source.size
        if @source[pos] == '\n'
          # Check whether this line contains a single-line "; end" (e.g., "def foo(x); end")
          line_str = @source.byte_slice(start_pos, pos - start_pos)
          if m = line_str.match(/;\s*end\b/)
            # Stop replacement at the semicolon so we preserve the "; end" that follows
            return start_pos + m.begin
          end

          return pos # Return position of newline (not including it)
        end
        pos += 1
      end

      # If no newline found, return end of source
      @source.size
    end

    # Find the end position of a sig block including trailing newline
    private def find_sig_end_pos(node : CST::GreenNode) : Int32
      token = node.token
      return 0 if token.nil?

      # Scan tokens to find the end of the sig block
      sig_start = token.start
      pos = 0

      # Find token index for sig start
      @tokens.each_with_index do |token, idx|
        if token.start == sig_start
          pos = idx
          break
        end
      end

      # Scan forward to find end of sig block
      # Look for '}' or 'end' depending on sig form
      depth = 0
      started = false

      while pos < @tokens.size
        token = @tokens[pos]

        case token.kind
        when TokenKind::LBrace
          depth += 1
          started = true
        when TokenKind::RBrace
          depth -= 1
          if started && depth == 0
            # Include trailing newline if present
            next_pos = pos + 1
            if next_pos < @tokens.size && @tokens[next_pos].kind == TokenKind::Newline
              return @tokens[next_pos].start + @tokens[next_pos].length
            else
              return token.start + token.length
            end
          end
        when TokenKind::Do
          depth += 1
          started = true
        when TokenKind::End
          depth -= 1
          if started && depth == 0
            # Include trailing newline if present
            next_pos = pos + 1
            if next_pos < @tokens.size && @tokens[next_pos].kind == TokenKind::Newline
              return @tokens[next_pos].start + @tokens[next_pos].length
            else
              return token.start + token.length
            end
          end
        end

        pos += 1
      end

      # Fallback: just the sig token itself
      token = node.token
      return 0 if token.nil?
      token.start + token.length
    end

    # Find the enclosing class block (start, end) that contains `pos`.
    # Returns a Tuple(start_pos, end_pos) or nil if not found.
    private def find_enclosing_class_range(pos : Int32) : Tuple(Int32, Int32)?
      @tokens.each_with_index do |t, idx|
        if t.kind == TokenKind::Class && t.start <= pos
          class_start = t.start

          # Find corresponding end for this class
          depth = 0
          k = idx
          while k < @tokens.size
            tk = @tokens[k]
            case tk.kind
            when TokenKind::Class
              depth += 1
            when TokenKind::End
              depth -= 1
              if depth == 0
                class_end = tk.start + tk.length
                # If the pos is inside this class range, return it
                return {class_start, class_end} if pos < class_end
                break
              end
            end
            k += 1
          end
        end
      end

      nil
    end
  end
end
