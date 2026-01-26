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
        IDENTIFIER_PATTERN = /[a-zA-Z_][a-zA-Z0-9_%-]*/
        URL_PATTERN = %r{[a-zA-Z0-9_\-.]+://}
        HEX_PATTERN = /0[xX][0-9a-fA-F]+/
        NUMBER_PATTERN = /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/
        # Capture hex-like tokens that include invalid characters (e.g., 0xreadbeef)
        INVALID_HEX_REMAIN = /-?0[xX][^\s,;:})"]+/
        FLAG_PATTERN = /-[A-Za-z_]/
        DIRECTIVE_PATTERN = /\.[a-zA-Z_][a-zA-Z0-9_\-.]*/
        QUOTED_STRING_PATTERN = /"(?:\\.|[^"\\])*"/
        SINGLE_QUOTED_PATTERN = /'(?:\\.|[^'\\])*'/
        STRUCTURAL_PATTERN = /[{}\[\]:=;,()]/

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
          if (matched = @scanner.scan(STRUCTURAL_PATTERN))
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

          # 3. Numbers and hex literals (must check before dash-identifiers)
          if char == '-' && peek_char(1) == '0' && peek_char(2)&.match?(/[xX]/)
            return tokenize_hex_or_invalid
          elsif char == '-' && peek_char(1)&.match?(/\d/)
            return tokenize_number_fast
          elsif char == '0' && peek_char(1)&.match?(/[xX]/)
            return tokenize_hex_or_invalid
          elsif char&.match?(/\d/)
            return tokenize_number_fast
          end

          # 4. Directives, Flags, Prefixes
          case char
          when '.'
            return tokenize_directive if peek_char(1)&.match?(/[a-zA-Z_]/)
          when '-'
            return tokenize_identifier_or_keyword if peek_char(1)&.match?(/[A-Za-z_]/)
          when '%'
            return tokenize_identifier_or_keyword if peek_char(1)&.match?(/[A-Za-z_]/)
          end

          # 5. Identifiers or Unquoted strings
          # Prefer URL tokens (scheme://) over identifiers
          return tokenize_unquoted_string if @scanner.check(URL_PATTERN)

          # If starting with a letter, check if the following characters lead into an interpolation
          # without scanning the entire remaining source (use scanner.check so we don't advance)
          if char&.match?(/[a-zA-Z_]/)
            @scanner.pos = @position
            if (m = @scanner.check(IDENTIFIER_PATTERN))
              after_pos = @position + m.length
              return tokenize_unquoted_string if @source[after_pos, 2] == '${'

            end
            return tokenize_identifier_or_keyword
          elsif char == '/'
            # Check for URL before treating as unquoted string
            return tokenize_unquoted_string if @scanner.check(URL_PATTERN)
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
              nl = @source.index("\n", @position)
              @position = if nl
                            nl + 1
                          else
                            @source.length
                          end
            end
            return true
          elsif current_char == '/' && peek_char(1) == '*'
            skip_nested_block_comment
            return true
          end
          false
        end

        def skip_nested_block_comment
          # Use index-based scanning to jump over nested block comments efficiently
          src = @source
          pos = @position + 2 # skip initial '/*'
          depth = 1

          while depth.positive? && pos < src.length
            nxt_open = src.index('/*', pos)
            nxt_close = src.index('*/', pos)

            # If no closer, advance to end
            if nxt_close.nil?
              pos = src.length
              break
            elsif nxt_open && nxt_open < nxt_close
              depth += 1
              pos = nxt_open + 2
            else
              depth -= 1
              pos = nxt_close + 2
            end
          end

          @position = pos
        end

        def tokenize_directive
          @scanner.pos = @position
          if (matched = @scanner.scan(DIRECTIVE_PATTERN))
            # Store without leading dot
            add_token(:directive, matched[1..], position: @scanner.pos)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def tokenize_quoted_string_fast
          @scanner.pos = @position
          if (matched = @scanner.scan(QUOTED_STRING_PATTERN))
            # Extract content (without surrounding quotes)
            content = matched[1...-1]
            # Fast-path: avoid unescaping if there are no backslashes
            unescaped = content.include?('\\') ? unescape_quoted_string(content) : content
            add_token(:string, unescaped, { quoted: true, quote_type: :double, position: @scanner.pos })
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def tokenize_single_quoted_string_fast
          @scanner.pos = @position
          if (matched = @scanner.scan(SINGLE_QUOTED_PATTERN))
            content = matched[1...-1]
            # Fast-path: avoid unescaping if there are no backslashes
            unescaped = content.include?('\\') ? unescape_single_quoted_string(content) : content
            add_token(:string, unescaped, { quoted: true, quote_type: :single, position: @scanner.pos })
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
              when '"' then result << '"'
                            i += 2
              when '\\' then result << '\\'
                             i += 2
              when '/' then result << '/'
                            i += 2
              when 'b' then result << "\b"
                            i += 2
              when 'f' then result << "\f"
                            i += 2
              when 'n' then result << "\n"
                            i += 2
              when 'r' then result << "\r"
                            i += 2
              when 't' then result << "\t"
                            i += 2
              when 'u'
                if i + 5 < str.length
                  hex = str[i + 2..i + 5]
                  begin
                    result << [hex.to_i(16)].pack('U')
                  rescue StandardError
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
                  rescue StandardError
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
              when "'" then result << "'"
              when '\\' then result << '\\'
              else
                result << '\\' << str[i + 1]
              end
              i += 2
            else
              result << str[i]
              i += 1
            end
          end
          result
        end

        def tokenize_identifier_or_keyword
          @scanner.pos = @position
          if (matched = @scanner.scan(IDENTIFIER_PATTERN))
            # Use Hash lookup for keywords (much faster than case/downcase)
            # Fast path: try direct lookup (no allocation if already lowercase)
            if KEYWORDS.key?(matched)
              v = KEYWORDS[matched]
              if v.nil?
                add_token(:null, nil, position: @scanner.pos)
              else
                add_token(:boolean, v, position: @scanner.pos)
              end
            else
              lc = matched.downcase
              if KEYWORDS.key?(lc)
                v = KEYWORDS[lc]
                if v.nil?
                  add_token(:null, nil, position: @scanner.pos)
                else
                  add_token(:boolean, v, position: @scanner.pos)
                end
              else
                add_token(:identifier, matched, position: @scanner.pos)
              end
            end

            @position = @scanner.pos
          else
            # Fallback for flags or complex unquoted strings if IDENTIFIER_PATTERN misses
            start = @position
            advance if current_char == '-'

            while current_char
              break if current_char.match?(/[\[\]{}();:,=\s]/)

              break unless current_char.match?(/[a-zA-Z0-9_%-]/)

              advance

            end

            value = @source[start...@position]
            return false if value.empty?

            lookup = value.downcase
            if KEYWORDS.key?(lookup)
              add_token(KEYWORDS[lookup].nil? ? :null : :boolean, KEYWORDS[lookup], position: @position)
            else
              add_token(:identifier, value, position: @position)
            end
          end
          true
        end

        def tokenize_unquoted_string
          @scanner.pos = @position
          src = @source
          start = @position

          # If URL at current position, consume entire URL until next delimiter (allow ':' in URL)
          if @scanner.check(URL_PATTERN)
            @scanner.scan(URL_PATTERN)
            @scanner.pos
            # Use scanner.scan_until to find next delimiter and stop before it
            end_pos = if @scanner.scan_until(/[\s,;})"]/)
                        # scanner.pos points after the delimiter; set end_pos to position before it
                        @scanner.pos - 1
                      else
                        src.length
                      end
            @position = end_pos
            add_token(:string, src[start...@position], position: @position)
            return true
          end

          # If interpolation occurs within the upcoming run, handle nested interpolation
          # Use scanner to find next '${' starting at current position to avoid scanning whole file
          @scanner.pos = start
          if @scanner.scan_until(/\$\{/) # moves pos to after '${'
            interp_pos = @scanner.pos - 2
            close = find_matching_interpolation_close(src, interp_pos + 2)
            if close.nil?
              end_pos = src.length
            else
              @scanner.pos = close + 1
              end_pos = if @scanner.scan_until(/[\s,;:})"]/)
                          @scanner.pos - 1
                        else
                          src.length
                        end
            end
            @position = end_pos
            add_token(:string, src[start...@position], position: @position)
            return true
          end

          # Fast path: consume until next delimiter (no interpolation present)
          @scanner.pos = start
          end_pos = if @scanner.scan_until(/[\s,;:})"]/)
                      @scanner.pos - 1
                    else
                      src.length
                    end
          if end_pos > start
            @position = end_pos
            add_token(:string, src[start...@position], position: @position)
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
            elsif current_char == '}' && interp_depth.positive?
              advance
              interp_depth -= 1
            elsif interp_depth.zero? && current_char.match?(/[\s,;:})"]/)
              # Stop at delimiters including quotes
              break unless current_char == ':' && peek_char(1) == '/' && peek_char(2) == '/'

              advance

            else
              advance
            end
          end

          value = @source[start...@position]
          # Only add token if we actually consumed something
          if value.length.positive?
            add_token(:string, value, position: @position)
            true
          else
            # Hit a delimiter immediately without consuming anything
            false
          end
        end

        # Find matching closing '}' for an interpolation that starts at pos (pos is after the '${')
        def find_matching_interpolation_close(src, pos)
          depth = 1
          while depth.positive? && pos < src.length
            next_open = src.index('${', pos)
            next_close = src.index('}', pos)
            return nil if next_close.nil?

            if next_open && next_open < next_close
              depth += 1
              pos = next_open + 2
            else
              depth -= 1
              pos = next_close + 1
            end
          end
          pos - 1
        end

        def tokenize_hex_or_invalid
          @scanner.pos = @position
          # Match hex with optional fractional part (treated as invalid) or invalid remainder
          if @scanner.scan(/-?0[xX][0-9a-fA-F]+(?:\.[0-9a-fA-F]+)?/)
            m = @scanner.matched
            if m.include?('.')
              add_token(:invalid_hex, m, position: @scanner.pos)
            else
              add_token(:hex_number, m, position: @scanner.pos)
            end
            @position = @scanner.pos
            return true
          elsif @scanner.scan(INVALID_HEX_REMAIN)
            add_token(:invalid_hex, @scanner.matched, position: @scanner.pos)
            @position = @scanner.pos
            return true
          end
          false
        end

        def tokenize_number_fast
          @scanner.pos = @position

          # Try regular number
          if @scanner.scan(NUMBER_PATTERN)
            add_token(:number, @scanner.matched, position: @scanner.pos)
            @position = @scanner.pos
            return true
          end

          false
        end
      end
    end
  end
end
