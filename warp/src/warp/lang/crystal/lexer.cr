# Minimal Crystal lexer (Phase 1)
# Emits `Warp::Lang::Crystal::Token` with kind/start/length.

module Warp
  module Lang
    module Crystal
      KEYWORDS = {
        "def"        => TokenKind::Def,
        "end"        => TokenKind::End,
        "class"      => TokenKind::Class,
        "module"     => TokenKind::Module,
        "struct"     => TokenKind::Struct,
        "enum"       => TokenKind::Enum,
        "macro"      => TokenKind::Macro,
        "if"         => TokenKind::If,
        "elsif"      => TokenKind::Elsif,
        "else"       => TokenKind::Else,
        "unless"     => TokenKind::Unless,
        "while"      => TokenKind::While,
        "until"      => TokenKind::Until,
        "for"        => TokenKind::For,
        "in"         => TokenKind::In,
        "do"         => TokenKind::Do,
        "return"     => TokenKind::Return,
        "break"      => TokenKind::Break,
        "next"       => TokenKind::Next,
        "yield"      => TokenKind::Yield,
        "true"       => TokenKind::True,
        "false"      => TokenKind::False,
        "nil"        => TokenKind::Nil,
        "lib"        => TokenKind::Lib,
        "fun"        => TokenKind::Fun,
        "require"    => TokenKind::Require,
        "include"    => TokenKind::Include,
        "extend"     => TokenKind::Extend,
        "abstract"   => TokenKind::Abstract,
        "alias"      => TokenKind::Alias,
        "annotation" => TokenKind::Annotation,
        "private"    => TokenKind::Private,
        "protected"  => TokenKind::Protected,
        "self"       => TokenKind::Self,
        "super"      => TokenKind::Super,
      }

      def self.scan(bytes : Bytes) : Tuple(Array(Token), Warp::Core::ErrorCode)
        tokens = [] of Token
        i = 0
        len = bytes.size

        while i < len
          c = bytes[i]

          # Newlines
          if c == '\n'.ord || c == '\r'.ord
            tokens << Token.new(TokenKind::Newline, i, 1)
            i += 1
            next
          end

          # Whitespace
          if c == ' '.ord || c == '\t'.ord
            j = i
            while j < len && (bytes[j] == ' '.ord || bytes[j] == '\t'.ord)
              j += 1
            end
            tokens << Token.new(TokenKind::Whitespace, i, j - i)
            i = j
            next
          end

          # Comments (# ... end-of-line)
          if c == '#'.ord
            j = i + 1
            while j < len && bytes[j] != '\n'.ord && bytes[j] != '\r'.ord
              j += 1
            end
            tokens << Token.new(TokenKind::CommentLine, i, j - i)
            i = j
            next
          end

          # Macro delimiters {{ and }}
          if c == '{'.ord && i + 1 < len && bytes[i + 1] == '{'.ord
            tokens << Token.new(TokenKind::MacroStart, i, 2)
            i += 2
            next
          end
          if c == '}'.ord && i + 1 < len && bytes[i + 1] == '}'.ord
            tokens << Token.new(TokenKind::MacroEnd, i, 2)
            i += 2
            next
          end

          # Strings (double-quoted)
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
            return {tokens, Warp::Core::ErrorCode::StringError} unless found
            tokens << Token.new(TokenKind::String, i, j - i)
            i = j
            next
          end

          # Strings/char (single-quoted) - treated as String for now
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
            return {tokens, Warp::Core::ErrorCode::StringError} unless found
            tokens << Token.new(TokenKind::String, i, j - i)
            i = j
            next
          end

          # Numbers (int/float)
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
              next
            end
            tokens << Token.new(TokenKind::Number, i, j - i)
            i = j
            next
          end

          # Identifiers / constants
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
            elsif txt[0].uppercase?
              tokens << Token.new(TokenKind::Constant, i, j - i)
            else
              tokens << Token.new(TokenKind::Identifier, i, j - i)
            end
            i = j
            next
          end

          # Variables and identifiers with prefixes
          if c == '@'.ord
            if i + 1 < len && bytes[i + 1] == '@'.ord
              j = i + 2
              while j < len && is_identifier_char(bytes[j])
                j += 1
              end
              tokens << Token.new(TokenKind::ClassVar, i, j - i)
              i = j
              next
            elsif i + 1 < len && bytes[i + 1] == '['.ord
              # annotation start: @[...]
              tokens << Token.new(TokenKind::At, i, 1)
              i += 1
              next
            else
              j = i + 1
              while j < len && is_identifier_char(bytes[j])
                j += 1
              end
              tokens << Token.new(TokenKind::InstanceVar, i, j - i)
              i = j
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
            next
          end

          # Symbols (:symbol) and ::
          if c == ':'.ord
            if i + 1 < len && bytes[i + 1] == ':'.ord
              tokens << Token.new(TokenKind::DoubleColon, i, 2)
              i += 2
              next
            elsif i + 1 < len && is_identifier_start(bytes[i + 1])
              j = i + 1
              while j < len && is_identifier_char(bytes[j])
                j += 1
              end
              tokens << Token.new(TokenKind::Symbol, i, j - i)
              i = j
              next
            else
              tokens << Token.new(TokenKind::Colon, i, 1)
              i += 1
              next
            end
          end

          next_c = i + 1 < len ? bytes[i + 1] : 0u8

          # Two-char operators
          if c == '='.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::EqualEqual, i, 2); i += 2; next
          elsif c == '!'.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::NotEqual, i, 2); i += 2; next
          elsif c == '<'.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::LessEqual, i, 2); i += 2; next
          elsif c == '>'.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::GreaterEqual, i, 2); i += 2; next
          elsif c == '&'.ord && next_c == '&'.ord
            tokens << Token.new(TokenKind::LogicalAnd, i, 2); i += 2; next
          elsif c == '|'.ord && next_c == '|'.ord
            tokens << Token.new(TokenKind::LogicalOr, i, 2); i += 2; next
          elsif c == '*'.ord && next_c == '*'.ord
            tokens << Token.new(TokenKind::Power, i, 2); i += 2; next
          elsif c == '<'.ord && next_c == '<'.ord
            tokens << Token.new(TokenKind::LeftShift, i, 2); i += 2; next
          elsif c == '>'.ord && next_c == '>'.ord
            tokens << Token.new(TokenKind::RightShift, i, 2); i += 2; next
          elsif c == '-'.ord && next_c == '>'.ord
            tokens << Token.new(TokenKind::Arrow, i, 2); i += 2; next
          elsif c == '='.ord && next_c == '>'.ord
            tokens << Token.new(TokenKind::FatArrow, i, 2); i += 2; next
          end

          case c
          when '('.ord
            tokens << Token.new(TokenKind::LParen, i, 1); i += 1; next
          when ')'.ord
            tokens << Token.new(TokenKind::RParen, i, 1); i += 1; next
          when '{'.ord
            tokens << Token.new(TokenKind::LBrace, i, 1); i += 1; next
          when '}'.ord
            tokens << Token.new(TokenKind::RBrace, i, 1); i += 1; next
          when '['.ord
            tokens << Token.new(TokenKind::LBracket, i, 1); i += 1; next
          when ']'.ord
            tokens << Token.new(TokenKind::RBracket, i, 1); i += 1; next
          when ','.ord
            tokens << Token.new(TokenKind::Comma, i, 1); i += 1; next
          when '.'.ord
            tokens << Token.new(TokenKind::Dot, i, 1); i += 1; next
          when '+'.ord
            tokens << Token.new(TokenKind::Plus, i, 1); i += 1; next
          when '-'.ord
            tokens << Token.new(TokenKind::Minus, i, 1); i += 1; next
          when '*'.ord
            tokens << Token.new(TokenKind::Star, i, 1); i += 1; next
          when '/'.ord
            tokens << Token.new(TokenKind::Slash, i, 1); i += 1; next
          when '%'.ord
            tokens << Token.new(TokenKind::Percent, i, 1); i += 1; next
          when '='.ord
            tokens << Token.new(TokenKind::Equal, i, 1); i += 1; next
          when '!'.ord
            tokens << Token.new(TokenKind::Not, i, 1); i += 1; next
          when '<'.ord
            tokens << Token.new(TokenKind::LessThan, i, 1); i += 1; next
          when '>'.ord
            tokens << Token.new(TokenKind::GreaterThan, i, 1); i += 1; next
          when '&'.ord
            tokens << Token.new(TokenKind::Ampersand, i, 1); i += 1; next
          when '|'.ord
            tokens << Token.new(TokenKind::Pipe, i, 1); i += 1; next
          when '^'.ord
            tokens << Token.new(TokenKind::Caret, i, 1); i += 1; next
          when '~'.ord
            tokens << Token.new(TokenKind::Tilde, i, 1); i += 1; next
          when ';'.ord
            tokens << Token.new(TokenKind::Semicolon, i, 1); i += 1; next
          when '?'.ord
            tokens << Token.new(TokenKind::Question, i, 1); i += 1; next
          when '@'.ord
            tokens << Token.new(TokenKind::At, i, 1); i += 1; next
          end

          tokens << Token.new(TokenKind::Unknown, i, 1)
          i += 1
        end

        tokens << Token.new(TokenKind::Eof, len, 0)
        {tokens, Warp::Core::ErrorCode::Success}
      end

      private def self.is_identifier_start(c : UInt8) : Bool
        (c >= 'a'.ord && c <= 'z'.ord) || (c >= 'A'.ord && c <= 'Z'.ord) || c == '_'.ord
      end

      private def self.is_identifier_char(c : UInt8) : Bool
        is_identifier_start(c) || (c >= '0'.ord && c <= '9'.ord)
      end

      class Lexer
        def self.scan(bytes : Bytes) : Tuple(Array(Token), Warp::Core::ErrorCode)
          Warp::Lang::Crystal.scan(bytes)
        end
      end
    end
  end
end
