# frozen_string_literal: true

require "../../core/lexer"
require "../../core/scanner"

module WireGram
  module Languages
    module Ucl
      # UCL (Universal Configuration Language) Lexer - high-performance with a lightweight scanner
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
          "true" => true, "false" => false, "yes" => true, "no" => false,
          "on" => true, "off" => false, "null" => nil, "nil" => nil
        }

        STRUCTURAL_MAP = {
          "{" => WireGram::Core::TokenType::LBrace,
          "}" => WireGram::Core::TokenType::RBrace,
          "[" => WireGram::Core::TokenType::LBracket,
          "]" => WireGram::Core::TokenType::RBracket,
          ":" => WireGram::Core::TokenType::Colon,
          "=" => WireGram::Core::TokenType::Equals,
          ";" => WireGram::Core::TokenType::Semicolon,
          "," => WireGram::Core::TokenType::Comma,
          "(" => WireGram::Core::TokenType::LParen,
          ")" => WireGram::Core::TokenType::RParen
        }

        def initialize(source)
          super
          @scanner = WireGram::Core::Scanner.new(source)
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        # Reason: Complex branching is intentional for performance-sensitive tokenization.
        # The method is organized for fast-paths and minimal allocations.
        private def try_tokenize_next
          skip_whitespace
          return true if @position >= @source.bytesize

          # Handle comments
          return true if skip_comment

          @scanner.pos = @position
          byte = current_byte
          return false unless byte

          # 1. Structural/Punctuation tokens (High Frequency)
          if (matched = @scanner.scan(STRUCTURAL_PATTERN))
            start_pos = @position
            add_token(STRUCTURAL_MAP[matched], matched, position: start_pos)
            @position = @scanner.pos
            return true
          end

          # 2. Quoted strings
          if byte == 0x22 # '"'
            return tokenize_quoted_string_fast
          elsif byte == 0x27 # '\''
            return tokenize_single_quoted_string_fast
          end

          # 3. Numbers and hex literals (must check before dash-identifiers)
          if byte == 0x2d # '-'
            b1 = peek_byte(1)
            b2 = peek_byte(2)
            if b1 == 0x30 && b2 && (b2 == 0x78 || b2 == 0x58) # '-0x' or '-0X'
              return tokenize_hex_or_invalid
            elsif b1 && (0x30..0x39).includes?(b1) # '-[0-9]'
              return tokenize_number_fast
            end
          elsif byte == 0x30 # '0'
            b1 = peek_byte(1)
            if b1 && (b1 == 0x78 || b1 == 0x58) # '0x' or '0X'
              return tokenize_hex_or_invalid
            end
          elsif (0x30..0x39).includes?(byte) # '[0-9]'
            return tokenize_number_fast
          end

          # 4. Directives, Flags, Prefixes
          case byte
          when 0x2e # '.'
            b1 = peek_byte(1)
            if b1 && ((0x61..0x7a).includes?(b1) || (0x41..0x5a).includes?(b1) || b1 == 0x5f) # [a-zA-Z_]
              return tokenize_directive
            end
          when 0x2d # '-'
            b1 = peek_byte(1)
            if b1 && ((0x61..0x7a).includes?(b1) || (0x41..0x5a).includes?(b1) || b1 == 0x5f) # [a-zA-Z_]
              return tokenize_identifier_or_keyword
            end
          when 0x25 # '%'
            b1 = peek_byte(1)
            if b1 && ((0x61..0x7a).includes?(b1) || (0x41..0x5a).includes?(b1) || b1 == 0x5f) # [a-zA-Z_]
              return tokenize_identifier_or_keyword
            end
          end

          # 5. Identifiers or Unquoted strings
          # Prefer URL tokens (scheme://) over identifiers
          return tokenize_unquoted_string if @scanner.check(URL_PATTERN)

          # If starting with a letter, check if the following characters lead into an interpolation
          # without scanning the entire remaining source (use scanner.check so we don't advance)
          if (0x61..0x7a).includes?(byte) || (0x41..0x5a).includes?(byte) || byte == 0x5f # [a-zA-Z_]
            @scanner.pos = @position
            if (m = @scanner.check(IDENTIFIER_PATTERN))
              after_pos = @position + m.bytesize
              return tokenize_unquoted_string if @source.byte_slice(after_pos, 2) == "${"
            end
            return tokenize_identifier_or_keyword
          elsif byte == 0x2f # '/'
            # Check for URL before treating as unquoted string
            return tokenize_unquoted_string if @scanner.check(URL_PATTERN)
          end

          false
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        private def skip_whitespace
          @scanner.pos = @position
          @scanner.skip(WHITESPACE_PATTERN)
          @position = @scanner.pos
        end

        def skip_comment
          @scanner.pos = @position
          byte = current_byte
          if byte == 0x23 # '#'
            # Fast-skip to end of line
            if @scanner.scan(/#[^\n]*/)
              @position = @scanner.pos
            else
              nl = @source.index("\n", @position)
              @position = nl ? nl + 1 : @source.bytesize
            end
            return true
          elsif byte == 0x2f && peek_byte(1) == 0x2a # '/' and '*'
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

          while depth.positive? && pos < src.bytesize
            nxt_open = src.index("/*", pos)
            nxt_close = src.index("*/", pos)

            # If no closer, advance to end
            if nxt_close.nil?
              pos = src.bytesize
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
            add_token(WireGram::Core::TokenType::Directive, matched[1..], position: @scanner.pos)
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
            unescaped = content.includes?("\\") ? unescape_quoted_string(content) : content
            extras = { :quoted => true, :quote_type => :double } of Symbol => WireGram::Core::TokenExtraValue
            add_token(WireGram::Core::TokenType::String, unescaped, extras: extras, position: @scanner.pos)
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
            unescaped = content.includes?("\\") ? unescape_single_quoted_string(content) : content
            extras = { :quoted => true, :quote_type => :single } of Symbol => WireGram::Core::TokenExtraValue
            add_token(WireGram::Core::TokenType::String, unescaped, extras: extras, position: @scanner.pos)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def unescape_quoted_string(str)
          # Fast path: if no backslashes, return as-is
          return str unless str.includes?("\\")

          builder = String::Builder.new
          i = 0
          while i < str.size
            if str[i] == '\\' && i + 1 < str.size
              case str[i + 1]
              when '"'
                builder << '"'
                i += 2
              when '\\'
                builder << '\\'
                i += 2
              when '/'
                builder << '/'
                i += 2
              when 'b'
                builder << '\b'
                i += 2
              when 'f'
                builder << '\f'
                i += 2
              when 'n'
                builder << '\n'
                i += 2
              when 'r'
                builder << '\r'
                i += 2
              when 't'
                builder << '\t'
                i += 2
              when 'u'
                if i + 5 < str.size
                  hex = str[(i + 2)..(i + 5)]
                  begin
                    builder << hex.to_i(16).chr
                  rescue
                    builder << '?'
                  end
                  i += 6
                else
                  builder << str[i]
                  i += 1
                end
              when 'x'
                if i + 3 < str.size
                  hex = str[(i + 2)..(i + 3)]
                  begin
                    builder << hex.to_i(16).chr
                  rescue
                    builder << 'x'
                  end
                  i += 4
                else
                  builder << str[i]
                  i += 1
                end
              else
                builder << str[i + 1]
                i += 2
              end
            else
              builder << str[i]
              i += 1
            end
          end
          builder.to_s
        end

        def unescape_single_quoted_string(str)
          # Fast path: if no backslashes, return as-is
          return str unless str.includes?("\\")

          builder = String::Builder.new
          i = 0
          while i < str.size
            if str[i] == '\\' && i + 1 < str.size
              case str[i + 1]
              when '\''
                builder << '\''
              when '\\'
                builder << '\\'
              else
                builder << '\\'
                builder << str[i + 1]
              end
              i += 2
            else
              builder << str[i]
              i += 1
            end
          end
          builder.to_s
        end

        def tokenize_identifier_or_keyword
          @scanner.pos = @position
          if (matched = @scanner.scan(IDENTIFIER_PATTERN))
            # Use Hash lookup for keywords (much faster than case/downcase)
            # Fast path: try direct lookup (no allocation if already lowercase)
            if KEYWORDS.has_key?(matched)
              v = KEYWORDS[matched]
              if v.nil?
                add_token(WireGram::Core::TokenType::Null, nil, position: @scanner.pos)
              else
                add_token(WireGram::Core::TokenType::Boolean, v, position: @scanner.pos)
              end
            else
              lc = matched.downcase
              if KEYWORDS.has_key?(lc)
                v = KEYWORDS[lc]
                if v.nil?
                  add_token(WireGram::Core::TokenType::Null, nil, position: @scanner.pos)
                else
                  add_token(WireGram::Core::TokenType::Boolean, v, position: @scanner.pos)
                end
              else
                add_token(WireGram::Core::TokenType::Identifier, matched, position: @scanner.pos)
              end
            end

            @position = @scanner.pos
          else
            # Fallback for flags or complex unquoted strings if IDENTIFIER_PATTERN misses
            start = @position
            advance if current_byte == 0x2d # '-'

            while (byte = current_byte)
              # [\[\]{}();:,=\s]
              break if byte == 0x5b || byte == 0x5d || byte == 0x7b || byte == 0x7d || byte == 0x28 || byte == 0x29 || byte == 0x3b || byte == 0x3a || byte == 0x2c || byte == 0x3d || (byte <= 0x20)
              # [a-zA-Z0-9_%-]
              break unless (0x61..0x7a).includes?(byte) || (0x41..0x5a).includes?(byte) || (0x30..0x39).includes?(byte) || byte == 0x5f || byte == 0x25 || byte == 0x2d
              advance
            end

            value = @source.byte_slice(start, @position - start)
            return false if value.empty?

            lookup = value.downcase
            if KEYWORDS.has_key?(lookup)
              kw = KEYWORDS[lookup]
              if kw.nil?
                add_token(WireGram::Core::TokenType::Null, nil, position: @position)
              else
                add_token(WireGram::Core::TokenType::Boolean, kw, position: @position)
              end
            else
              add_token(WireGram::Core::TokenType::Identifier, value, position: @position)
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
            # Use scanner.scan_until to find next delimiter and stop before it
            end_pos = if @scanner.scan_until(/[\s,;})"]/)
                        # scanner.pos points after the delimiter; set end_pos to position before it
                        @scanner.pos - 1
                      else
                        src.bytesize
                      end
            @position = end_pos
            add_token(WireGram::Core::TokenType::String, src.byte_slice(start, @position - start), position: @position)
            return true
          end

          # If interpolation occurs within the upcoming run, handle nested interpolation
          # Use scanner to find next '${' starting at current position to avoid scanning whole file
          @scanner.pos = start
          if @scanner.scan_until(/\$\{/) # moves pos to after '${'
            interp_pos = @scanner.pos - 2
            close = find_matching_interpolation_close(src, interp_pos + 2)
            if close.nil?
              end_pos = src.bytesize
            else
              @scanner.pos = close + 1
              end_pos = if @scanner.scan_until(/[\s,;:})"]/)
                          @scanner.pos - 1
                        else
                          src.bytesize
                        end
            end
            @position = end_pos
            add_token(WireGram::Core::TokenType::String, src.byte_slice(start, @position - start), position: @position)
            return true
          end

          # Fast path: consume until next delimiter (no interpolation present)
          @scanner.pos = start
          end_pos = if @scanner.scan_until(/[\s,;:})"]/)
                      @scanner.pos - 1
                    else
                      src.bytesize
                    end
          if end_pos > start
            @position = end_pos
            add_token(WireGram::Core::TokenType::String, src.byte_slice(start, @position - start), position: @position)
            return true
          end

          # Fallback: handle interpolation and nested braces
          start = @position
          interp_depth = 0

          while (byte = current_byte)
            if byte == 0x24 && peek_byte(1) == 0x7b # '$' and '{'
              advance
              advance
              interp_depth += 1
            elsif byte == 0x7d && interp_depth.positive? # '}'
              advance
              interp_depth -= 1
            elsif interp_depth.zero? && (byte == 0x5b || byte == 0x5d || byte == 0x7b || byte == 0x7d || byte == 0x28 || byte == 0x29 || byte == 0x3b || byte == 0x3a || byte == 0x2c || byte == 0x3d || byte == 0x22 || (byte <= 0x20))
              # Stop at delimiters including quotes
              break unless byte == 0x3a && peek_byte(1) == 0x2f && peek_byte(2) == 0x2f # ':' and '/' and '/'
              advance
            else
              advance
            end
          end

          value = src.byte_slice(start, @position - start)
          # Only add token if we actually consumed something
          if value.bytesize.positive?
            add_token(WireGram::Core::TokenType::String, value, position: @position)
            true
          else
            # Hit a delimiter immediately without consuming anything
            false
          end
        end

        # Find matching closing '}' for an interpolation that starts at pos (pos is after the '${')
        def find_matching_interpolation_close(src, pos)
          depth = 1
          while depth.positive? && pos < src.bytesize
            next_open = src.index("${", pos)
            next_close = src.index("}", pos)
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
          if (m = @scanner.scan(/-?0[xX][0-9a-fA-F]+(?:\.[0-9a-fA-F]+)?/))
            if m.includes?(".")
              add_token(WireGram::Core::TokenType::InvalidHex, m, position: @scanner.pos)
            else
              add_token(WireGram::Core::TokenType::HexNumber, m, position: @scanner.pos)
            end
            @position = @scanner.pos
            return true
          elsif (m = @scanner.scan(INVALID_HEX_REMAIN))
            add_token(WireGram::Core::TokenType::InvalidHex, m, position: @scanner.pos)
            @position = @scanner.pos
            return true
          end
          false
        end

        def tokenize_number_fast
          @scanner.pos = @position

          # Try regular number
          if (matched = @scanner.scan(NUMBER_PATTERN))
            add_token(WireGram::Core::TokenType::Number, matched, position: @scanner.pos)
            @position = @scanner.pos
            return true
          end

          false
        end
      end
    end
  end
end
