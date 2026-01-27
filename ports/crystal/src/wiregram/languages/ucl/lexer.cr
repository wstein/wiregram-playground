# frozen_string_literal: true

require "../../core/lexer"
require "../../core/scanner"

module WireGram
  module Languages
    module Ucl
      # UCL (Universal Configuration Language) Lexer - high-performance byte-based scanner
      # Tokenizes UCL syntax including objects, arrays, strings, numbers, and comments
      class Lexer < WireGram::Core::BaseLexer
        KEYWORDS = {
          "true" => true, "false" => false, "yes" => true, "no" => false,
          "on" => true, "off" => false, "null" => nil, "nil" => nil
        }

        STRUCTURAL_MAP = {
          0x7b_u8 => WireGram::Core::TokenType::LBrace,    # '{'
          0x7d_u8 => WireGram::Core::TokenType::RBrace,    # '}'
          0x5b_u8 => WireGram::Core::TokenType::LBracket,  # '['
          0x5d_u8 => WireGram::Core::TokenType::RBracket,  # ']'
          0x3a_u8 => WireGram::Core::TokenType::Colon,     # ':'
          0x3d_u8 => WireGram::Core::TokenType::Equals,    # '='
          0x3b_u8 => WireGram::Core::TokenType::Semicolon, # ';'
          0x2c_u8 => WireGram::Core::TokenType::Comma,     # ','
          0x28_u8 => WireGram::Core::TokenType::LParen,    # '('
          0x29_u8 => WireGram::Core::TokenType::RParen     # ')'
        }

        def initialize(source, use_simd = false, use_symbolic_utf8 = false, use_upfront_rules = false)
          super(source)
          @use_simd = use_simd
          @use_symbolic_utf8 = use_symbolic_utf8
          @use_upfront_rules = use_upfront_rules
          @scanner = WireGram::Core::Scanner.new(source)
          build_structural_index! if use_upfront_rules
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        # Reason: Complex branching is intentional for performance-sensitive tokenization.
        # The method is organized for fast-paths and minimal allocations.
        private def try_tokenize_next
          skip_whitespace
          return true if @position >= @source.bytesize

          # Handle comments
          return true if skip_comment

          byte = current_byte
          return false unless byte

          # 1. Structural/Punctuation tokens (High Frequency)
          if (type = STRUCTURAL_MAP[byte]?)
            add_token(type, byte.chr.to_s)
            advance
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
          if is_url_start?
            return tokenize_unquoted_string
          end

          # If starting with a letter, check if the following characters lead into an interpolation
          if (0x61..0x7a).includes?(byte) || (0x41..0x5a).includes?(byte) || byte == 0x5f # [a-zA-Z_]
            # Fast check for interpolation after potential identifier
            pos = @position + 1
            while (b = peek_byte(pos - @position)) && ((0x61..0x7a).includes?(b) || (0x41..0x5a).includes?(b) || (0x30..0x39).includes?(b) || b == 0x5f || b == 0x25 || b == 0x2d)
              pos += 1
            end
            if peek_byte(pos - @position) == 0x24 && peek_byte(pos - @position + 1) == 0x7b # '${'
              return tokenize_unquoted_string
            end
            return tokenize_identifier_or_keyword
          elsif byte == 0x2f # '/'
            # Check for URL before treating as unquoted string
            return tokenize_unquoted_string if is_url_start?
          end

          false
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        private def is_url_start?
          # quick check for [a-zA-Z0-9_\-.]+://
          pos = @position
          while pos < @bytes.size
            b = @bytes[pos]
            if (0x61..0x7a).includes?(b) || (0x41..0x5a).includes?(b) || (0x30..0x39).includes?(b) || b == 0x5f || b == 0x2d || b == 0x2e
              pos += 1
            else
              break
            end
          end
          return false if pos == @position
          return @bytes[pos]? == 0x3a && @bytes[pos + 1]? == 0x2f && @bytes[pos + 2]? == 0x2f # ://
        end

        private def skip_whitespace
          while (byte = current_byte)
            # \s = 0x20 (space), 0x09 (tab), 0x0a (LF), 0x0d (CR), 0x0b (VT), 0x0c (FF)
            if byte == 0x20 || (byte >= 0x09 && byte <= 0x0d)
              advance
            else
              break
            end
          end
        end

        def skip_comment
          byte = current_byte
          if byte == 0x23 # '#'
            # Fast-skip to end of line
            while (byte = current_byte) && byte != 0x0a # '\n'
              advance
            end
            advance if current_byte == 0x0a
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
          start = @position
          advance # skip '.'
          while (byte = current_byte) && ((0x61..0x7a).includes?(byte) || (0x41..0x5a).includes?(byte) || (0x30..0x39).includes?(byte) || byte == 0x5f || byte == 0x2d || byte == 0x2e)
            advance
          end

          if @position > start + 1
            # Store without leading dot
            add_token(WireGram::Core::TokenType::Directive, @source.byte_slice(start + 1, @position - start - 1), position: @position)
            true
          else
            @position = start
            false
          end
        end

        def tokenize_quoted_string_fast
          start = @position
          advance # skip opening quote

          while (byte = current_byte)
            if byte == 0x22 # '"'
              advance
              matched = @source.byte_slice(start, @position - start)
              # Extract content (without surrounding quotes)
              content = matched[1...-1]
              # Fast-path: avoid unescaping if there are no backslashes
              unescaped = content.includes?("\\") ? unescape_quoted_string(content) : content
              extras = { :quoted => true, :quote_type => :double } of Symbol => WireGram::Core::TokenExtraValue
              add_token(WireGram::Core::TokenType::String, unescaped, extras: extras, position: @position)
              return true
            elsif byte == 0x5c # '\\'
              advance
              advance if current_byte
            else
              advance
            end
          end
          false
        end

        def tokenize_single_quoted_string_fast
          start = @position
          advance # skip opening quote

          while (byte = current_byte)
            if byte == 0x27 # '\''
              advance
              matched = @source.byte_slice(start, @position - start)
              content = matched[1...-1]
              # Fast-path: avoid unescaping if there are no backslashes
              unescaped = content.includes?("\\") ? unescape_single_quoted_string(content) : content
              extras = { :quoted => true, :quote_type => :single } of Symbol => WireGram::Core::TokenExtraValue
              add_token(WireGram::Core::TokenType::String, unescaped, extras: extras, position: @position)
              return true
            elsif byte == 0x5c # '\\'
              advance
              advance if current_byte
            else
              advance
            end
          end
          false
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

        private def has_uppercase?(str : String) : Bool
          str.each_byte do |byte|
            return true if byte >= 0x41 && byte <= 0x5a
          end
          false
        end

        def tokenize_identifier_or_keyword
          start = @position
          # Allow leading '-', '%'
          byte = current_byte
          if byte == 0x2d || byte == 0x25
            advance
          end

          while (byte = current_byte)
            # [a-zA-Z0-9_%-]
            if (0x61..0x7a).includes?(byte) || (0x41..0x5a).includes?(byte) || (0x30..0x39).includes?(byte) || byte == 0x5f || byte == 0x25 || byte == 0x2d
              advance
            else
              break
            end
          end

          value = @source.byte_slice(start, @position - start)
          return false if value.empty?

          # Use Hash lookup for keywords (much faster than case/downcase)
          # Fast path: try direct lookup (no allocation if already lowercase)
          if KEYWORDS.has_key?(value)
            v = KEYWORDS[value]
            if v.nil?
              add_token(WireGram::Core::TokenType::Null, nil, position: @position)
            else
              add_token(WireGram::Core::TokenType::Boolean, v, position: @position)
            end
            return true
          end

          # Try downcase if needed
          lc = has_uppercase?(value) ? value.downcase : value
          if lc != value && KEYWORDS.has_key?(lc)
            v = KEYWORDS[lc]
            if v.nil?
              add_token(WireGram::Core::TokenType::Null, nil, position: @position)
            else
              add_token(WireGram::Core::TokenType::Boolean, v, position: @position)
            end
          else
            add_token(WireGram::Core::TokenType::Identifier, value, position: @position)
          end

          true
        end

        private def find_delimiter(pos) : Int32
          while pos < @bytes.size
            byte = @bytes[pos]
            # \s , ; : } ) "
            if byte <= 0x20 || byte == 0x2c || byte == 0x3b || byte == 0x3a || byte == 0x7d || byte == 0x29 || byte == 0x22
              return pos
            end
            pos += 1
          end
          pos
        end

        def tokenize_unquoted_string
          start = @position
          src = @source

          # If URL at current position, consume entire URL until next delimiter (allow ':' in URL)
          if is_url_start?
            # Consume until next delimiter
            end_pos = find_delimiter(start)
            @position = end_pos
            add_token(WireGram::Core::TokenType::String, src.byte_slice(start, @position - start), position: @position)
            return true
          end

          # Fast path: check for interpolation without regex
          # We search for '${'
          interp_pos = src.index("${", start)
          delimiter_pos = find_delimiter(start)

          if interp_pos && interp_pos < delimiter_pos
            # interpolation occurs within the upcoming run
            close = find_matching_interpolation_close(src, interp_pos + 2)
            if close.nil?
              end_pos = src.bytesize
            else
              end_pos = find_delimiter(close + 1)
            end
            @position = end_pos
            add_token(WireGram::Core::TokenType::String, src.byte_slice(start, @position - start), position: @position)
            return true
          end

          # Fast path: consume until next delimiter (no interpolation present)
          if delimiter_pos > start
            @position = delimiter_pos
            add_token(WireGram::Core::TokenType::String, src.byte_slice(start, @position - start), position: @position)
            return true
          end

          # Fallback: handle interpolation and nested braces manually
          # (This part was already mostly manual but let's ensure it stays efficient)
          interp_depth = 0
          @position = start

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
          start = @position
          # We know it starts with '-0x', '0x', '-0X', or '0X'
          if current_byte == 0x2d # '-'
            advance
          end
          advance # '0'
          advance # 'x' or 'X'

          has_dot = false
          while (byte = current_byte)
            if (0x30..0x39).includes?(byte) || (0x61..0x66).includes?(byte) || (0x41..0x46).includes?(byte)
              advance
            elsif byte == 0x2e && !has_dot # '.'
              # Check if what follows is a hex digit
              nb = peek_byte(1)
              if nb && ((0x30..0x39).includes?(nb) || (0x61..0x66).includes?(nb) || (0x41..0x46).includes?(nb))
                has_dot = true
                advance
              else
                break
              end
            else
              break
            end
          end

          # If it stopped due to a non-hex digit and it's NOT a delimiter, it might be an invalid hex remainder
          byte = current_byte
          if byte && !(byte <= 0x20 || byte == 0x2c || byte == 0x3b || byte == 0x3a || byte == 0x7d || byte == 0x29 || byte == 0x22)
            # consume until delimiter as invalid hex
            while (byte = current_byte) && !(byte <= 0x20 || byte == 0x2c || byte == 0x3b || byte == 0x3a || byte == 0x7d || byte == 0x29 || byte == 0x22)
              advance
            end
            add_token(WireGram::Core::TokenType::InvalidHex, @source.byte_slice(start, @position - start), position: @position)
            return true
          end

          m = @source.byte_slice(start, @position - start)
          if has_dot
            add_token(WireGram::Core::TokenType::InvalidHex, m, position: @position)
          else
            add_token(WireGram::Core::TokenType::HexNumber, m, position: @position)
          end
          true
        end

        def tokenize_number_fast
          start = @position
          # Optional minus
          if current_byte == 0x2d # '-'
            advance
          end

          # Integer part
          byte = current_byte
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
            e_offset = 1
            e_next = peek_byte(e_offset)
            if e_next == 0x2b || e_next == 0x2d # '+' or '-'
              e_offset += 1
              e_next = peek_byte(e_offset)
            end

            if e_next && (0x30..0x39).includes?(e_next)
              advance # skip 'e' or 'E'
              if current_byte == 0x2b || current_byte == 0x2d # '+' or '-'
                advance
              end
              while (byte = current_byte) && (0x30..0x39).includes?(byte)
                advance
              end
            end
          end

          add_token(WireGram::Core::TokenType::Number, @source.byte_slice(start, @position - start), position: @position)
          true
        end
      end
    end
  end
end
