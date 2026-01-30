module Warp
  module Lexer
    class TokenScanner
      alias ErrorCode = Core::ErrorCode
      alias Token = CST::Token
      alias TokenKind = CST::TokenKind

      def self.scan(bytes : Bytes, jsonc : Bool = false) : Tuple(Array(Token), ErrorCode)
        tokens = [] of Token
        i = 0
        len = bytes.size
        backend = Backend.current

        while i < len
          last_i = i
          c = bytes[i]
          case c
          when ' '.ord, '\t'.ord
            start = i
            i = scan_space_tab_end(bytes, i, backend)
            tokens << Token.new(TokenKind::Whitespace, start, i - start)
          when '\n'.ord
            tokens << Token.new(TokenKind::Newline, i, 1)
            i += 1
          when '\r'.ord
            start = i
            i += 1
            if i < len && bytes[i] == '\n'.ord
              i += 1
              tokens << Token.new(TokenKind::Newline, start, 2)
            else
              tokens << Token.new(TokenKind::Newline, start, 1)
            end
          when '/'.ord
            if jsonc && i + 1 < len
              if bytes[i + 1] == '/'.ord
                start = i
                i = scan_line_comment_end(bytes, i + 2, backend)
                tokens << Token.new(TokenKind::CommentLine, start, i - start)
              elsif bytes[i + 1] == '*'.ord
                start = i
                end_idx = scan_block_comment_end(bytes, i + 2)
                return {tokens, ErrorCode::StringError} if end_idx < 0
                i = end_idx
                tokens << Token.new(TokenKind::CommentBlock, start, i - start)
              else
                tokens << Token.new(TokenKind::Unknown, i, 1)
                i += 1
              end
            else
              tokens << Token.new(TokenKind::Unknown, i, 1)
            end
          when '{'.ord
            tokens << Token.new(TokenKind::LBrace, i, 1)
            i += 1
          when '}'.ord
            tokens << Token.new(TokenKind::RBrace, i, 1)
            i += 1
          when '['.ord
            tokens << Token.new(TokenKind::LBracket, i, 1)
            i += 1
          when ']'.ord
            tokens << Token.new(TokenKind::RBracket, i, 1)
            i += 1
          when ':'.ord
            tokens << Token.new(TokenKind::Colon, i, 1)
            i += 1
          when ','.ord
            tokens << Token.new(TokenKind::Comma, i, 1)
            i += 1
          when '"'.ord
            start = i + 1
            end_idx = scan_string_end(bytes, start)
            return {tokens, ErrorCode::UnclosedString} if end_idx < 0
            tokens << Token.new(TokenKind::String, start, end_idx - start)
            i = end_idx + 1
          else
            if c == '-'.ord || (c >= '0'.ord && c <= '9'.ord)
              end_idx = scan_number_end(bytes, i)
              return {tokens, ErrorCode::NumberError} unless IR.valid_number?(bytes, i, end_idx - i)
              tokens << Token.new(TokenKind::Number, i, end_idx - i)
              i = end_idx
            elsif match_literal(bytes, i, "true")
              tokens << Token.new(TokenKind::True, i, 4)
              i += 4
            elsif match_literal(bytes, i, "false")
              tokens << Token.new(TokenKind::False, i, 5)
              i += 5
            elsif match_literal(bytes, i, "null")
              tokens << Token.new(TokenKind::Null, i, 4)
              i += 4
            else
              tokens << Token.new(TokenKind::Unknown, i, 1)
              i += 1
            end
          end
          if i == last_i
            tokens << Token.new(TokenKind::Unknown, i, 1)
            i += 1
          end
        end

        tokens << Token.new(TokenKind::Eof, len, 0)
        {tokens, ErrorCode::Success}
      end

      private def self.match_literal(bytes : Bytes, start : Int32, literal : String) : Bool
        return false if start + literal.bytesize > bytes.size
        literal.bytes.each_with_index do |byte, offset|
          return false unless bytes[start + offset] == byte
        end
        true
      end

      private def self.scan_string_end(bytes : Bytes, start : Int32) : Int32
        i = start
        escaped = false
        while i < bytes.size
          c = bytes[i]
          if escaped
            escaped = false
          elsif c == '\\'.ord
            escaped = true
          elsif c == '"'.ord
            return i
          end
          i += 1
        end
        -1
      end

      private def self.scan_space_tab_end(bytes : Bytes, start : Int32, backend : Backend::Base) : Int32
        len = bytes.size
        i = start
        ptr = bytes.to_unsafe

        while i + 16 <= len
          masks = backend.build_masks(ptr + i, 16)
          expected = 0xFFFF_u64
          break unless (masks.whitespace & expected) == expected
          i += 16
        end

        while i < len && (bytes[i] == ' '.ord || bytes[i] == '\t'.ord)
          i += 1
        end
        i
      end

      private def self.scan_line_comment_end(bytes : Bytes, start : Int32, backend : Backend::Base) : Int32
        len = bytes.size
        i = start
        ptr = bytes.to_unsafe

        while i < len
          block_len = len - i
          block_len = 64 if block_len > 64
          break if block_len < 64
          mask = backend.newline_mask(ptr + i, block_len)
          if mask == 0
            i += block_len
          else
            return i + mask.trailing_zeros_count
          end
        end

        while i < len
          c = bytes[i]
          return i if c == '\n'.ord || c == '\r'.ord
          i += 1
        end
        i
      end

      private def self.scan_block_comment_end(bytes : Bytes, start : Int32) : Int32
        i = start
        len = bytes.size
        while i + 1 < len
          if bytes[i] == '*'.ord && bytes[i + 1] == '/'.ord
            return i + 2
          end
          i += 1
        end
        -1
      end

      private def self.scan_number_end(bytes : Bytes, start : Int32) : Int32
        i = start
        while i < bytes.size
          c = bytes[i]
          case c
          when '0'.ord..'9'.ord, '-'.ord, '+'.ord, '.'.ord, 'e'.ord, 'E'.ord
            i += 1
          else
            break
          end
        end
        i
      end
    end
  end
end
