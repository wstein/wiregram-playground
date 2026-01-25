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
        HEX_PATTERN = /0[xX][0-9a-fA-F]+/
        NUMBER_PATTERN = /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/
        FLAG_PATTERN = /-[A-Za-z_]/
        DIRECTIVE_PATTERN = /\.[a-zA-Z_][a-zA-Z0-9_\-\.]*/
        QUOTED_STRING_PATTERN = /"(?:\\.|[^"\\])*"/
        SINGLE_QUOTED_PATTERN = /'(?:\\.|[^'\\])*'/

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

          # Check for directive (must come before identifier check since it starts with .)
          if current_char == '.' && peek_char(1)&.match?(/[a-zA-Z_]/)
            return tokenize_directive
          end

          # Check for flag-style identifiers (like -i)
          if current_char == '-' && peek_char(1)&.match?(/[A-Za-z_]/)
            return tokenize_identifier_or_keyword
          end

          # Check for URLs
          if @source[@position..] =~ URL_PATTERN
            return tokenize_unquoted_string
          end

          # Check for percent-prefixed tokens
          if current_char == '%' && peek_char(1)&.match?(/[A-Za-z_]/)
            return tokenize_identifier_or_keyword
          end

          char = current_char

          case char
          when '{'
            add_token(:lbrace, '{'); advance; true
          when '}'
            add_token(:rbrace, '}'); advance; true
          when '['
            add_token(:lbracket, '['); advance; true
          when ']'
            add_token(:rbracket, ']'); advance; true
          when ':'
            add_token(:colon, ':'); advance; true
          when '='
            add_token(:equals, '='); advance; true
          when ';'
            add_token(:semicolon, ';'); advance; true
          when ','
            add_token(:comma, ','); advance; true
          when '('
            add_token(:lparen, '('); advance; true
          when ')'
            add_token(:rparen, ')'); advance; true
          when '"'
            tokenize_quoted_string_fast
          when "'"
            tokenize_single_quoted_string_fast
          when /[a-zA-Z_]/
            tokenize_identifier_or_keyword
          when '/'
            tokenize_unquoted_string
          when /[0-9\-]/
            tokenize_number_fast
          else
            false
          end
        end

        private

        def skip_whitespace
          @scanner.pos = @position
          @scanner.skip(WHITESPACE_PATTERN)
          @position = @scanner.pos
        end

        def skip_comment
          if current_char == '#'
            advance while current_char && current_char != "\n"
            advance if current_char == "\n"
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
          start = @position
          advance if current_char == '-'  # Handle flags like -i

          while current_char
            break if current_char.match?(/[\[\]\{\}\(\);:,=\s]/)
            if current_char.match?(/[a-zA-Z0-9_%\-]/)
              advance
            else
              break
            end
          end

          value = @source[start...@position]
          case value.downcase
          when 'true'
            add_token(:boolean, true)
          when 'false'
            add_token(:boolean, false)
          when 'yes'
            add_token(:boolean, true)
          when 'no'
            add_token(:boolean, false)
          when 'null', 'nil'
            add_token(:null, nil)
          when 'on'
            add_token(:boolean, true)
          when 'off'
            add_token(:boolean, false)
          else
            add_token(:identifier, value)
          end
          true
        end

        def tokenize_unquoted_string
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
            elsif interp_depth == 0 && current_char.match?(/[\s,;:\}\)]/)
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
          add_token(:string, value)
          true
        end

        def tokenize_number_fast
          @scanner.pos = @position

          # Try hex number first
          if @scanner.scan(HEX_PATTERN)
            add_token(:hex_number, @scanner.matched)
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
