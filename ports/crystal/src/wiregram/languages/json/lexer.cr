# frozen_string_literal: true

require "../../core/lexer"
require "../../core/scanner"

module WireGram
  module Languages
    module Json
      # High-performance JSON lexer using a lightweight scanner
      class Lexer < WireGram::Core::BaseLexer
        # Pre-compiled regex patterns for performance
        STRING_PATTERN = /"(?:\\.|[^"\\])*"/
        WHITESPACE_PATTERN = /\s+/
        NUMBER_PATTERN = /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/
        TRUE_PATTERN = /true/
        FALSE_PATTERN = /false/
        NULL_PATTERN = /null/

        def initialize(source)
          super
          @scanner = WireGram::Core::Scanner.new(source)
        end

        private def try_tokenize_next
          byte = current_byte
          return false unless byte

          case byte
          when 0x7b # '{'
            add_token(WireGram::Core::TokenType::LBrace, "{")
            advance
            true
          when 0x7d # '}'
            add_token(WireGram::Core::TokenType::RBrace, "}")
            advance
            true
          when 0x5b # '['
            add_token(WireGram::Core::TokenType::LBracket, "[")
            advance
            true
          when 0x5d # ']'
            add_token(WireGram::Core::TokenType::RBracket, "]")
            advance
            true
          when 0x3a # ':'
            add_token(WireGram::Core::TokenType::Colon, ":")
            advance
            true
          when 0x2c # ','
            add_token(WireGram::Core::TokenType::Comma, ",")
            advance
            true
          when 0x22 # '"'
            tokenize_string
          else
            if byte == 0x2d || (0x30..0x39).includes?(byte) # '-' or '0'-'9'
              tokenize_number
            elsif byte == 0x74 || byte == 0x66 || byte == 0x6e # 't', 'f', 'n'
              tokenize_literal
            else
              false
            end
          end
        end

        private def tokenize_string
          @scanner.pos = @position
          if (matched = @scanner.scan(STRING_PATTERN))
            # Extract content (remove quotes)
            content = matched[1...-1]
            # Only unescape if string contains backslashes (fast path for unescaped strings)
            unescaped = content.includes?("\\") ? unescape_string(content) : content
            add_token(WireGram::Core::TokenType::String, unescaped, position: @scanner.pos)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def unescape_string(str)
          # Fast path: if no backslashes, return as-is (already checked by caller)
          return str unless str.includes?("\\")

          String.build do |builder|
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
                  builder << "\b"
                  i += 2
                when 'f'
                  builder << "\f"
                  i += 2
                when 'n'
                  builder << "\n"
                  i += 2
                when 'r'
                  builder << "\r"
                  i += 2
                when 't'
                  builder << "\t"
                  i += 2
                when 'u'
                  # Unicode escape \uXXXX
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
                  builder << str[i]
                  i += 1
                end
              else
                builder << str[i]
                i += 1
              end
            end
          end
        end

        def tokenize_number
          @scanner.pos = @position
          if (matched = @scanner.scan(NUMBER_PATTERN))
            number_text = matched
            if number_text.includes?(".") || number_text.includes?('e') || number_text.includes?('E')
              begin
                value = number_text.to_f
              rescue ex : ArgumentError
                value = number_text.starts_with?("-") ? -Float64::INFINITY : Float64::INFINITY
              end
            else
              value = number_text.to_i64
            end
            add_token(WireGram::Core::TokenType::Number, value, position: @scanner.pos)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def tokenize_literal
          @scanner.pos = @position
          if @scanner.scan(TRUE_PATTERN)
            add_token(WireGram::Core::TokenType::Boolean, true, position: @scanner.pos)
            @position = @scanner.pos
            true
          elsif @scanner.scan(FALSE_PATTERN)
            add_token(WireGram::Core::TokenType::Boolean, false, position: @scanner.pos)
            @position = @scanner.pos
            true
          elsif @scanner.scan(NULL_PATTERN)
            add_token(WireGram::Core::TokenType::Null, nil, position: @scanner.pos)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def skip_whitespace
          @scanner.pos = @position
          @scanner.skip(WHITESPACE_PATTERN)
          @position = @scanner.pos
        end
      end
    end
  end
end
