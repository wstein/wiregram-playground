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

      private struct SimdIndex
        @indices : Array(UInt32)
        @bytes : Bytes

        def initialize(@indices : Array(UInt32), @bytes : Bytes)
        end

        def next_index_of(start : Int32, a : UInt8, b : UInt8? = nil) : Int32
          i = lower_bound(start)
          while i < @indices.size
            idx = @indices[i].to_i
            byte = @bytes[idx]
            return idx if byte == a || (b && byte == b)
            i += 1
          end
          -1
        end

        private def lower_bound(target : Int32) : Int32
          left = 0
          right = @indices.size
          while left < right
            mid = (left + right) // 2
            if @indices[mid].to_i < target
              left = mid + 1
            else
              right = mid
            end
          end
          left
        end
      end

      class StatefulLexer
        @bytes : Bytes
        @state : Warp::Lexer::LexerState?

        def initialize(@bytes : Bytes, @state : Warp::Lexer::LexerState? = nil)
        end

        def scan_all : Tuple(Array(Token), Warp::Core::ErrorCode, Int32)
          Warp::Lang::Crystal.scan_bytes(@bytes, @state)
        end
      end

      def self.scan(bytes : Bytes, state : Warp::Lexer::LexerState? = nil) : Tuple(Array(Token), Warp::Core::ErrorCode, Int32)
        lexer = StatefulLexer.new(bytes, state)
        lexer.scan_all
      end

      def self.scan_bytes(bytes : Bytes, state : Warp::Lexer::LexerState? = nil) : Tuple(Array(Token), Warp::Core::ErrorCode, Int32)
        tokens = [] of Token
        i = 0
        len = bytes.size

        simd_result = Warp::Lang::Crystal.simd_scan(bytes)
        if simd_result.error != Warp::Core::ErrorCode::Success && simd_result.error != Warp::Core::ErrorCode::Empty
          return {tokens, simd_result.error, 0}
        end
        simd = SimdIndex.new(simd_result.indices, bytes)

        last_nonspace_kind : TokenKind? = nil

        while i < len
          c = bytes[i]

          # Newlines
          if c == '\n'.ord || c == '\r'.ord
            tokens << Token.new(TokenKind::Newline, i, 1)
            i += 1
            last_nonspace_kind = TokenKind::Newline
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
            state.try(&.push(Warp::Lexer::LexerState::State::Comment))
            j = scan_to_line_end(bytes, i + 1, simd)
            tokens << Token.new(TokenKind::CommentLine, i, j - i)
            i = j
            state.try(&.pop)
            next
          end

          # Macro delimiters {{ and }}
          if c == '{'.ord && i + 1 < len && bytes[i + 1] == '{'.ord
            state.try(&.push(Warp::Lexer::LexerState::State::Macro))
            backend = Warp::Backend.current
            indices = Warp::Lang::Common::StateAwareSimdHelpers.scan_macro_interior(
              bytes,
              (i + 2).to_u32,
              backend
            )
            closing = indices.reverse.find { |idx| bytes[idx] == '}'.ord }
            end_idx = if closing && closing.to_i + 1 < len && bytes[closing.to_i + 1] == '}'.ord
                        closing.to_i
                      else
                        scan_to_double(bytes, i + 2, '}'.ord.to_u8, '}'.ord.to_u8, simd)
                      end
            return {tokens, Warp::Core::ErrorCode::StringError, i} if end_idx < 0
            tokens << Token.new(TokenKind::MacroStart, i, 2)
            tokens << Token.new(TokenKind::MacroEnd, end_idx, 2)
            i = end_idx + 2
            last_nonspace_kind = TokenKind::MacroEnd
            state.try(&.pop)
            next
          end
          if c == '}'.ord && i + 1 < len && bytes[i + 1] == '}'.ord
            tokens << Token.new(TokenKind::MacroEnd, i, 2)
            i += 2
            last_nonspace_kind = TokenKind::MacroEnd
            next
          end
          if c == '{'.ord && i + 1 < len && bytes[i + 1] == '%'.ord
            state.try(&.push(Warp::Lexer::LexerState::State::Macro))
            backend = Warp::Backend.current
            indices = Warp::Lang::Common::StateAwareSimdHelpers.scan_macro_interior(
              bytes,
              (i + 2).to_u32,
              backend
            )
            closing = indices.reverse.find { |idx| bytes[idx] == '}'.ord }
            end_idx = if closing && closing.to_i > 0 && bytes[closing.to_i - 1] == '%'.ord
                        closing.to_i
                      else
                        scan_to_double(bytes, i + 2, '%'.ord.to_u8, '}'.ord.to_u8, simd)
                      end
            return {tokens, Warp::Core::ErrorCode::StringError, i} if end_idx < 0
            tokens << Token.new(TokenKind::MacroStart, i, 2)
            tokens << Token.new(TokenKind::MacroEnd, end_idx, 2)
            i = end_idx + 2
            last_nonspace_kind = TokenKind::MacroEnd
            state.try(&.pop)
            next
          end

          # Strings (double-quoted)
          if c == '"'.ord
            state.try(&.push(Warp::Lexer::LexerState::State::String))
            j = scan_string_with_helpers(bytes, i, '"'.ord.to_u8)
            return {tokens, Warp::Core::ErrorCode::StringError, i} if j < 0
            tokens << Token.new(TokenKind::String, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::String
            state.try(&.pop)
            next
          end

          # Strings/char (single-quoted) - treated as String for now
          if c == '\''.ord
            state.try(&.push(Warp::Lexer::LexerState::State::String))
            j = scan_string_with_helpers(bytes, i, '\''.ord.to_u8)
            return {tokens, Warp::Core::ErrorCode::StringError, i} if j < 0
            tokens << Token.new(TokenKind::String, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::String
            state.try(&.pop)
            next
          end

          # Regex literals (/.../)
          if c == '/'.ord && should_be_regex(last_nonspace_kind)
            state.try(&.push(Warp::Lexer::LexerState::State::Regex))
            j = scan_regex_with_helpers(bytes, i)
            return {tokens, Warp::Core::ErrorCode::StringError, i} if j < 0
            tokens << Token.new(TokenKind::Regex, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::Regex
            state.try(&.pop)
            next
          end

          # Percent strings: %w(...), %i(...), %r(...), etc.
          if c == '%'.ord && i + 1 < len && is_percent_literal_type(bytes[i + 1])
            # Crystal percent literal types: w, i, q, Q, r, s, x, W, I, R, S, X
            lit_type = bytes[i + 1]
            d = i + 2
            if d < len
              delim = bytes[d]
              # support paired delimiters: () {} [] <>
              close = case delim
                      when '('.ord then ')'.ord.to_u8
                      when '{'.ord then '}'.ord.to_u8
                      when '['.ord then ']'.ord.to_u8
                      when '<'.ord then '>'.ord.to_u8
                      else              delim
                      end
              # use SIMD-driven delimiter scanning for efficiency
              k = scan_percent_delimited(bytes, d + 1, close, lit_type)
              if k > 0
                state.try(&.push(Warp::Lexer::LexerState::State::String))
                tokens << Token.new(TokenKind::String, i, k - i)
                i = k
                last_nonspace_kind = TokenKind::String
                state.try(&.pop)
                next
              end
            end
          end

          # Percent strings with direct delimiters: %(...), %[...], %{...}, etc.
          if c == '%'.ord && i + 1 < len && !is_percent_literal_type(bytes[i + 1])
            next_char = bytes[i + 1]
            # Check for string delimiters
            delimiter_open = nil
            delimiter_close = nil
            case next_char
            when '('.ord
              delimiter_open = '('.ord
              delimiter_close = ')'.ord
            when '['.ord
              delimiter_open = '['.ord
              delimiter_close = ']'.ord
            when '{'.ord
              delimiter_open = '{'.ord
              delimiter_close = '}'.ord
            when '<'.ord
              delimiter_open = '<'.ord
              delimiter_close = '>'.ord
            when '|'.ord
              delimiter_open = '|'.ord
              delimiter_close = '|'.ord
            when ' '.ord, '\t'.ord
              delimiter_open = next_char
              delimiter_close = next_char
            else
              # If next char is not a delimiter, skip this as a % operator
              # This will be handled as Percent token later
              delimiter_open = nil
            end

            if delimiter_open
              state.try(&.push(Warp::Lexer::LexerState::State::String))
              close = delimiter_close.not_nil!.to_u8
              if close == '"'.ord.to_u8 || close == '\''.ord.to_u8
                j = scan_string_with_helpers(bytes, i + 1, close)
              else
                j = scan_delimited(bytes, i + 1, close, simd)
              end
              return {tokens, Warp::Core::ErrorCode::StringError, i} if j < 0
              tokens << Token.new(TokenKind::String, i, j - i)
              i = j
              last_nonspace_kind = TokenKind::String
              state.try(&.pop)
              next
            end
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
              last_nonspace_kind = TokenKind::Float
              next
            end
            tokens << Token.new(TokenKind::Number, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::Number
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

          # Variables and identifiers with prefixes
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
            elsif i + 1 < len && bytes[i + 1] == '['.ord
              state.try(&.push(Warp::Lexer::LexerState::State::Annotation))
              backend = Warp::Backend.current
              indices = Warp::Lang::Common::StateAwareSimdHelpers.scan_annotation_interior(
                bytes,
                (i + 1).to_u32,
                backend
              )
              closing = indices.find { |idx| bytes[idx] == ']'.ord }
              end_idx = closing ? closing.to_i : scan_to_op_byte(bytes, i + 2, ']'.ord.to_u8, simd)
              return {tokens, Warp::Core::ErrorCode::StringError, i} if end_idx < 0
              tokens << Token.new(TokenKind::Annotation, i, end_idx - i + 1)
              i = end_idx + 1
              last_nonspace_kind = TokenKind::Annotation
              state.try(&.pop)
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

          # Symbols (:symbol) and ::
          if c == ':'.ord
            if i + 1 < len && bytes[i + 1] == ':'.ord
              tokens << Token.new(TokenKind::DoubleColon, i, 2)
              i += 2
              last_nonspace_kind = TokenKind::DoubleColon
              next
            elsif i + 1 < len && is_identifier_start(bytes[i + 1])
              j = i + 1
              while j < len && is_identifier_char(bytes[j])
                j += 1
              end
              tokens << Token.new(TokenKind::Symbol, i, j - i)
              i = j
              last_nonspace_kind = TokenKind::Symbol
              next
            else
              tokens << Token.new(TokenKind::Colon, i, 1)
              i += 1
              last_nonspace_kind = TokenKind::Colon
              next
            end
          end

          next_c = i + 1 < len ? bytes[i + 1] : 0u8

          # Two-char operators
          if c == '='.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::EqualEqual, i, 2); i += 2; last_nonspace_kind = TokenKind::EqualEqual; next
          elsif c == '!'.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::NotEqual, i, 2); i += 2; last_nonspace_kind = TokenKind::NotEqual; next
          elsif c == '<'.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::LessEqual, i, 2); i += 2; last_nonspace_kind = TokenKind::LessEqual; next
          elsif c == '>'.ord && next_c == '='.ord
            tokens << Token.new(TokenKind::GreaterEqual, i, 2); i += 2; last_nonspace_kind = TokenKind::GreaterEqual; next
          elsif c == '&'.ord && next_c == '&'.ord
            tokens << Token.new(TokenKind::LogicalAnd, i, 2); i += 2; last_nonspace_kind = TokenKind::LogicalAnd; next
          elsif c == '|'.ord && next_c == '|'.ord
            tokens << Token.new(TokenKind::LogicalOr, i, 2); i += 2; last_nonspace_kind = TokenKind::LogicalOr; next
          elsif c == '*'.ord && next_c == '*'.ord
            tokens << Token.new(TokenKind::Power, i, 2); i += 2; last_nonspace_kind = TokenKind::Power; next
          elsif c == '<'.ord && next_c == '<'.ord
            tokens << Token.new(TokenKind::LeftShift, i, 2); i += 2; last_nonspace_kind = TokenKind::LeftShift; next
          elsif c == '>'.ord && next_c == '>'.ord
            tokens << Token.new(TokenKind::RightShift, i, 2); i += 2; last_nonspace_kind = TokenKind::RightShift; next
          elsif c == '-'.ord && next_c == '>'.ord
            tokens << Token.new(TokenKind::Arrow, i, 2); i += 2; last_nonspace_kind = TokenKind::Arrow; next
          elsif c == '='.ord && next_c == '>'.ord
            tokens << Token.new(TokenKind::FatArrow, i, 2); i += 2; last_nonspace_kind = TokenKind::FatArrow; next
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
            tokens << Token.new(TokenKind::Percent, i, 1); i += 1; last_nonspace_kind = TokenKind::Percent; next
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
          when '^'.ord
            tokens << Token.new(TokenKind::Caret, i, 1); i += 1; last_nonspace_kind = TokenKind::Caret; next
          when '~'.ord
            tokens << Token.new(TokenKind::Tilde, i, 1); i += 1; last_nonspace_kind = TokenKind::Tilde; next
          when ';'.ord
            tokens << Token.new(TokenKind::Semicolon, i, 1); i += 1; last_nonspace_kind = TokenKind::Semicolon; next
          when '?'.ord
            tokens << Token.new(TokenKind::Question, i, 1); i += 1; last_nonspace_kind = TokenKind::Question; next
          when '@'.ord
            tokens << Token.new(TokenKind::At, i, 1); i += 1; last_nonspace_kind = TokenKind::At; next
          end

          tokens << Token.new(TokenKind::Unknown, i, 1)
          i += 1
        end

        tokens << Token.new(TokenKind::Eof, len, 0)
        {attach_trivia(tokens), Warp::Core::ErrorCode::Success, 0}
      end

      private def self.attach_trivia(tokens : Array(Token)) : Array(Token)
        result = [] of Token
        pending = [] of Trivia

        tokens.each do |tok|
          case tok.kind
          when TokenKind::Whitespace
            pending << Trivia.new(TriviaKind::Whitespace, tok.start, tok.length)
          when TokenKind::CommentLine
            pending << Trivia.new(TriviaKind::CommentLine, tok.start, tok.length)
          when TokenKind::Newline, TokenKind::Eof
            if !pending.empty?
              tok.trivia = pending.dup
              pending.clear
            end
            result << tok
          else
            if !pending.empty?
              tok.trivia = pending.dup
              pending.clear
            end
            result << tok
          end
        end

        if !pending.empty? && result.size > 0
          result.last.trivia.concat(pending)
          pending.clear
        end

        result
      end

      private def self.is_identifier_start(c : UInt8) : Bool
        (c >= 'a'.ord && c <= 'z'.ord) || (c >= 'A'.ord && c <= 'Z'.ord) || c == '_'.ord
      end

      private def self.is_identifier_char(c : UInt8) : Bool
        is_identifier_start(c) || (c >= '0'.ord && c <= '9'.ord)
      end

      private def self.scan_to_line_end(bytes : Bytes, start : Int32, simd : SimdIndex) : Int32
        len = bytes.size
        return len if start >= len
        idx = simd.next_index_of(start, '\n'.ord.to_u8, '\r'.ord.to_u8)
        return idx if idx >= 0
        backend = Warp::Backend.current
        Warp::Lang::Common::SimdLexingUtils.scan_to_line_end(bytes, start, backend)
      end

      private def self.scan_delimited(bytes : Bytes, start : Int32, delimiter : UInt8, simd : SimdIndex? = nil) : Int32
        len = bytes.size
        i = start + 1
        return -1 if i >= len
        backend = Warp::Backend.current
        Warp::Lang::Common::SimdLexingUtils.scan_delimited(bytes, start, delimiter, false, backend) do |_b|
          false
        end
      end

      private def self.scan_string_with_helpers(bytes : Bytes, start : Int32, quote_char : UInt8) : Int32
        backend = Warp::Backend.current
        indices = Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
          bytes,
          (start + 1).to_u32,
          quote_char,
          backend
        )
        end_idx = indices.reverse.find { |idx| bytes[idx] == quote_char }
        return -1 unless end_idx
        end_idx.to_i + 1
      end

      private def self.scan_regex_with_helpers(bytes : Bytes, start : Int32) : Int32
        backend = Warp::Backend.current
        indices = Warp::Lang::Common::StateAwareSimdHelpers.scan_regex_interior(
          bytes,
          (start + 1).to_u32,
          backend
        )
        end_idx = indices.reverse.find { |idx| bytes[idx] == '/'.ord }
        return -1 unless end_idx
        i = end_idx.to_i + 1
        while i < bytes.size && regex_modifier?(bytes[i])
          i += 1
        end
        i
      end

      private def self.scan_to_double(bytes : Bytes, start : Int32, a : UInt8, b : UInt8, simd : SimdIndex? = nil) : Int32
        len = bytes.size
        i = start
        ptr = bytes.to_unsafe
        backend = Warp::Backend.current

        while i + 1 < len
          if simd
            idx = simd.not_nil!.next_index_of(i, a)
            if idx >= 0
              return idx if idx + 1 < len && ptr[idx + 1] == b
              i = idx + 1
            end
          end
          block_len = len - i
          block_len = 64 if block_len > 64
          masks = backend.build_masks(ptr + i, block_len)
          candidates = masks.op

          while candidates != 0
            tz = candidates.trailing_zeros_count
            idx = i + tz
            if ptr[idx] == a && idx + 1 < len && ptr[idx + 1] == b
              return idx
            end
            candidates &= candidates - 1_u64
          end

          if !op_target?(a)
            j = 0
            while j + i + 1 < len && j < block_len
              if ptr[i + j] == a && i + j + 1 < len && ptr[i + j + 1] == b
                return i + j
              end
              j += 1
            end
          end

          i += 64
        end

        -1
      end

      private def self.scan_to_op_byte(bytes : Bytes, start : Int32, target : UInt8, simd : SimdIndex? = nil) : Int32
        len = bytes.size
        i = start
        ptr = bytes.to_unsafe
        backend = Warp::Backend.current

        while i < len
          if simd
            idx = simd.not_nil!.next_index_of(i, target)
            return idx if idx >= 0
          end
          block_len = len - i
          block_len = 64 if block_len > 64
          masks = backend.build_masks(ptr + i, block_len)
          candidates = masks.op

          while candidates != 0
            tz = candidates.trailing_zeros_count
            idx = i + tz
            return idx if ptr[idx] == target
            candidates &= candidates - 1_u64
          end

          i += 64
        end

        -1
      end

      private def self.is_percent_literal_type(c : UInt8) : Bool
        # %w, %i, %r, %q, %s, %x, %W, %I, %Q, %R, %S, %X
        (c >= 'a'.ord && c <= 'z'.ord) || (c >= 'A'.ord && c <= 'Z'.ord)
      end

      private def self.regex_modifier?(b : UInt8) : Bool
        b == 'i'.ord.to_u8 || b == 'm'.ord.to_u8 || b == 'x'.ord.to_u8
      end

      private def self.should_be_regex(last_kind : TokenKind?) : Bool
        return true if last_kind == nil
        case last_kind
        when TokenKind::LParen, TokenKind::LBracket, TokenKind::LBrace, TokenKind::Comma, TokenKind::Semicolon,
             TokenKind::Newline, TokenKind::Return, TokenKind::Do, TokenKind::If, TokenKind::Unless, TokenKind::While,
             TokenKind::Equal, TokenKind::LessEqual, TokenKind::GreaterEqual, TokenKind::LogicalAnd, TokenKind::LogicalOr,
             TokenKind::Arrow, TokenKind::FatArrow
          true
        else
          false
        end
      end

      private def self.scan_percent_delimited(bytes : Bytes, start : Int32, close : UInt8, lit_type : UInt8) : Int32
        len = bytes.size
        i = start
        return -1 if i >= len

        backend = Warp::Backend.current
        escape_scanner = Warp::Lexer::EscapeScanner.new
        ptr = bytes.to_unsafe

        # for %r (regex), we need to handle modifiers after the closing delimiter
        is_regex = lit_type == 'r'.ord.to_u8 || lit_type == 'R'.ord.to_u8

        if is_regex && close == '/'.ord.to_u8
          indices = Warp::Lang::Common::StateAwareSimdHelpers.scan_regex_interior(
            bytes,
            start.to_u32,
            backend
          )
          end_idx = indices.reverse.find { |idx| bytes[idx] == '/'.ord }
          if end_idx
            end_i = end_idx.to_i + 1
            while end_i < len && regex_modifier?(bytes[end_i])
              end_i += 1
            end
            return end_i
          end
        elsif close == '"'.ord.to_u8 || close == '\''.ord.to_u8
          indices = Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
            bytes,
            start.to_u32,
            close,
            backend
          )
          end_idx = indices.reverse.find { |idx| bytes[idx] == close }
          return end_idx.to_i + 1 if end_idx
        end

        while i < len
          block_len = len - i
          block_len = 64 if block_len > 64

          masks = backend.build_masks(ptr + i, block_len)
          backslash = masks.backslash
          delim_mask = Warp::Lang::Common::SimdLexingUtils.build_byte_mask(ptr + i, block_len, close)
          escaped = escape_scanner.next(backslash).escaped
          unescaped = delim_mask & ~escaped

          if unescaped != 0
            end_idx = i + unescaped.trailing_zeros_count + 1
            # for %r, consume trailing modifiers (i, m, x, o)
            if is_regex
              while end_idx < len && ((bytes[end_idx] == 'i'.ord.to_u8 || bytes[end_idx] == 'm'.ord.to_u8 ||
                    bytes[end_idx] == 'x'.ord.to_u8 || bytes[end_idx] == 'o'.ord.to_u8))
                end_idx += 1
              end
            end
            return end_idx
          end

          i += 64
        end

        -1
      end

      private def self.op_target?(b : UInt8) : Bool
        b == '{'.ord.to_u8 || b == '}'.ord.to_u8 || b == '['.ord.to_u8 || b == ']'.ord.to_u8 || b == ':'.ord.to_u8 || b == ','.ord.to_u8 || b == '\n'.ord.to_u8 || b == '\r'.ord.to_u8
      end

      # SIMD-driven pattern detection for Crystal-specific structures
      # These methods detect macros, annotations, and type boundaries using whitespace masks

      # Detect macro delimiters {{ }}, {%% %} using SIMD boundary scanning
      # Returns indices where macro regions start
      def self.detect_macro_boundaries(bytes : Bytes) : Array(UInt32)
        indices = Array(UInt32).new
        len = bytes.size
        i = 0

        while i < len - 1
          # Look for {{ or {%%
          if bytes[i] == '{'.ord
            if i + 1 < len && bytes[i + 1] == '{'.ord
              indices << i.to_u32
              # Skip to matching }}
              i = scan_to_double(bytes, i + 2, '}'.ord.to_u8, '}'.ord.to_u8)
              i = i < 0 ? len : i + 2
              next
            elsif i + 1 < len && bytes[i + 1] == '%'.ord
              indices << i.to_u32
              # Skip to matching %}
              i = scan_to_double(bytes, i + 2, '%'.ord.to_u8, '}'.ord.to_u8)
              i = i < 0 ? len : i + 2
              next
            end
          end

          i += 1
        end

        indices
      end

      # Detect annotation markers @[...] using bracket scanning
      # Returns indices where annotations occur
      def self.detect_annotations(bytes : Bytes) : Array(UInt32)
        indices = Array(UInt32).new
        len = bytes.size
        i = 0

        while i < len - 1
          if bytes[i] == '@'.ord && i + 1 < len && bytes[i + 1] == '['.ord
            indices << i.to_u32
            # Skip to matching ]
            j = i + 2
            while j < len && bytes[j] != ']'.ord
              j += 1
            end
            i = j + 1
          else
            i += 1
          end
        end

        indices
      end

      # Detect type annotation markers (: Type) using colon+whitespace pattern
      # Returns indices of colons marking type boundaries
      def self.detect_type_boundaries(bytes : Bytes) : Array(UInt32)
        indices = Array(UInt32).new
        len = bytes.size
        backend = Warp::Backend.current
        ptr = bytes.to_unsafe
        i = 0

        # Use whitespace mask to find type annotation positions
        # Pattern: identifier : Type (whitespace often surrounds :)
        while i < len
          if bytes[i] == ':'.ord && i + 1 < len
            # Check if preceded by identifier and followed by type
            is_type_colon = false

            if i > 0 && (is_identifier_char(bytes[i - 1]) || bytes[i - 1] == ' '.ord)
              if i + 1 < len && (is_identifier_start(bytes[i + 1]) || bytes[i + 1] == ' '.ord)
                is_type_colon = true
              end
            end

            if is_type_colon
              indices << i.to_u32
            end
          end

          i += 1
        end

        indices
      end

      # Detect all Crystal-specific patterns with metadata
      def self.detect_all_patterns(bytes : Bytes) : Hash(String, Array(UInt32))
        {
          "macro_boundaries" => detect_macro_boundaries(bytes),
          "annotations"      => detect_annotations(bytes),
          "type_boundaries"  => detect_type_boundaries(bytes),
        }
      end

      private def self.is_identifier_start(c : UInt8) : Bool
        (c >= 'a'.ord && c <= 'z'.ord) || (c >= 'A'.ord && c <= 'Z'.ord) || c == '_'.ord
      end

      private def self.is_identifier_char(c : UInt8) : Bool
        is_identifier_start(c) || (c >= '0'.ord && c <= '9'.ord)
      end

      class Lexer
        def self.scan(bytes : Bytes, state : Warp::Lexer::LexerState? = nil) : Tuple(Array(Token), Warp::Core::ErrorCode, Int32)
          Warp::Lang::Crystal.scan(bytes, state)
        end
      end
    end
  end
end
