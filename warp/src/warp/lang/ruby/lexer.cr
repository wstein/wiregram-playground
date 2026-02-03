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
        property trivia : Array(Trivia)

        def initialize(
          @kind : TokenKind,
          @start : Int32,
          @length : Int32,
          @trivia : Array(Trivia) = [] of Trivia,
        )
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

      def self.scan(bytes : Bytes, state : Warp::Lexer::LexerState? = nil) : Tuple(Array(Token), Warp::Core::ErrorCode, Int32)
        # Module-level compatibility: this method is used internally by tests and other code.
        tokens = [] of Token
        i = 0
        len = bytes.size

        simd_result = Warp::Lang::Ruby.simd_scan(bytes)
        if simd_result.error != ErrorCode::Success && simd_result.error != ErrorCode::Empty
          return {tokens, simd_result.error, 0}
        end
        simd = SimdIndex.new(simd_result.indices, bytes)

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
            state.try(&.push(Warp::Lexer::LexerState::State::Comment))
            j = scan_to_line_end(bytes, i + 1, simd)
            tokens << Token.new(TokenKind::CommentLine, i, j - i)
            i = j
            state.try(&.pop)
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
              # move to next line start using SIMD
              j = scan_to_line_end(bytes, j, simd)
              if j < len
                j += 1
              end
              # search for delimiter at line start
              k = j
              found = -1
              while k < len
                line_start = k
                # skip leading whitespace using built-in scan
                while k < len && (bytes[k] == ' '.ord || bytes[k] == '\t'.ord)
                  k += 1
                end
                # match delimiter
                if match_literal(bytes, k, delim)
                  k += delim.bytesize
                  # ensure end of line
                  if k >= len || bytes[k] == '\n'.ord || bytes[k] == '\r'.ord
                    found = k
                    # consume rest of line using SIMD
                    k = scan_to_line_end(bytes, k, simd)
                    if k < len
                      k += 1
                    end
                    break
                  end
                end
                # advance to next line using SIMD
                k = scan_to_line_end(bytes, k, simd)
                if k < len
                  k += 1
                end
              end
              end_idx = (found >= 0) ? found : k
              state.try(&.push(Warp::Lexer::LexerState::State::Heredoc))
              tokens << Token.new(TokenKind::Heredoc, i, end_idx - i)
              state.try(&.pop)
              i = end_idx
              last_nonspace_kind = TokenKind::Heredoc
              next
            end
          end

          # strings
          if c == '"'.ord
            state.try(&.push(Warp::Lexer::LexerState::State::String))
            j = scan_delimited(bytes, i, '"'.ord.to_u8, false, simd)
            return {tokens, ErrorCode::StringError, start_i} if j < 0
            tokens << Token.new(TokenKind::String, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::String
            state.try(&.pop)
            next
          end

          if c == '\''.ord
            state.try(&.push(Warp::Lexer::LexerState::State::String))
            j = scan_delimited(bytes, i, '\''.ord.to_u8, false, simd)
            return {tokens, ErrorCode::StringError, start_i} if j < 0
            tokens << Token.new(TokenKind::String, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::String
            state.try(&.pop)
            next
          end

          # regex simple form when in expression position
          if c == '/'.ord && should_be_regex(last_nonspace_kind)
            state.try(&.push(Warp::Lexer::LexerState::State::Regex))
            j = scan_delimited(bytes, i, '/'.ord.to_u8, true, simd)
            return {tokens, ErrorCode::StringError, start_i} if j < 0
            tokens << Token.new(TokenKind::Regex, i, j - i)
            i = j
            last_nonspace_kind = TokenKind::Regex
            state.try(&.pop)
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
            # percent operator or percent literal (%w, %i, %r, %q, %s, %x)
            if i + 1 < len && is_percent_literal_type(bytes[i + 1])
              lit_type = bytes[i + 1]
              d = i + 2
              if d < len
                delim = bytes[d]
                # support paired delimiters: () {} []
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
        {attach_trivia(tokens), ErrorCode::Success, 0}
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
          when TokenKind::CommentBlock
            pending << Trivia.new(TriviaKind::CommentBlock, tok.start, tok.length)
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

      private def self.scan_to_line_end(bytes : Bytes, start : Int32, simd : SimdIndex) : Int32
        len = bytes.size
        return len if start >= len
        idx = simd.next_index_of(start, '\n'.ord.to_u8, '\r'.ord.to_u8)
        return idx if idx >= 0
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

      private def self.scan_delimited(bytes : Bytes, start : Int32, delimiter : UInt8, allow_modifiers : Bool = false, simd : SimdIndex? = nil) : Int32
        len = bytes.size
        i = start + 1
        return -1 if i >= len

        if simd
          simd.not_nil!.next_index_of(i, delimiter)
        end

        backend = Warp::Backend.current
        escape_scanner = Warp::Lexer::EscapeScanner.new
        ptr = bytes.to_unsafe

        while i < len
          block_len = len - i
          block_len = 64 if block_len > 64

          masks = backend.build_masks(ptr + i, block_len)
          backslash = masks.backslash
          delim_mask = build_byte_mask(ptr + i, block_len, delimiter)
          escaped = escape_scanner.next(backslash).escaped
          unescaped = delim_mask & ~escaped

          if unescaped != 0
            end_idx = i + unescaped.trailing_zeros_count + 1
            if allow_modifiers
              while end_idx < len && regex_modifier?(bytes[end_idx])
                end_idx += 1
              end
            end
            return end_idx
          end

          i += 64
        end

        -1
      end

      private def self.build_byte_mask(ptr : Pointer(UInt8), block_len : Int32, target : UInt8) : UInt64
        mask = 0_u64
        i = 0
        while i < block_len
          mask |= (1_u64 << i) if ptr[i] == target
          i += 1
        end
        mask
      end

      private def self.regex_modifier?(b : UInt8) : Bool
        b == 'i'.ord.to_u8 || b == 'm'.ord.to_u8 || b == 'x'.ord.to_u8 || b == 'o'.ord.to_u8
      end

      private def self.is_percent_literal_type(c : UInt8) : Bool
        # %w, %i, %r, %q, %s, %x, %W, %I, %Q, %R, %S, %X
        (c >= 'a'.ord && c <= 'z'.ord) || (c >= 'A'.ord && c <= 'Z'.ord)
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

        while i < len
          block_len = len - i
          block_len = 64 if block_len > 64

          masks = backend.build_masks(ptr + i, block_len)
          backslash = masks.backslash
          delim_mask = build_byte_mask(ptr + i, block_len, close)
          escaped = escape_scanner.next(backslash).escaped
          unescaped = delim_mask & ~escaped

          if unescaped != 0
            end_idx = i + unescaped.trailing_zeros_count + 1
            # for %r, consume trailing modifiers
            if is_regex
              while end_idx < len && regex_modifier?(bytes[end_idx])
                end_idx += 1
              end
            end
            return end_idx
          end

          i += 64
        end

        -1
      end

      # SIMD-driven pattern detection for Ruby-specific structures
      # These methods detect heredocs, regex literals, and string interpolation using whitespace masks
      #
      # Returns array of indices where these patterns occur
      def self.detect_heredoc_boundaries(bytes : Bytes) : Array(UInt32)
        indices = Array(UInt32).new
        len = bytes.size
        i = 0
        while i < len - 1
          # Look for << followed by identifier (heredoc start marker)
          if bytes[i] == '<'.ord && bytes[i + 1] == '<'.ord
            # Check if this is actually a heredoc (not left-shift or <<)
            # by verifying an identifier follows
            j = i + 2
            # Skip optional - or ~ modifiers
            if j < len && (bytes[j] == '-'.ord || bytes[j] == '~'.ord)
              j += 1
            end
            # Check for heredoc delimiter
            if j < len && is_identifier_start(bytes[j])
              indices << i.to_u32
            end
            i += 2
          else
            i += 1
          end
        end
        indices
      end

      # Detect regex literal delimiters using whitespace context
      # Returns indices of regex start positions
      def self.detect_regex_delimiters(bytes : Bytes) : Array(UInt32)
        indices = Array(UInt32).new
        len = bytes.size
        i = 0
        last_token_kind : TokenKind? = nil

        while i < len
          c = bytes[i]

          # Skip whitespace
          if c == ' '.ord || c == '\t'.ord || c == '\n'.ord || c == '\r'.ord
            i += 1
            next
          end

          # Check for regex delimiter (/)
          if c == '/'.ord && should_be_regex(last_token_kind)
            indices << i.to_u32
            # Skip to end of regex
            i = scan_delimited(bytes, i, '/'.ord.to_u8, true)
            i = i < 0 ? len : i
            last_token_kind = TokenKind::Regex
            next
          end

          # Track token kind for context
          case c
          when '='.ord, '('.ord, '['.ord, '{'.ord, ','.ord, ';'.ord, '~'.ord
            last_token_kind = TokenKind::LParen
          when 'i'.ord..'z'.ord, 'A'.ord..'Z'.ord
            last_token_kind = TokenKind::Identifier
          else
            last_token_kind = TokenKind::Unknown
          end

          i += 1
        end

        indices
      end

      # Detect string interpolation markers (#{}) using whitespace scanning
      # Returns indices where #{} appears
      def self.detect_string_interpolation(bytes : Bytes) : Array(UInt32)
        indices = Array(UInt32).new
        len = bytes.size
        i = 0

        # Only scan inside strings — look for starting quotes first
        while i < len
          if bytes[i] == '"'.ord
            # Scan double-quoted string for #{...}
            i += 1
            while i < len - 1
              if bytes[i] == '#'.ord && bytes[i + 1] == '{'.ord
                indices << (i - 1).to_u32 # Mark position of opening quote + content
                # Skip to closing }
                depth = 1
                i += 2
                while i < len && depth > 0
                  if bytes[i] == '{'.ord
                    depth += 1
                  elsif bytes[i] == '}'.ord
                    depth -= 1
                  elsif bytes[i] == '"'.ord
                    break
                  end
                  i += 1
                end
              elsif bytes[i] == '"'.ord
                break
              else
                i += 1
              end
            end
            i += 1
          else
            i += 1
          end
        end

        indices
      end

      # Combined SIMD pattern detection: returns all Ruby-specific structural positions
      # with metadata about pattern type
      def self.detect_all_patterns(bytes : Bytes) : Hash(String, Array(UInt32))
        {
          "heredoc_markers"      => detect_heredoc_boundaries(bytes),
          "regex_delimiters"     => detect_regex_delimiters(bytes),
          "string_interpolation" => detect_string_interpolation(bytes),
        }
      end

      # Expose a `Lexer` class for compatibility with existing callers/tests.
      class Lexer
        def self.scan(bytes : Bytes, state : Warp::Lexer::LexerState? = nil) : Tuple(Array(Token), Warp::Core::ErrorCode, Int32)
          Warp::Lang::Ruby.scan(bytes, state)
        end
      end
    end
  end
end
