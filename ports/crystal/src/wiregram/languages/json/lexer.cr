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
        TRUE_PATTERN = /true/
        FALSE_PATTERN = /false/
        NULL_PATTERN = /null/

        def initialize(source, use_simd = false, use_symbolic_utf8 = false, use_upfront_rules = false)
          super(source)
          @use_simd = use_simd
          @use_symbolic_utf8 = use_symbolic_utf8
          @use_upfront_rules = use_upfront_rules
          @scanner = WireGram::Core::Scanner.new(source)
          build_structural_index! if use_upfront_rules
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
          start = @position
          advance # skip opening quote

          if @use_upfront_rules
            loop do
              teleport_to_next
              byte = current_byte
              break unless byte
              if byte == 0x22 # '"'
                advance
                break
              elsif byte == 0x5c # '\\'
                advance
                advance if current_byte
              end
            end
            matched = @source.byte_slice(start, @position - start)
            content = matched[1...-1]
            unescaped = content.includes?("\\") ? unescape_string(content) : content
            add_token(WireGram::Core::TokenType::String, unescaped, position: @position)
            true
          elsif (matched = @scanner.scan(STRING_PATTERN))
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
          start = @position

          # Optional minus
          if current_byte == 0x2d # '-'
            advance
          end

          # Integer part
          byte = current_byte
          unless byte && (0x30..0x39).includes?(byte)
            @position = start
            return false
          end

          if byte == 0x30 # '0'
            advance
          else
            # 1-9 followed by any number of digits
            advance
            while (byte = current_byte) && (0x30..0x39).includes?(byte)
              advance
            end
          end

          # Fractional part
          if current_byte == 0x2e # '.'
            # Check if what follows is a digit before advancing past '.'
            next_byte = peek_byte(1)
            if next_byte && (0x30..0x39).includes?(next_byte)
              advance # skip '.'
              while (byte = current_byte) && (0x30..0x39).includes?(byte)
                advance
              end
            end
          end

          # Exponent part
          byte = current_byte
          if byte == 0x65 || byte == 0x45 # 'e' or 'E'
            # Check if valid exponent follows
            e_offset = 1
            e_next = peek_byte(e_offset)
            if e_next == 0x2b || e_next == 0x2d # '+' or '-'
              e_offset += 1
              e_next = peek_byte(e_offset)
            end

            if e_next && (0x30..0x39).includes?(e_next)
              advance # skip 'e' or 'E'
              byte = current_byte
              if byte == 0x2b || byte == 0x2d # '+' or '-'
                advance
              end
              while (byte = current_byte) && (0x30..0x39).includes?(byte)
                advance
              end
            end
          end

          number_text = @source.byte_slice(start, @position - start)
          if number_text.includes?(".") || number_text.includes?('e') || number_text.includes?('E')
            begin
              value = number_text.to_f
            rescue ex : ArgumentError
              value = number_text.starts_with?("-") ? -Float64::INFINITY : Float64::INFINITY
            end
          else
            value = number_text.to_i64
          end
          add_token(WireGram::Core::TokenType::Number, value, position: @position)
          @scanner.pos = @position
          true
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
