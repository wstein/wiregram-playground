# frozen_string_literal: true

require 'strscan'
require_relative '../../core/lexer'

module WireGram
  module Languages
    module Json
      # High-performance JSON lexer using StringScanner
      class Lexer < WireGram::Core::BaseLexer
        # Pre-compiled regex patterns for performance
        STRING_PATTERN = /"(?:\\.|[^"\\])*"/
        WHITESPACE_PATTERN = /\s+/
        NUMBER_PATTERN = /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/
        TRUE_PATTERN = /true/
        FALSE_PATTERN = /false/
        NULL_PATTERN = /null/

        def initialize(source)
          super(source)
          @scanner = StringScanner.new(source)
        end

        def next_token
          skip_whitespace

          # If at end, return EOF token
          if @position >= @source.length
            token = { type: :eof, value: nil, position: @position }
            unless @tokens.last && @tokens.last[:type] == :eof
              @tokens << token
            end
            return token
          end

          prev_len = @tokens.length

          if try_tokenize_next
            return @tokens.last if @tokens.length > prev_len
          else
            # Error recovery
            @errors << {
              type: :unknown_character,
              char: current_char,
              position: @position
            }
            token = { type: :unknown, value: current_char, position: @position }
            advance
            @tokens << token
            return token
          end

          # If we advanced to EOF, return EOF
          if @position >= @source.length
            token = { type: :eof, value: nil, position: @position }
            unless @tokens.last && @tokens.last[:type] == :eof
              @tokens << token
            end
            return token
          end
        end

        protected

        def try_tokenize_next
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
          when ','
            add_token(:comma, ','); advance; true
          when '"'
            tokenize_string
          when '-', '0'..'9'
            tokenize_number
          when 't', 'f', 'n'
            tokenize_literal
          else
            false
          end
        end

        private

        def tokenize_string
          # Use StringScanner to match full quoted string including escapes
          @scanner.pos = @position
          if matched = @scanner.scan(STRING_PATTERN)
            # Extract content (remove quotes)
            content = matched[1...-1]
            # Only unescape if string contains backslashes (fast path for unescaped strings)
            unescaped = content.include?('\\') ? unescape_string(content) : content
            add_token(:string, unescaped)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def unescape_string(str)
          # Fast path: if no backslashes, return as-is (already checked by caller)
          return str unless str.include?('\\')

          # Pre-allocate result buffer with estimated capacity (most strings don't have many escapes)
          result = String.new(capacity: str.length)
          i = 0
          
          while i < str.length
            if str[i] == '\\' && i + 1 < str.length
              case str[i + 1]
              when '"'
                result << '"'
                i += 2
              when '\\'
                result << '\\'
                i += 2
              when '/'
                result << '/'
                i += 2
              when 'b'
                result << "\b"
                i += 2
              when 'f'
                result << "\f"
                i += 2
              when 'n'
                result << "\n"
                i += 2
              when 'r'
                result << "\r"
                i += 2
              when 't'
                result << "\t"
                i += 2
              when 'u'
                # Unicode escape \uXXXX
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
              else
                result << str[i]
                i += 1
              end
            else
              result << str[i]
              i += 1
            end
          end
          result
        end

        def tokenize_number
          @scanner.pos = @position
          if matched = @scanner.scan(NUMBER_PATTERN)
            value = matched.include?('.') || matched.match?(/[eE]/) ? matched.to_f : matched.to_i
            add_token(:number, value)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def tokenize_literal
          @scanner.pos = @position
          if @scanner.scan(TRUE_PATTERN)
            add_token(:boolean, true)
            @position = @scanner.pos
            true
          elsif @scanner.scan(FALSE_PATTERN)
            add_token(:boolean, false)
            @position = @scanner.pos
            true
          elsif @scanner.scan(NULL_PATTERN)
            add_token(:null, nil)
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
