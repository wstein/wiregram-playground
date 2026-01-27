# frozen_string_literal: true

require 'strscan'
require_relative '../../core/lexer'

module WireGram
  module Languages
    module Expression
      # High-performance lexer for simple expression language using StringScanner
      # Supports: numbers, identifiers, operators, keywords (let)
      class Lexer < WireGram::Core::BaseLexer
        KEYWORDS = %w[let].freeze

        # Pre-compiled regex patterns for performance
        WHITESPACE_PATTERN = /\s+/
        NUMBER_PATTERN = /\d+(?:\.\d+)?/
        IDENTIFIER_PATTERN = /[a-zA-Z_][a-zA-Z0-9_]*/
        STRING_PATTERN = /"(?:\\.|[^"\\])*"/
        DIGIT_PATTERN = /\d/
        LETTER_PATTERN = /[a-zA-Z_]/

        def initialize(source)
          super
          @scanner = StringScanner.new(source)
        end

        def skip_whitespace
          @scanner.pos = @position
          @scanner.skip(WHITESPACE_PATTERN)
          @position = @scanner.pos
        end

        protected

        def try_tokenize_next
          char = current_char

          case char
          when '+' then add_token(:plus, '+')
                        advance
                        true
          when '-' then add_token(:minus, '-')
                        advance
                        true
          when '*' then add_token(:star, '*')
                        advance
                        true
          when '/' then add_token(:slash, '/')
                        advance
                        true
          when '=' then add_token(:equals, '=')
                        advance
                        true
          when '(' then add_token(:lparen, '(')
                        advance
                        true
          when ')' then add_token(:rparen, ')')
                        advance
                        true
          when '"' then tokenize_string_fast
          when /\d/ then tokenize_number_fast
          when /[a-zA-Z_]/ then tokenize_identifier_fast
          else false
          end
        end

        private

        def tokenize_number_fast
          @scanner.pos = @position
          if @scanner.scan(NUMBER_PATTERN)
            matched = @scanner.matched
            value = matched.include?('.') ? matched.to_f : matched.to_i
            add_token(:number, value, position: @scanner.pos)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def tokenize_identifier_fast
          @scanner.pos = @position
          if @scanner.scan(IDENTIFIER_PATTERN)
            value = @scanner.matched
            type = KEYWORDS.include?(value) ? :keyword : :identifier
            add_token(type, value, position: @scanner.pos)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def tokenize_string_fast
          @scanner.pos = @position
          if (matched = @scanner.scan(STRING_PATTERN))
            # Remove surrounding quotes
            content = matched[1...-1]
            # Fast-path: avoid unescaping for common case with no backslashes
            unescaped = content.include?('\\') ? unescape_string(content) : content
            add_token(:string, unescaped, position: @scanner.pos)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def unescape_string(str)
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
                  hex = str[(i + 2)..(i + 5)]
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
      end
    end
  end
end
