# frozen_string_literal: true

require "../../core/lexer"
require "../../core/scanner"

module WireGram
  module Languages
    module Expression
      # High-performance lexer for simple expression language using byte-based scanning
      # Supports: numbers, identifiers, operators, keywords (let)
      class Lexer < WireGram::Core::BaseLexer
        KEYWORDS = {"let" => true}

        def initialize(source, use_simd = false, use_symbolic_utf8 = false, use_upfront_rules = false, use_branchless = false, use_brzozowski = false, use_gpu = false, verbose = false)
          super(source)
          @use_simd = use_simd
          @use_symbolic_utf8 = use_symbolic_utf8
          @use_upfront_rules = use_upfront_rules
          @use_branchless = use_branchless
          @use_brzozowski = use_brzozowski
          @use_gpu = use_gpu
          @verbose = verbose
          @scanner = WireGram::Core::Scanner.new(source)
          STDERR.puts "[Expression::Lexer] Initializing (SIMD=#{@use_simd}, Upfront=#{@use_upfront_rules}, Branchless=#{@use_branchless}, Brzozowski=#{@use_brzozowski}, GPU=#{@use_gpu})" if @verbose
          build_structural_index! if use_upfront_rules
        end

        private def try_tokenize_next
          byte = current_byte
          return false unless byte

          case byte
          when 0x2b # '+'
            add_token(WireGram::Core::TokenType::Plus, "+")
            advance
            true
          when 0x2d # '-'
            add_token(WireGram::Core::TokenType::Minus, "-")
            advance
            true
          when 0x2a # '*'
            add_token(WireGram::Core::TokenType::Star, "*")
            advance
            true
          when 0x2f # '/'
            add_token(WireGram::Core::TokenType::Slash, "/")
            advance
            true
          when 0x3d # '='
            add_token(WireGram::Core::TokenType::Equals, "=")
            advance
            true
          when 0x28 # '('
            add_token(WireGram::Core::TokenType::LParen, "(")
            advance
            true
          when 0x29 # ')'
            add_token(WireGram::Core::TokenType::RParen, ")")
            advance
            true
          when 0x22 # '"'
            tokenize_string_fast
          else
            if (0x30..0x39).includes?(byte) # '0'-'9'
              tokenize_number_fast
            elsif (0x61..0x7a).includes?(byte) || (0x41..0x5a).includes?(byte) || byte == 0x5f # [a-zA-Z_]
              tokenize_identifier_fast
            else
              false
            end
          end
        end

        private def tokenize_number_fast
          start = @position
          # We know first byte is a digit from caller
          advance

          while (byte = current_byte) && (0x30..0x39).includes?(byte)
            advance
          end

          if current_byte == 0x2e # '.'
            next_byte = peek_byte(1)
            if next_byte && (0x30..0x39).includes?(next_byte)
              advance # skip '.'
              while (byte = current_byte) && (0x30..0x39).includes?(byte)
                advance
              end
            end
          end

          matched = @source.byte_slice(start, @position - start)
          value = matched.includes?('.') ? matched.to_f : matched.to_i64
          add_token(WireGram::Core::TokenType::Number, value, position: @position)
          true
        end

        def tokenize_identifier_fast
          start = @position
          # We know first byte is [a-zA-Z_] from caller
          advance

          while (byte = current_byte) && ((0x61..0x7a).includes?(byte) || (0x41..0x5a).includes?(byte) || (0x30..0x39).includes?(byte) || byte == 0x5f)
            advance
          end

          value = @source.byte_slice(start, @position - start)
          type = KEYWORDS.has_key?(value) ? WireGram::Core::TokenType::Keyword : WireGram::Core::TokenType::Identifier
          add_token(type, value, position: @position)
          true
        end

        def tokenize_string_fast
          start = @position
          advance # skip opening quote

          while (byte = current_byte)
            if byte == 0x22 # '"'
              advance
              matched = @source.byte_slice(start, @position - start)
              # Remove surrounding quotes
              content = matched[1...-1]
              # Fast-path: avoid unescaping for common case with no backslashes
              unescaped = content.includes?("\\") ? unescape_string(content) : content
              add_token(WireGram::Core::TokenType::String, unescaped, position: @position)
              return true
            elsif byte == 0x5c # '\\'
              advance
              advance if current_byte # skip escaped char
            else
              advance
            end
          end

          false # Unterminated string
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
