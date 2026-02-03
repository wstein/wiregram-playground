# Stage1b: Lexer token assembly from structural indices.
module Warp
  module Lexer
    class TokenAssembler
      alias ErrorCode = Core::ErrorCode
      alias Token = Core::Token
      alias TokenType = Core::TokenType
      alias LexerBuffer = Core::LexerBuffer

      def self.each_token(bytes : Bytes, buffer : LexerBuffer, state : LexerState? = nil, &block : Token ->) : ErrorCode
        len = bytes.size
        idx_ptr = buffer.ptr
        count = buffer.count

        # Fallback: if there are no structural indices, scan the entire input for tokens
        if count == 0
          pos = 0
          while pos < len
            # Skip whitespace
            while pos < len && (bytes[pos] == ' '.ord || bytes[pos] == '\t'.ord || bytes[pos] == '\n'.ord || bytes[pos] == '\r'.ord)
              pos += 1
            end
            break if pos >= len

            b = bytes[pos]
            case b
            when '{'.ord
              yield Token.new(TokenType::StartObject, pos, 1); pos += 1; next
            when '}'.ord
              yield Token.new(TokenType::EndObject, pos, 1); pos += 1; next
            when '['.ord
              yield Token.new(TokenType::StartArray, pos, 1); pos += 1; next
            when ']'.ord
              yield Token.new(TokenType::EndArray, pos, 1); pos += 1; next
            when ':'.ord
              yield Token.new(TokenType::Colon, pos, 1); pos += 1; next
            when ','.ord
              yield Token.new(TokenType::Comma, pos, 1); pos += 1; next
            when '"'.ord
              start = pos + 1
              end_idx = IR.scan_string_end(bytes, start, -1)
              return ErrorCode::UnclosedString if end_idx < 0
              state.try(&.push(LexerState::State::String))
              yield Token.new(TokenType::String, start, end_idx - start)
              state.try(&.pop)
              pos = end_idx + 1
              next
            else
              end_idx = IR.scan_scalar_end(bytes, pos, -1)
              tok_type = scalar_type(bytes[pos])
              yield Token.new(tok_type, pos, end_idx - pos)
              pos = end_idx
              next
            end
          end

          return ErrorCode::Success
        end

        i = 0
        while i < count
          idx = idx_ptr[i].to_i
          next_idx = i + 1 < count ? idx_ptr[i + 1].to_i : -1
          c = bytes[idx]
          case c
          when '{'.ord
            yield Token.new(TokenType::StartObject, idx, 1)
          when '}'.ord
            yield Token.new(TokenType::EndObject, idx, 1)
          when '['.ord
            yield Token.new(TokenType::StartArray, idx, 1)
          when ']'.ord
            yield Token.new(TokenType::EndArray, idx, 1)
          when ':'.ord
            yield Token.new(TokenType::Colon, idx, 1)
          when ','.ord
            yield Token.new(TokenType::Comma, idx, 1)
          when '\n'.ord
            yield Token.new(TokenType::Newline, idx, 1)
          when '\r'.ord
            # Coalesce CRLF into a single newline token.
            if idx + 1 < len && bytes[idx + 1] == '\n'.ord
              yield Token.new(TokenType::Newline, idx, 2)
              i += 1 if next_idx == idx + 1
            else
              yield Token.new(TokenType::Newline, idx, 1)
            end
          when '"'.ord
            start = idx + 1
            end_idx = IR.scan_string_end(bytes, start, next_idx)
            return ErrorCode::UnclosedString if end_idx < 0

            state.try(&.push(LexerState::State::String))
            yield Token.new(TokenType::String, start, end_idx - start)
            state.try(&.pop)
            # Advance the structural index pointer past the string's closing quote
            # so we don't treat the closing quote as the start of a new string.
            while i + 1 < count && idx_ptr[i + 1].to_i <= end_idx
              i += 1
            end
          else
            start = idx
            end_idx = IR.scan_scalar_end(bytes, start, next_idx)
            tok_type = scalar_type(bytes[start])
            yield Token.new(tok_type, start, end_idx - start)
          end

          # ... rest of the method unchanged ...

          # Detect scalar tokens that are not represented in the structural
          # index stream. For example, a number between a colon and a comma
          # may not have been marked by the lexer; find a non-whitespace
          # byte between the current index and the next structural index
          # and emit a scalar token if appropriate.
          unless c == '"'.ord
            limit = next_idx != -1 ? next_idx : len
            s = idx + 1
            while s < limit
              while s < limit && (bytes[s] == ' '.ord || bytes[s] == '\t'.ord || bytes[s] == '\n'.ord || bytes[s] == '\r'.ord)
                s += 1
              end
              break if s >= limit
              b = bytes[s]
              # Skip structural starts
              if b == '{'.ord || b == '}'.ord || b == '['.ord || b == ']'.ord || b == ':'.ord || b == ','.ord || b == '"'.ord || b == '\n'.ord || b == '\r'.ord
                break
              end
              e = IR.scan_scalar_end(bytes, s, limit)
              tok_type = scalar_type(bytes[s])
              yield Token.new(tok_type, s, e - s)
              s = e
            end
          end

          i += 1
        end

        ErrorCode::Success
      end

      private def self.scalar_type(first_byte : UInt8) : TokenType
        case first_byte
        when 't'.ord
          TokenType::True
        when 'f'.ord
          TokenType::False
        when 'n'.ord
          TokenType::Null
        else
          TokenType::Number
        end
      end
    end
  end
end
