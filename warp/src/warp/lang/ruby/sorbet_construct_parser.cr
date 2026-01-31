module Warp::Lang::Ruby
  # SorbetConstructParser: Parses Sorbet runtime constructs like T.let, T.must, etc.
  # Uses proper parsing to handle nested expressions correctly
  class SorbetConstructParser
    @source : String
    @pos : Int32

    def initialize(@source : String)
      @pos = 0
    end

    # Find all T.let calls in the source
    def find_all_t_let_calls : Array({start: Int32, end_pos: Int32, value: String, type: String})
      results = [] of {start: Int32, end_pos: Int32, value: String, type: String}
      @pos = 0

      while @pos < @source.size
        if match_text("T.let")
          start = @pos
          @pos += 5 # Skip "T.let"
          skip_whitespace

          if peek_char == '('
            @pos += 1 # Skip '('
            value = read_argument
            skip_whitespace

            if peek_char == ','
              @pos += 1 # Skip ','
              skip_whitespace
              type = read_argument
              skip_whitespace

              if peek_char == ')'
                @pos += 1 # Skip ')'
                results << {start: start, end_pos: @pos, value: value, type: type}
              end
            end
          end
        else
          @pos += 1
        end
      end

      results
    end

    # Find all T.must, T.cast, T.unsafe calls
    def find_all_t_method_calls(method_name : String) : Array({start: Int32, end_pos: Int32, value: String})
      results = [] of {start: Int32, end_pos: Int32, value: String}
      @pos = 0
      pattern = "T.#{method_name}"

      while @pos < @source.size
        if match_text(pattern)
          start = @pos
          @pos += pattern.size
          skip_whitespace

          if peek_char == '('
            @pos += 1 # Skip '('
            value = read_argument
            skip_whitespace

            # For T.cast, skip the second argument (the type)
            if method_name == "cast"
              if peek_char == ','
                @pos += 1
                skip_argument # Skip the type argument
                skip_whitespace
              end
            end

            if peek_char == ')'
              @pos += 1 # Skip ')'
              results << {start: start, end_pos: @pos, value: value}
            end
          end
        else
          @pos += 1
        end
      end

      results
    end

    # Find all T::Typename or T.typename constructs that need conversion
    # Returns {start, end_pos, original_text, replacement}
    def find_all_sorbet_types : Array({start: Int32, end_pos: Int32, original: String, replacement: String})
      results = [] of {start: Int32, end_pos: Int32, original: String, replacement: String}
      @pos = 0

      while @pos < @source.size
        if match_text("T.all(")
          start = @pos
          @pos += 6 # Skip "T.all("
          # Skip until closing paren
          skip_argument
          if peek_char == ')'
            @pos += 1
            original = @source[start...@pos]
            # T.all() represents intersection types which Crystal doesn't support
            # Convert to Object (most general type) or leave untyped
            results << {start: start, end_pos: @pos, original: original, replacement: "Object"}
          end
        elsif match_text("T.any(")
          start = @pos
          @pos += 6 # Skip "T.any("
          # Skip until closing paren
          skip_argument
          if peek_char == ')'
            @pos += 1
            original = @source[start...@pos]
            # T.any() is a union type - convert to just remove it or use Object
            results << {start: start, end_pos: @pos, original: original, replacement: "Object"}
          end
        elsif match_text("T.nilable(")
          start = @pos
          @pos += 10 # Skip "T.nilable("
          inner = read_argument
          if peek_char == ')'
            @pos += 1
            original = @source[start...@pos]
            replacement = SorbetParser.convert_type_str("T.nilable(#{inner})")
            results << {start: start, end_pos: @pos, original: original, replacement: replacement}
          end
        elsif match_text("T.untyped")
          start = @pos
          @pos += 9 # Skip "T.untyped"
          original = @source[start...@pos]
          # T.untyped is Sorbet's escape hatch - convert to Object
          results << {start: start, end_pos: @pos, original: original, replacement: "Object"}
        elsif match_text("T::Array[")
          start = @pos
          @pos += 8 # Skip "T::Array["
          inner = read_argument
          if peek_char == ']'
            @pos += 1
            original = @source[start...@pos]
            replacement = SorbetParser.convert_type_str("T::Array[#{inner}]")
            results << {start: start, end_pos: @pos, original: original, replacement: replacement}
          end
        elsif match_text("T::Hash[")
          start = @pos
          @pos += 7 # Skip "T::Hash["
          inner = read_argument
          if peek_char == ']'
            @pos += 1
            original = @source[start...@pos]
            replacement = SorbetParser.convert_type_str("T::Hash[#{inner}]")
            results << {start: start, end_pos: @pos, original: original, replacement: replacement}
          end
        elsif match_text("T::Set[")
          start = @pos
          @pos += 6 # Skip "T::Set["
          inner = read_argument
          if peek_char == ']'
            @pos += 1
            original = @source[start...@pos]
            replacement = SorbetParser.convert_type_str("T::Set[#{inner}]")
            results << {start: start, end_pos: @pos, original: original, replacement: replacement}
          end
        elsif match_text("T::Enumerator[")
          start = @pos
          @pos += 13 # Skip "T::Enumerator["
          inner = read_argument
          if peek_char == ']'
            @pos += 1
            original = @source[start...@pos]
            replacement = SorbetParser.convert_type_str("T::Enumerator[#{inner}]")
            results << {start: start, end_pos: @pos, original: original, replacement: replacement}
          end
        elsif match_text("T::Generic")
          start = @pos
          @pos += 10 # Skip "T::Generic"
          original = @source[start...@pos]
          # T::Generic is used for generic classes - not directly supported in Crystal
          results << {start: start, end_pos: @pos, original: original, replacement: ""}
        elsif match_text("T::Boolean")
          start = @pos
          @pos += 10 # Skip "T::Boolean"
          original = @source[start...@pos]
          results << {start: start, end_pos: @pos, original: original, replacement: "Bool"}
        elsif match_text("T.type_alias")
          start = @pos
          @pos += 12 # Skip "T.type_alias"
          # Skip the block
          skip_whitespace
          if peek_char == '{'
            @pos += 1
            depth = 1
            while @pos < @source.size && depth > 0
              if peek_char == '{'
                depth += 1
              elsif peek_char == '}'
                depth -= 1
              end
              @pos += 1
            end
            original = @source[start...@pos]
            # Type aliases should be removed in Crystal
            results << {start: start, end_pos: @pos, original: original, replacement: ""}
          end
        else
          @pos += 1
        end
      end

      results
    end

    private def match_text(text : String) : Bool
      return false if @pos + text.size > @source.size
      @source[@pos, text.size] == text
    end

    private def peek_char : Char?
      return nil if @pos >= @source.size
      @source[@pos]
    end

    private def skip_whitespace
      while @pos < @source.size && @source[@pos].whitespace?
        @pos += 1
      end
    end

    private def read_argument : String
      start = @pos
      depth = 0
      in_string = false
      string_char = '\0'

      while @pos < @source.size
        char = @source[@pos]

        if in_string
          if char == string_char && (@pos == 0 || @source[@pos - 1] != '\\')
            in_string = false
          end
        else
          case char
          when '"', '\''
            in_string = true
            string_char = char
          when '(', '[', '{'
            depth += 1
          when ')', ']', '}'
            return @source[start...@pos].strip if depth == 0
            depth -= 1
          when ','
            return @source[start...@pos].strip if depth == 0
          end
        end

        @pos += 1
      end

      @source[start...@pos].strip
    end

    private def skip_argument
      depth = 0
      in_string = false
      string_char = '\0'

      while @pos < @source.size
        char = @source[@pos]

        if in_string
          if char == string_char && (@pos == 0 || @source[@pos - 1] != '\\')
            in_string = false
          end
        else
          case char
          when '"', '\''
            in_string = true
            string_char = char
          when '(', '[', '{'
            depth += 1
          when ')', ']', '}'
            return if depth == 0
            depth -= 1
          when ','
            return if depth == 0
          end
        end

        @pos += 1
      end
    end
  end
end
