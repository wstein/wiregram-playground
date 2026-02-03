# Minimal Ruby lexer used for integration tests
# Focused implementation that is simple, well-tested, and small.
# It emits `Warp::Lang::Ruby::Token` with `kind : TokenKind`, `start` and `length`.

module Warp
  module Lang
    module Ruby
      alias ErrorCode = Warp::Core::ErrorCode

      struct Token
        property kind : TokenKind
        property start : Int32
        property length : Int32

        def initialize(@kind : TokenKind, @start : Int32, @length : Int32)
        end
      end

      KEYWORDS = {
        "def"    => TokenKind::Def,
        "end"    => TokenKind::End,
        "class"  => TokenKind::Class,
        "module" => TokenKind::Module,
        "if"     => TokenKind::If,
        "elsif"  => TokenKind::Elsif,
        "else"   => TokenKind::Else,
        "unless" => TokenKind::Unless,
        "while"  => TokenKind::While,
        "until"  => TokenKind::Until,
        "for"    => TokenKind::For,
        "in"     => TokenKind::In,
        "do"     => TokenKind::Do,
        "return" => TokenKind::Return,
        "true"   => TokenKind::True,
        "false"  => TokenKind::False,
        "nil"    => TokenKind::Nil,
        "yield"  => TokenKind::Yield,
        "when"   => TokenKind::When,
      }

      def self.scan(bytes : Bytes) : Tuple(Array(Token), Warp::Core::ErrorCode, Int32)
        # Module-level compatibility: this method is used internally by tests and other code.
        if ENV["WARP_SIMD_RUBY"]? == "1"
          simd_result = Warp::Lang::Ruby.simd_scan(bytes)
          if simd_result.error == Warp::Core::ErrorCode::Utf8Error
            return {Array(Token).new, Warp::Core::ErrorCode::Utf8Error, 0}
          end
        end

        tokens = [] of Token
        i = 0
        len = bytes.size

        last_nonspace_kind : TokenKind? = nil

        while i < len
          start_i = i
          c = bytes[i]

          # Newlines
          if c == '\n'.ord || c == '\r'.ord
            tokens << Token.new(TokenKind::Newline, i, 1)
            i += 1
            last_nonspace_kind = TokenKind::Newline
            next
          end

          # space / tab
          if c == ' '.ord || c == '\t'.ord
            j = i
            while j < len && (bytes[j] == ' '.ord || bytes[j] == '\t'.ord)
              j += 1
            end
            tokens << Token.new(TokenKind::Whitespace, i, j - i)
            i = j
            next
          end

          # comments
          if c == '#'.ord
            j = if ENV["WARP_SIMD_RUBY"]? == "1"
                  scan_to_line_end(bytes, i + 1)
                else
                  k = i + 1
                  while k < len && bytes[k] != '\n'.ord && bytes[k] != '\r'.ord
                    k += 1
                  end
                  k
                end
            tokens << Token.new(TokenKind::CommentLine, i, j - i)
            i = j
            next
          end

          # heredoc start <<, <<- or <<~
          if c == '<'.ord && i + 1 < len && bytes[i + 1] == '<'.ord
            # parse delimiter
            j = i + 2
            # skip - or ~ (optional)
            if j < len && (bytes[j] == '-'.ord || bytes[j] == '~'.ord)
              j += 1
            end
            # Do NOT skip whitespace here — heredoc delimiter must follow directly
            # read delimiter token (word or quoted)
            delim_start = j
            if j < len && (bytes[j] == '"'.ord || bytes[j] == '\''.ord)
              quote = bytes[j]
              j += 1
              while j < len && bytes[j] != quote
                j += 1
              end
              delim = String.new(bytes[delim_start, j - delim_start])
              j += 1 if j < len
            else
              while j < len && (is_identifier_char(bytes[j]) || bytes[j] == '_'.ord)
                j += 1
              end
              delim = String.new(bytes[delim_start, j - delim_start])
            end

            # If delimiter is empty (e.g. there was whitespace), this is not a heredoc — treat as operator
            if delim.bytesize == 0
              # fall through to operator handling
            else
              # move to next line start
              while j < len && bytes[j] != '\n'.ord && bytes[j] != '\r'.ord
                j += 1
              end
              if j < len && bytes[j] == '\r'.ord
                j += 1
              end
              if j < len && bytes[j] == '\n'.ord
                j += 1
              end
              # search for delimiter at line start
              k = j
              found = -1
              while k < len
                line_start = k
                # skip leading whitespace
                while k < len && (bytes[k] == ' '.ord || bytes[k] == '\t'.ord)
                  k += 1
                end
                # match delimiter
                if match_literal(bytes, k, delim)
                  k += delim.bytesize
                  # ensure end of line
                  if k >= len || bytes[k] == '\n'.ord || bytes[k] == '\r'.ord
                    found = k
                    # consume rest of line
                    while k < len && bytes[k] != '\n'.ord && bytes[k] != '\r'.ord
                      k += 1
                    end
                    if k < len && bytes[k] == '\r'.ord
                      k += 1
                    end
                    if k < len && bytes[k] == '\n'.ord
                      k += 1
                    end
                    break
                  end
                end
                # advance to next line
                while k < len && bytes[k] != '\n'.ord && bytes[k] != '\r'.ord
                  k += 1
                end
                if k < len && bytes[k] == '\r'.ord
                  k += 1
                end
                if k < len && bytes[k] == '\n'.ord
                  k += 1
                end
              end
              end_idx = (found >= 0) ? found : k
              tokens << Token.new(TokenKind::Heredoc, i, end_idx - i)
              i = end_idx
              last_nonspace_kind = TokenKind::Heredoc
              next
            end
          end

          # strings
          if c == '"'.ord
            j = i + 1
            found = false
            while j < len
              if bytes[j] == '\\'.ord
                j += 2
                next
              elsif bytes[j] == '"'.ord
                j += 1
                found = true
                break
              else
                j += 1
              end
            end
            unless found
              return {tokens, ErrorCode::StringError, start_i}
            end
            tokens << Token.new(TokenKind::String, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::String
            next
          end

          if c == '\''.ord
            j = i + 1
            found = false
            while j < len
              if bytes[j] == '\\'.ord
                j += 2
                next
              elsif bytes[j] == '\''.ord
                j += 1
                found = true
                break
              else
                j += 1
              end
            end
            unless found
              return {tokens, ErrorCode::StringError, start_i}
            end
            tokens << Token.new(TokenKind::String, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::String
            next
          end

          # regex simple form when in expression position
          if c == '/'.ord && should_be_regex(last_nonspace_kind)
            j = i + 1
            while j < len
              if bytes[j] == '\\'.ord
                j += 2
                next
              elsif bytes[j] == '/'.ord
                j += 1
                # Handle regex modifiers (e.g., /pattern/i)
                while j < len && (bytes[j] == 'i'.ord || bytes[j] == 'm'.ord || bytes[j] == 'x'.ord || bytes[j] == 'o'.ord)
                  j += 1
                end
                break
              else
                j += 1
              end
            end
            if j >= len
              return {tokens, ErrorCode::StringError, start_i}
            end
            tokens << Token.new(TokenKind::Regex, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::Regex
            next
          end

          # numbers
          if c >= '0'.ord && c <= '9'.ord
            j = i
            while j < len && ((bytes[j] >= '0'.ord && bytes[j] <= '9'.ord) || bytes[j] == '_'.ord)
              j += 1
            end
            if j < len && bytes[j] == '.'.ord && (j + 1 < len && bytes[j + 1] >= '0'.ord && bytes[j + 1] <= '9'.ord)
              j += 1
              while j < len && ((bytes[j] >= '0'.ord && bytes[j] <= '9'.ord) || bytes[j] == '_'.ord)
                j += 1
              end
              tokens << Token.new(TokenKind::Float, i, j - i)
              i = j
              last_nonspace_kind = TokenKind::Float
              next
            end
            tokens << Token.new(TokenKind::Number, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::Number
            next
          end

          # variables and identifiers
          if is_identifier_start(c)
            j = i + 1
            while j < len && is_identifier_char(bytes[j])
              j += 1
            end
            # include trailing ? or !
            if j < len && (bytes[j] == '?'.ord || bytes[j] == '!'.ord)
              j += 1
            end
            txt = String.new(bytes[i, j - i])
            if KEYWORDS[txt]?
              tokens << Token.new(KEYWORDS[txt], i, j - i)
              last_nonspace_kind = KEYWORDS[txt]
            elsif txt[0].uppercase?
              tokens << Token.new(TokenKind::Constant, i, j - i)
              last_nonspace_kind = TokenKind::Constant
            else
              tokens << Token.new(TokenKind::Identifier, i, j - i)
              last_nonspace_kind = TokenKind::Identifier
            end
            i = j
            next
          end

          # instance/class/global vars
          if c == '@'.ord
            if i + 1 < len && bytes[i + 1] == '@'.ord
              j = i + 2
              while j < len && is_identifier_char(bytes[j])
                j += 1
              end
              tokens << Token.new(TokenKind::ClassVar, i, j - i)
              i = j
              last_nonspace_kind = TokenKind::ClassVar
              next
            else
              j = i + 1
              while j < len && is_identifier_char(bytes[j])
                j += 1
              end
              tokens << Token.new(TokenKind::InstanceVar, i, j - i)
              i = j
              last_nonspace_kind = TokenKind::InstanceVar
              next
            end
          end

          if c == '$'.ord
            j = i + 1
            while j < len && (is_identifier_char(bytes[j]) || (bytes[j] >= '0'.ord && bytes[j] <= '9'.ord))
              j += 1
            end
            tokens << Token.new(TokenKind::GlobalVar, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::GlobalVar
            next
          end

          # symbols (:symbol)
          if c == ':'.ord
            if i + 1 < len && is_identifier_start(bytes[i + 1])
              j = i + 1
              while j < len && is_identifier_char(bytes[j])
                j += 1
              end
              tokens << Token.new(TokenKind::Symbol, i, j - i)
              i = j
              last_nonspace_kind = TokenKind::Symbol
              next
            elsif i + 1 < len && bytes[i + 1] == ':'.ord
              tokens << Token.new(TokenKind::DoubleColon, i, 2)
              i += 2
              last_nonspace_kind = TokenKind::DoubleColon
              next
            else
              tokens << Token.new(TokenKind::Colon, i, 1)
              i += 1
              last_nonspace_kind = TokenKind::Colon
              next
            end
          end

          # punctuation and operators (two-char and single-char)
          next_c = i + 1 < len ? bytes[i + 1] : 0u8

          # Two-char operators
          if c == '<'.ord && next_c == '='.ord && i + 2 < len && bytes[i + 2] == '>'.ord
            tokens << Token.new(TokenKind::Spaceship, i, 3); i += 3; last_nonspace_kind = TokenKind::Spaceship; next
          elsif c == '<'.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::LessEqual, i, 2); i += 2; last_nonspace_kind = TokenKind::LessEqual; next
          elsif c == '>'.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::GreaterEqual, i, 2); i += 2; last_nonspace_kind = TokenKind::GreaterEqual; next
          elsif c == '='.ord && next_c == '~'.ord
            tokens << Token.new(TokenKind::Match, i, 2); i += 2; last_nonspace_kind = TokenKind::Match; next
          elsif c == '!'.ord && next_c == '~'.ord
            tokens << Token.new(TokenKind::NotMatch, i, 2); i += 2; last_nonspace_kind = TokenKind::NotMatch; next
          elsif c == '*'.ord && next_c == '*'.ord
            tokens << Token.new(TokenKind::Power, i, 2); i += 2; last_nonspace_kind = TokenKind::Power; next
          elsif c == '='.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::Equal, i, 2); i += 2; last_nonspace_kind = TokenKind::Equal; next
          elsif c == '!'.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::NotMatch, i, 2); i += 2; last_nonspace_kind = TokenKind::NotMatch; next
          elsif c == '&'.ord && next_c == '&'.ord
            tokens << Token.new(TokenKind::LogicalAnd, i, 2); i += 2; last_nonspace_kind = TokenKind::LogicalAnd; next
          elsif c == '|'.ord && next_c == '|'.ord
            tokens << Token.new(TokenKind::LogicalOr, i, 2); i += 2; last_nonspace_kind = TokenKind::LogicalOr; next
          elsif c == '<'.ord && next_c == '<'.ord && !(i + 2 < len && bytes[i + 2] == '<'.ord)
            # left shift (not heredoc which is handled earlier)
            tokens << Token.new(TokenKind::LeftShift, i, 2); i += 2; last_nonspace_kind = TokenKind::LeftShift; next
          elsif c == '>'.ord && next_c == '>'.ord
            tokens << Token.new(TokenKind::RightShift, i, 2); i += 2; last_nonspace_kind = TokenKind::RightShift; next
          end

          case c
          when '('.ord
            tokens << Token.new(TokenKind::LParen, i, 1); i += 1; last_nonspace_kind = TokenKind::LParen; next
          when ')'.ord
            tokens << Token.new(TokenKind::RParen, i, 1); i += 1; last_nonspace_kind = TokenKind::RParen; next
          when '{'.ord
            tokens << Token.new(TokenKind::LBrace, i, 1); i += 1; last_nonspace_kind = TokenKind::LBrace; next
          when '}'.ord
            tokens << Token.new(TokenKind::RBrace, i, 1); i += 1; last_nonspace_kind = TokenKind::RBrace; next
          when '['.ord
            tokens << Token.new(TokenKind::LBracket, i, 1); i += 1; last_nonspace_kind = TokenKind::LBracket; next
          when ']'.ord
            tokens << Token.new(TokenKind::RBracket, i, 1); i += 1; last_nonspace_kind = TokenKind::RBracket; next
          when ','.ord
            tokens << Token.new(TokenKind::Comma, i, 1); i += 1; last_nonspace_kind = TokenKind::Comma; next
          when '.'.ord
            tokens << Token.new(TokenKind::Dot, i, 1); i += 1; last_nonspace_kind = TokenKind::Dot; next
          when '+'.ord
            tokens << Token.new(TokenKind::Plus, i, 1); i += 1; last_nonspace_kind = TokenKind::Plus; next
          when '-'.ord
            tokens << Token.new(TokenKind::Minus, i, 1); i += 1; last_nonspace_kind = TokenKind::Minus; next
          when '*'.ord
            tokens << Token.new(TokenKind::Star, i, 1); i += 1; last_nonspace_kind = TokenKind::Star; next
          when '/'.ord
            tokens << Token.new(TokenKind::Slash, i, 1); i += 1; last_nonspace_kind = TokenKind::Slash; next
          when '%'.ord
            # percent operator or percent literal
            if i + 1 < len && ((bytes[i + 1] >= 'a'.ord && bytes[i + 1] <= 'z'.ord) || (bytes[i + 1] >= 'A'.ord && bytes[i + 1] <= 'Z'.ord))
              # percent literal: find matching delimiter
              lit_type = bytes[i + 1]
              d = i + 2
              if d < len
                delim = bytes[d]
                # support paired delimiters
                close = case delim
                        when '('.ord then ')'.ord
                        when '{'.ord then '}'.ord
                        when '['.ord then ']'.ord
                        else              delim
                        end
                k = d + 1
                while k < len && bytes[k] != close
                  if bytes[k] == '\\'.ord
                    k += 2
                    next
                  end
                  k += 1
                end
                if k < len && bytes[k] == close
                  tokens << Token.new(TokenKind::String, i, k - i + 1)
                  i = k + 1
                  last_nonspace_kind = TokenKind::String
                  next
                end
              end
            end
            tokens << Token.new(TokenKind::Percent, i, 1); i += 1; last_nonspace_kind = TokenKind::Percent; next
          when '~'.ord
            tokens << Token.new(TokenKind::Tilde, i, 1); i += 1; last_nonspace_kind = TokenKind::Tilde; next
          when ';'.ord
            tokens << Token.new(TokenKind::Semicolon, i, 1); i += 1; last_nonspace_kind = TokenKind::Semicolon; next
          when '?'.ord
            tokens << Token.new(TokenKind::Question, i, 1); i += 1; last_nonspace_kind = TokenKind::Question; next
          when '='.ord
            tokens << Token.new(TokenKind::Equal, i, 1); i += 1; last_nonspace_kind = TokenKind::Equal; next
          when '!'.ord
            tokens << Token.new(TokenKind::Not, i, 1); i += 1; last_nonspace_kind = TokenKind::Not; next
          when '<'.ord
            tokens << Token.new(TokenKind::LessThan, i, 1); i += 1; last_nonspace_kind = TokenKind::LessThan; next
          when '>'.ord
            tokens << Token.new(TokenKind::GreaterThan, i, 1); i += 1; last_nonspace_kind = TokenKind::GreaterThan; next
          when '&'.ord
            tokens << Token.new(TokenKind::Ampersand, i, 1); i += 1; last_nonspace_kind = TokenKind::Ampersand; next
          when '|'.ord
            tokens << Token.new(TokenKind::Pipe, i, 1); i += 1; last_nonspace_kind = TokenKind::Pipe; next
          end

          # fallback: unknown single byte
          tokens << Token.new(TokenKind::Unknown, i, 1)
          i += 1
        end

        tokens << Token.new(TokenKind::Eof, len, 0)
        {tokens, ErrorCode::Success, 0}
      end

      private def self.match_literal(bytes : Bytes, start : Int32, literal : String) : Bool
        return false if start + literal.bytesize > bytes.size
        literal.bytes.each_with_index do |b, offset|
          return false unless bytes[start + offset] == b
        end
        true
      end

      private def self.is_identifier_start(c : UInt8) : Bool
        (c >= 'a'.ord && c <= 'z'.ord) || (c >= 'A'.ord && c <= 'Z'.ord) || c == '_'.ord
      end

      private def self.is_identifier_char(c : UInt8) : Bool
        is_identifier_start(c) || (c >= '0'.ord && c <= '9'.ord)
      end

      private def self.should_be_regex(last_kind : TokenKind?) : Bool
        return true if last_kind == nil
        case last_kind
        when TokenKind::LParen, TokenKind::LBracket, TokenKind::LBrace, TokenKind::Comma, TokenKind::Semicolon,
             TokenKind::Newline, TokenKind::Return, TokenKind::Do, TokenKind::If, TokenKind::Unless, TokenKind::While,
             TokenKind::Equal, TokenKind::Match, TokenKind::NotMatch, TokenKind::Tilde
          true
        else
          false
        end
      end

      private def self.scan_to_line_end(bytes : Bytes, start : Int32) : Int32
        len = bytes.size
        return len if start >= len
        backend = Warp::Backend.current
        ptr = bytes.to_unsafe
        i = start
        while i < len
          block_len = len - i
          block_len = 64 if block_len > 64
          mask = backend.newline_mask(ptr + i, block_len)
          if mask != 0
            return i + mask.trailing_zeros_count
          end
          i += 64
        end
        len
      end

      # Expose a `Lexer` class for compatibility with existing callers/tests.
      class Lexer
        def self.scan(bytes : Bytes) : Tuple(Array(Token), Warp::Core::ErrorCode, Int32)
          Warp::Lang::Ruby.scan(bytes)
        end
      end
    end
  end
end
