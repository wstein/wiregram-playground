# frozen_string_literal: true

require "../../core/lexer"
require "../../core/scanner"

module WireGram
  module Languages
    module Expression
      # High-performance lexer for simple expression language using StringScanner
      # Supports: numbers, identifiers, operators, keywords (let)
      class Lexer < WireGram::Core::BaseLexer
        KEYWORDS = %w[let]

        # Pre-compiled regex patterns for performance
        WHITESPACE_PATTERN = /\s+/
        NUMBER_PATTERN = /\d+(?:\.\d+)?/
        IDENTIFIER_PATTERN = /[a-zA-Z_][a-zA-Z0-9_]*/
        STRING_PATTERN = /"(?:\\.|[^"\\])*"/
        DIGIT_PATTERN = /\d/
        LETTER_PATTERN = /[a-zA-Z_]/

        def initialize(source)
          super
          @scanner = WireGram::Core::Scanner.new(source)
        end

        def skip_whitespace
          @scanner.pos = @position
          @scanner.skip(WHITESPACE_PATTERN)
          @position = @scanner.pos
        end

        private def try_tokenize_next
          char = current_char
          return false unless char

          case char
          when "+"
            add_token(WireGram::Core::TokenType::Plus, "+")
            advance
            true
          when "-"
            add_token(WireGram::Core::TokenType::Minus, "-")
            advance
            true
          when "*"
            add_token(WireGram::Core::TokenType::Star, "*")
            advance
            true
          when "/"
            add_token(WireGram::Core::TokenType::Slash, "/")
            advance
            true
          when "="
            add_token(WireGram::Core::TokenType::Equals, "=")
            advance
            true
          when "("
            add_token(WireGram::Core::TokenType::LParen, "(")
            advance
            true
          when ")"
            add_token(WireGram::Core::TokenType::RParen, ")")
            advance
            true
          when "\""
            tokenize_string_fast
          else
            if /\d/.matches?(char)
              tokenize_number_fast
            elsif /[a-zA-Z_]/.matches?(char)
              tokenize_identifier_fast
            else
              false
            end
          end
        end

        private def tokenize_number_fast
          @scanner.pos = @position
          if @scanner.scan(NUMBER_PATTERN)
            matched = @scanner.matched.not_nil!
            value = matched.includes?(".") ? matched.to_f : matched.to_i64
            add_token(WireGram::Core::TokenType::Number, value, position: @scanner.pos)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def tokenize_identifier_fast
          @scanner.pos = @position
          if @scanner.scan(IDENTIFIER_PATTERN)
            value = @scanner.matched.not_nil!
            type = KEYWORDS.includes?(value) ? WireGram::Core::TokenType::Keyword : WireGram::Core::TokenType::Identifier
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
            unescaped = content.includes?("\\") ? unescape_string(content) : content
            add_token(WireGram::Core::TokenType::String, unescaped, position: @scanner.pos)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def unescape_string(str)
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
      end
    end
  end
end
