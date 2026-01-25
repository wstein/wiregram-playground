# frozen_string_literal: true

require 'strscan'
require_relative '../../core/lexer'

module WireGram
  module Languages
    module Ucl
      # UCL (Universal Configuration Language) Lexer - high-performance with StringScanner
      # Tokenizes UCL syntax including objects, arrays, strings, numbers, and comments
      class Lexer < WireGram::Core::BaseLexer
        # Pre-compiled regex patterns for performance
        WHITESPACE_PATTERN = /\s+/
        IDENTIFIER_PATTERN = /[a-zA-Z_][a-zA-Z0-9_%\-]*/
        URL_PATTERN = /[a-zA-Z0-9_\-\.]+:\/\//
        # Hex numbers (allow optional leading sign). Invalid hex patterns are handled explicitly.
        HEX_PATTERN = /-?0[xX][0-9a-fA-F]+/
        NUMBER_PATTERN = /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/
        INVALID_HEX_REMAIN = /-?0[xX][^\s,;:\}\)"]+/
        FLAG_PATTERN = /-[A-Za-z_]/
        DIRECTIVE_PATTERN = /\.[a-zA-Z_][a-zA-Z0-9_\-\.]*/
        QUOTED_STRING_PATTERN = /"(?:\\.|[^"\\])*"/
        SINGLE_QUOTED_PATTERN = /'(?:\\.|[^'\\])*'/
        STRUCTURAL_PATTERN = /[\{\}\[\]\:\=;,\(\)]/
        
        KEYWORDS = {
          'true' => true, 'false' => false, 'yes' => true, 'no' => false,
          'on' => true, 'off' => false, 'null' => nil, 'nil' => nil
        }.freeze

        STRUCTURAL_MAP = {
          '{' => :lbrace, '}' => :rbrace, '[' => :lbracket, ']' => :rbracket,
          ':' => :colon, '=' => :equals, ';' => :semicolon, ',' => :comma,
          '(' => :lparen, ')' => :rparen
        }.freeze

        def initialize(source)
          super(source)
          @scanner = StringScanner.new(source)
        end

        protected

        def try_tokenize_next
          skip_whitespace
          return true if @position >= @source.length

          # Handle comments
          return true if skip_comment

          @scanner.pos = @position
          char = current_char

          # 1. Structural/Punctuation tokens (High Frequency)
          if matched = @scanner.scan(STRUCTURAL_PATTERN)
            add_token(STRUCTURAL_MAP[matched], matched)
            @position = @scanner.pos
            return true
          end

          # 2. Quoted strings
          if char == '"'
            return tokenize_quoted_string_fast
          elsif char == "'"
            return tokenize_single_quoted_string_fast
          end

          # 3. Numbers (must check before dash-identifiers)
          if char == '-'
            if peek_char(1)&.match?(/\d/)
               return tokenize_number_fast
            end
          elsif char&.match?(/\d/)
            return tokenize_number_fast
          end

          # 4. Directives, Flags, Prefixes
          case char
          when '.'
            if peek_char(1)&.match?(/[a-zA-Z_]/)
              return tokenize_directive
            end
          when '-'
            if peek_char(1)&.match?(/[A-Za-z_]/)
              return tokenize_identifier_or_keyword
            end
          when '%'
            if peek_char(1)&.match?(/[A-Za-z_]/)
              return tokenize_identifier_or_keyword
            end
          end

          # 5. Identifiers or Unquoted strings
          if char&.match?(/[a-zA-Z_]/)
            return tokenize_identifier_or_keyword
          elsif char == '/'
            # Check for URL before treating as unquoted string
            if @scanner.check(URL_PATTERN)
              return tokenize_unquoted_string
            end
          end

          false
        end

        private

        def skip_whitespace
          @scanner.pos = @position
          @scanner.skip(WHITESPACE_PATTERN)
          @position = @scanner.pos
        end

        def skip_comment
          @scanner.pos = @position
          if current_char == '#'
            # Fast-skip to end of line
            if @scanner.scan(/#[^\n]*/)
              @position = @scanner.pos
            else
              advance while current_char && current_char != "\n"
              advance if current_char == "\n"
            end
            return true
          elsif current_char == '/' && peek_char(1) == '*'
            skip_nested_block_comment
            return true
          end
          false
        end

        def skip_nested_block_comment
          advance # skip /
          advance # skip *
          depth = 1

          while depth > 0 && current_char
            if current_char == '/' && peek_char(1) == '*'
              advance
              advance
              depth += 1
            elsif current_char == '*' && peek_char(1) == '/'
              advance
              advance
              depth -= 1
            else
              advance
            end
          end
        end

        def tokenize_directive
          @scanner.pos = @position
          if matched = @scanner.scan(DIRECTIVE_PATTERN)
            # Store without leading dot
            add_token(:directive, matched[1..-1])
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def tokenize_quoted_string_fast
          @scanner.pos = @position
          if matched = @scanner.scan(QUOTED_STRING_PATTERN)
            # Extract content (without surrounding quotes)
            content = matched[1...-1]
            # Fast-path: avoid unescaping if there are no backslashes
            unescaped = content.include?('\\') ? unescape_quoted_string(content) : content
            add_token(:string, unescaped, quoted: true, quote_type: :double)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def tokenize_single_quoted_string_fast
          @scanner.pos = @position
          if matched = @scanner.scan(SINGLE_QUOTED_PATTERN)
            content = matched[1...-1]
            # Fast-path: avoid unescaping if there are no backslashes
            unescaped = content.include?('\\') ? unescape_single_quoted_string(content) : content
            add_token(:string, unescaped, quoted: true, quote_type: :single)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def unescape_quoted_string(str)
          # Fast path: if no backslashes, return as-is
          return str unless str.include?('\\')

          result = String.new(capacity: str.length)
          i = 0
          while i < str.length
            if str[i] == '\\' && i + 1 < str.length
              case str[i + 1]
              when '"' then result << '"'; i += 2
              when '\\' then result << '\\'; i += 2
              when '/' then result << '/'; i += 2
              when 'b' then result << "\b"; i += 2
              when 'f' then result << "\f"; i += 2
              when 'n' then result << "\n"; i += 2
              when 'r' then result << "\r"; i += 2
              when 't' then result << "\t"; i += 2
              when 'u'
                if i + 5 < str.length
                  hex = str[i + 2..i + 5]
                  begin
                    result << [hex.to_i(16)].pack('U')
                  rescue
                    result << '?'
                  end
                  i += 6
                else
                  result << str[i]
                  i += 1
                end
              when 'x'
                if i + 3 < str.length
                  hex = str[i + 2..i + 3]
                  begin
                    result << hex.to_i(16).chr
                  rescue
                    result << 'x'
                  end
                  i += 4
                else
                  result << str[i]
                  i += 1
                end
              else
                result << str[i + 1]
                i += 2
              end
            else
              result << str[i]
              i += 1
            end
          end
          result
        end

        def unescape_single_quoted_string(str)
          # Fast path: if no backslashes, return as-is
          return str unless str.include?('\\')

          result = String.new(capacity: str.length)
          i = 0
          while i < str.length
            if str[i] == '\\' && i + 1 < str.length
              case str[i + 1]
              when "'" then result << "'"; i += 2
              when '\\' then result << '\\'; i += 2
              else
                result << '\\' << str[i + 1]
                i += 2
              end
            else
              result << str[i]
              i += 1
            end
          end
          result
        end

        def tokenize_identifier_or_keyword
          @scanner.pos = @position
          if matched = @scanner.scan(IDENTIFIER_PATTERN)
            # Use Hash lookup for keywords (much faster than case/downcase)
            # Fast path: try direct lookup (no allocation if already lowercase)
            if KEYWORDS.key?(matched)
              v = KEYWORDS[matched]
              if v.nil?
                add_token(:null, nil)
              else
                add_token(:boolean, v)
              end
            else
              lc = matched.downcase
              if KEYWORDS.key?(lc)
                v = KEYWORDS[lc]
                if v.nil?
                  add_token(:null, nil)
                else
                  add_token(:boolean, v)
                end
              else
                add_token(:identifier, matched)
              end
            end

            @position = @scanner.pos
            true
          else
            # Fallback for flags or complex unquoted strings if IDENTIFIER_PATTERN misses
            start = @position
            advance if current_char == '-'

            while current_char
              break if current_char.match?(/[\[\]\{\}\(\);:,=\s]/)
              if current_char.match?(/[a-zA-Z0-9_%\-]/)
                advance
              else
                break
              end
            end

            value = @source[start...@position]
            return false if value.empty?

            lookup = value.downcase
            if KEYWORDS.key?(lookup)
               add_token(KEYWORDS[lookup].nil? ? :null : :boolean, KEYWORDS[lookup])
            else
               add_token(:identifier, value)
            end
            true
          end
        end

        def tokenize_unquoted_string
          @scanner.pos = @position
          # Fast path: consume a run of non-delimiter characters (no interpolation)
          if matched = @scanner.scan(/[^\s,;:\}\)"]+/)
            # matched does not include delimiters; consume and return
            add_token(:string, matched)
            @position = @scanner.pos
            return true
          end

          # Fallback: handle interpolation and nested braces
          start = @position
          interp_depth = 0

          while current_char
            if current_char == '$' && peek_char(1) == '{'
              advance
              advance
              interp_depth += 1
            elsif current_char == '}' && interp_depth > 0
              advance
              interp_depth -= 1
            elsif interp_depth == 0 && current_char.match?(/[\s,;:\}\)"]/)
              # Stop at delimiters including quotes
              if current_char == ':' && peek_char(1) == '/' && peek_char(2) == '/'
                advance
              else
                break
              end
            else
              advance
            end
          end

          value = @source[start...@position]
          # Only add token if we actually consumed something
          if value.length > 0
            add_token(:string, value)
            true
          else
            # Hit a delimiter immediately without consuming anything
            false
          end
        end

        def tokenize_number_fast
          @scanner.pos = @position

          # Handle hex numbers and invalid hex forms
          if @scanner.scan(/-?0[xX][0-9a-fA-F]+\.[0-9a-fA-F]*/)
            # Hex with a decimal point -> invalid hex
            add_token(:invalid_hex, @scanner.matched)
            @position = @scanner.pos
            return true
          elsif @scanner.scan(HEX_PATTERN)
            add_token(:hex_number, @scanner.matched)
            @position = @scanner.pos
            return true
          elsif @scanner.scan(INVALID_HEX_REMAIN)
            # Starts like hex but contains invalid characters -> treat as invalid_hex
            add_token(:invalid_hex, @scanner.matched)
            @position = @scanner.pos
            return true
          end

          # Try regular number
          if @scanner.scan(NUMBER_PATTERN)
            add_token(:number, @scanner.matched)
            @position = @scanner.pos
            return true
          end

          false
        end
      end
    end
  end
end
