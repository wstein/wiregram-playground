# frozen_string_literal: true

require_relative '../../core/lexer'

module WireGram
  module Languages
    module Ucl
      # UCL (Universal Configuration Language) Lexer
      # Tokenizes UCL syntax including objects, arrays, strings, numbers, and comments
      class Lexer < WireGram::Core::BaseLexer
        protected

        def try_tokenize_next
          skip_whitespace
          return true if @position >= @source.length

          # Handle comments
          return true if skip_comment

          # Heuristics: treat leading '-' followed by letter as identifier (flags like -i)
          if current_char == '-' && peek_char(1)&.match?(/[A-Za-z_]/)
            return tokenize_identifier_or_keyword
          end

          # Heuristic: capture URLs like http://... as unquoted strings
          if @source[@position..] =~ /\A[a-zA-Z0-9_\-\.]+:\/\//
            return tokenize_unquoted_string
          end

          # Heuristic: percent-prefixed tokens like %a should be identifiers
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
            tokenize_quoted_string
          when "'"
            tokenize_single_quoted_string
          when '.'
            # directive like .include
            if peek_char(1)&.match?(/[a-zA-Z_]/)
              start = @position
              advance # consume '.'
              advance while current_char&.match?(/[a-zA-Z0-9_\-\.]/)
              value = @source[start...@position]
              # store value without the leading dot
              add_token(:directive, value[1..-1])
              true
            else
              false
            end

          when /[a-zA-Z_]/
            tokenize_identifier_or_keyword
          when '/'
            tokenize_unquoted_string
          when /[0-9\-]/
            tokenize_number
          else
            false
          end
        end

        private

        def skip_whitespace
          while current_char&.match?(/[\s]/)
            advance
          end
        end

        def skip_comment
          if current_char == '#'
            # Skip line comment
            advance while current_char && current_char != "\n"
            advance if current_char == "\n"
            return true
          elsif current_char == '/' && peek_char(1) == '*'
            # Skip block comment with nesting support
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

        def tokenize_quoted_string
          advance # skip opening quote
          value = String.new

          while current_char
            if current_char == '"'
              break
            elsif current_char == '\\'
              advance
              esc = current_char
              case esc
              when '"' then value << '"'
              when '\\' then value << '\\'
              when '/' then value << '/'
              when 'b' then value << "\b"
              when 'f' then value << "\f"
              when 'n' then value << "\n"
              when 'r' then value << "\r"
              when 't' then value << "\t"
              when 'u'
                # unicode escape \uXXXX
                hex = String.new
                4.times do
                  advance
                  hex << (current_char || '')
                end
                value << ([hex.to_i(16)].pack('U') rescue '?')
              when 'x'
                # hex escape \xXX
                hex = String.new
                2.times do
                  advance
                  hex << (current_char || '')
                end
                value << hex.to_i(16).chr rescue value << 'x'
              else
                value << esc
              end
              advance
            else
              value << current_char
              advance
            end
          end

          advance if current_char == '"' # skip closing quote
          # mark double-quoted strings explicitly
          add_token(:string, value, quoted: true, quote_type: :double)
          true
        end

        def tokenize_single_quoted_string
          advance # skip opening quote
          value = String.new

          while current_char
            if current_char == "'"
              break
            elsif current_char == '\\'
              advance
              esc = current_char
              case esc
              when "'" then value << "'"
              when '\\' then value << '\\'
              else
                value << '\\' << esc
              end
              advance
            else
              value << current_char
              advance
            end
          end

          advance if current_char == "'" # skip closing quote
          # mark single-quoted strings explicitly
          add_token(:string, value, quoted: true, quote_type: :single)
          true
        end

        def tokenize_identifier_or_keyword
          start = @position

          # Allow leading dash for tokens like -i and include '%' inside identifiers
          advance if current_char == '-'

          # Continue reading identifier characters including hyphens
          # This handles hyphenated identifiers like "all-depends", "build-depends"
          while current_char
            # Stop at UCL structural delimiters
            break if current_char.match?(/[\[\]\{\}\(\);:,=\s]/)

            # Continue if it's a valid identifier character (including hyphens)
            if current_char.match?(/[a-zA-Z0-9_%\-]/)
              advance
            else
              break
            end
          end

          value = @source[start...@position]

          # Check for keywords and booleans
          case value.downcase
          when 'true'
            add_token(:boolean, true)
          when 'false'
            add_token(:boolean, false)
          when 'yes'
            add_token(:boolean, true)  # Normalization: yes -> true
          when 'no'
            add_token(:boolean, false) # Normalization: no -> false
          when 'null', 'nil'
            add_token(:null, nil)
          when 'on'
            add_token(:boolean, true)  # Normalization: on -> true
          when 'off'
            add_token(:boolean, false) # Normalization: off -> false
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
              # start interpolation, include '${'
              advance
              advance
              interp_depth += 1
            elsif current_char == '}' && interp_depth > 0
              advance
              interp_depth -= 1
            elsif interp_depth == 0 && current_char.match?(/[\s,;:\}\)]/)
              # Check if this is a URL scheme (colon followed by //)
              if current_char == ':' && peek_char(1) == '/' && peek_char(2) == '/'
                # This is part of a URL, continue
                advance
              else
                # Real break - this is a structural delimiter or whitespace
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

        def tokenize_number
          start = @position

          # Handle negative sign
          advance if current_char == '-'

          # Check for hex number
          if current_char == '0' && (peek_char(1) == 'x' || peek_char(1) == 'X')
            # Let tokenize_hex_number handle the entire thing from start (including negative sign)
            tokenize_hex_number_with_sign(start)
            return true
          end

          # Integer part
          if current_char == '0'
            advance
          else
            advance while current_char&.match?(/[0-9]/)
          end

          # Fraction part
          if current_char == '.'
            advance
            advance while current_char&.match?(/[0-9]/)
          end

          # Scientific notation
          if current_char&.match?(/[eE]/)
            advance
            advance if current_char&.match?(/[+-]/)
            advance while current_char&.match?(/[0-9]/)
          end

          value = @source[start...@position]
          add_token(:number, value)
          true
        end

        def tokenize_hex_number_with_sign(start)
          advance # 0
          advance # x or X

          # Allow hex numbers and also support hex-like tokens that may include dots later

          hex_start = @position
          advance while current_char&.match?(/[0-9a-fA-F]/)
          hex_part = @source[hex_start...@position]

          # Check for invalid hex - if hex_part is empty or next char suggests invalid hex
          if hex_part.empty? || current_char&.match?(/[a-zA-Z0-9_]/)
            # Could be invalid hex like 0xreadbeef or just 0x
            # Try to read more to capture the full invalid token
            if !hex_part.empty? && current_char&.match?(/[a-zA-Z0-9_]/)
              # We have some hex digits followed by invalid chars - read them all
              advance while current_char&.match?(/[a-zA-Z0-9_.]/)
            elsif hex_part.empty?
              # Just "0x" with nothing after - could be valid identifier like "0x"
              # For now, treat as string
              advance while current_char&.match?(/[a-zA-Z0-9_.]/)
            end

            value = @source[start...@position]
            add_token(:invalid_hex, value)
            return true
          end

          # Check for invalid hex number with fraction (e.g., 0xdeadbeef.1)
          if current_char == '.'
            # This is an invalid hex number - treat as string
            advance while current_char&.match?(/[0-9a-fA-F.]/)
            # Return as a string token to be normalized
            value = @source[start...@position]
            add_token(:invalid_hex, value)
            return true
          end

          # Valid hex number
          value = @source[start...@position]
          add_token(:hex_number, value)
          true
        end
      end
    end
  end
end
