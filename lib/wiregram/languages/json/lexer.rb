# frozen_string_literal: true

require_relative '../../core/lexer'

module WireGram
  module Languages
    module Json
      # Minimal JSON lexer
      class Lexer < WireGram::Core::BaseLexer
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
          when /[\-0-9]/
            tokenize_number
          when /[tfn]/i
            tokenize_literal
          else
            false
          end
        end

        private

        def tokenize_string
          advance # skip opening quote
          start = @position
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
                # unicode escape \uXXXX — best-effort: parse hex
                hex = String.new
                4.times do
                  advance
                  hex << (current_char || '')
                end
                value << ([hex.to_i(16)].pack('U') rescue '?')
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
          add_token(:string, value)
          true
        end

        def tokenize_number
          start = @position

          # sign
          advance if current_char == '-'

          # integer part
          if current_char == '0'
            advance
          else
            advance while current_char&.match?(/[0-9]/)
          end

          # fraction
          if current_char == '.'
            advance
            advance while current_char&.match?(/[0-9]/)
          end

          # exponent
          if current_char&.match?(/[eE]/)
            advance
            advance if current_char&.match?(/[+-]/)
            advance while current_char&.match?(/[0-9]/)
          end

          raw = @source[start...@position]
          value = raw.include?('.') || raw.match?(/[eE]/) ? raw.to_f : raw.to_i
          add_token(:number, value)
          true
        end

        def tokenize_literal
          # true, false, null
          if @source[@position..].start_with?('true')
            4.times { advance }
            add_token(:boolean, true)
            true
          elsif @source[@position..].start_with?('false')
            5.times { advance }
            add_token(:boolean, false)
            true
          elsif @source[@position..].start_with?('null')
            4.times { advance }
            add_token(:null, nil)
            true
          else
            false
          end
        end
      end
    end
  end
end
