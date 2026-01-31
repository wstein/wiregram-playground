# frozen_string_literal: true

require "./token"
require "./simd_accelerator"
require "./brzozowski"
require "./metal_accelerator"

module WireGram
  module Core
  # Base Lexer - Foundation for tokenization
  # Provides error recovery and resilient tokenization
  class BaseLexer
    getter source : String
    getter position : Int32
    getter tokens : Array(Token)
    getter errors : Array(Hash(Symbol, String | Int32 | TokenType | Symbol | Nil))
    getter last_token : Token | Nil
    property? use_simd : Bool = false
    property? use_symbolic_utf8 : Bool = false
    property? use_upfront_rules : Bool = false
    property? use_branchless : Bool = false
    property? use_brzozowski : Bool = false
    property? use_gpu : Bool = false
    property? verbose : Bool = false

    @structural_indices : Array(Int32)? = nil
    @structural_types : Array(UInt8)? = nil
    @current_structural_ptr : Int32 = 0

    def initialize(@source : String)
      @bytes = @source.to_slice
      @position = 0
      @tokens = [] of Token
      @errors = [] of Hash(Symbol, String | Int32 | TokenType | Symbol | Nil)
      @streaming = false
      @last_token = nil
    end

    # Stage 1: Build structural index upfront if requested
    def build_structural_index!
      return unless @use_upfront_rules
      STDERR.puts "[Lexer] Building structural index (Stage 1)..." if @verbose
      size = @bytes.size
      # Pre-calculate capacity to avoid many reallocations
      # A rough estimate for JSON/UCL is 1 structural char per 10 bytes
      indices = Array(Int32).new(size // 8)
      types = Array(UInt8).new(size // 8) if @use_branchless
      ptr = @bytes.to_unsafe
      i = 0

      # Parallel indexing if requested (Experimental)
      if @use_upfront_rules && ENV["WIREGRAM_PARALLEL_INDEXING"]? == "1"
        STDERR.puts "[Lexer] Using parallel indexing (4 fibers)..." if @verbose
        parallel_build_structural_index!
        return
      end

      # Use SIMD for Stage 1 if enabled
      if @use_simd
        STDERR.puts "[Lexer] Using SIMD for Stage 1..." if @verbose
        # Hot loop optimization: local references
        bytes = @bytes
        idx = indices
        typ = types

        while i + 15 < size
          mask, _ = SimdAccelerator.find_structural_bits(ptr + i)
          if mask > 0
            m = mask
            while m > 0
              tz = m.trailing_zeros_count
              pos = i + tz
              idx << pos
              # Branchless path requires character types to avoid dispatch overhead in Stage 2
              if typ
                typ << bytes[pos]
              end
              m &= (m - 1)
            end
          end
          i += 16
        end
      end

      # Finish remaining bytes or full scan if SIMD disabled
      while i < size
        b = @bytes[i]
        if b <= 0x20 || b == 0x7b || b == 0x7d || b == 0x5b || b == 0x5d || b == 0x3a || b == 0x2c || b == 0x22 || b == 0x5c || b == 0x3d || b == 0x3b || b == 0x23 || b == 0x2f
          indices << i
          types << b if types
        end
        i += 1
      end
      @structural_indices = indices
      @structural_types = types
      @current_structural_ptr = 0
    end

    private def parallel_build_structural_index!
      size = @bytes.size
      num_fibers = 4
      chunk_size = (size / num_fibers).to_i
      channel = Channel({Int32, Array(Int32), Array(UInt8)?}).new

      num_fibers.times do |f|
        spawn do
          start_pos = f * chunk_size
          end_pos = (f == num_fibers - 1) ? size : (f + 1) * chunk_size
          chunk_indices = [] of Int32
          chunk_types = @use_branchless ? [] of UInt8 : nil

          ptr = @bytes.to_unsafe
          i = start_pos

          if @use_simd
            while i + 15 < end_pos
              mask, _ = SimdAccelerator.find_structural_bits(ptr + i)
              while mask > 0
                tz = mask.trailing_zeros_count
                pos = i + tz
                if pos < end_pos
                  chunk_indices << pos
                  chunk_types << @bytes[pos] if chunk_types
                end
                mask &= (mask - 1)
              end
              i += 16
            end
          end

          while i < end_pos
            b = @bytes[i]
            if b <= 0x20 || b == 0x7b || b == 0x7d || b == 0x5b || b == 0x5d || b == 0x3a || b == 0x2c || b == 0x22 || b == 0x5c || b == 0x3d || b == 0x3b || b == 0x23 || b == 0x2f
              chunk_indices << i
              chunk_types << b if chunk_types
            end
            i += 1
          end
          channel.send({f, chunk_indices, chunk_types})
        end
      end

      results = Array({Int32, Array(Int32), Array(UInt8)?}).new(num_fibers)
      num_fibers.times { results << channel.receive }
      results.sort_by! { |r| r[0] }

      all_indices = Array(Int32).new(size // 10)
      all_types = @use_branchless ? Array(UInt8).new(size // 10) : nil

      results.each do |r|
        all_indices.concat(r[1])
        t = r[2]
        all_types.concat(t) if all_types && t
      end

      @structural_indices = all_indices
      @structural_types = all_types
      @current_structural_ptr = 0
    end

      # Jump to the next structural character using the index
      private def jump_to_next_structural
        indices = @structural_indices
        return unless indices

        while @current_structural_ptr < indices.size && indices[@current_structural_ptr] < @position
          @current_structural_ptr += 1
        end

        if @current_structural_ptr < indices.size
          @position = indices[@current_structural_ptr]
        else
          @position = @bytes.size
        end
      end

      # Teleport to the next structural character, skipping non-structural data.
      # This is used for skipping content of strings or unquoted literals.
      protected def teleport_to_next
        return advance unless @use_upfront_rules && (indices = @structural_indices)

        idx_size = indices.size
        cur_ptr = @current_structural_ptr
        pos = @position

        while cur_ptr < idx_size && indices[cur_ptr] <= pos
          cur_ptr += 1
        end
        @current_structural_ptr = cur_ptr

        if cur_ptr < idx_size
          @position = indices[cur_ptr]
        else
          @position = @bytes.size
        end
      end

      # Public API to enable/disable streaming mode. When enabled, tokens are
      # returned directly and not stored in @tokens which avoids large memory
      # allocations during token streaming.
      def enable_streaming!
        @streaming = true
      end

      def disable_streaming!
        @streaming = false
      end

      # Tokenize the source code eagerly (compatibility)
      def tokenize : Array(Token)
        @tokens = [] of Token
        @errors = [] of Hash(Symbol, String | Int32 | TokenType | Symbol | Nil)
        @position = 0
        @streaming = false

        t1 = Time.instant
        loop do
          token = next_token
          break if token.type == TokenType::Eof
        end
        t2 = Time.instant
        STDERR.puts "[Lexer] Stage 2 took #{(t2 - t1).to_f * 1000} ms" if @verbose
        STDERR.puts "[Lexer] Total tokens: #{@tokens.size}" if @verbose

        @tokens
      end

      # Produce the next token from the source on demand.
      # This enables lazy tokenization for parsers that request tokens incrementally.
      def next_token : Token
        if @use_branchless && @use_upfront_rules && (indices = @structural_indices) && (types = @structural_types)
          # Branchless Stage 2 path
          loop do
            # Skip whitespace using index
            # This is a hot loop. We pre-fetch variables to avoid repeated property access.
            idx_size = indices.size
            cur_ptr = @current_structural_ptr

            # Inlined whitespace skipping
            unsafe_types = types.to_unsafe
            unsafe_indices = indices.to_unsafe
            while cur_ptr < idx_size
              b = unsafe_types[cur_ptr]
              if b > 0x20
                @current_structural_ptr = cur_ptr
                @position = unsafe_indices[cur_ptr]

                # FAST PATH: Structural tokens
                if b == 0x2c # ','
                  add_token(TokenType::Comma, ",")
                  @position += 1
                  @current_structural_ptr = cur_ptr + 1
                  return @streaming ? @last_token.not_nil! : @tokens.last
                elsif b == 0x3a # ':'
                  add_token(TokenType::Colon, ":")
                  @position += 1
                  @current_structural_ptr = cur_ptr + 1
                  return @streaming ? @last_token.not_nil! : @tokens.last
                elsif b == 0x7d # '}'
                  add_token(TokenType::RBrace, "}")
                  @position += 1
                  @current_structural_ptr = cur_ptr + 1
                  return @streaming ? @last_token.not_nil! : @tokens.last
                elsif b == 0x7b # '{'
                  add_token(TokenType::LBrace, "{")
                  @position += 1
                  @current_structural_ptr = cur_ptr + 1
                  return @streaming ? @last_token.not_nil! : @tokens.last
                elsif b == 0x5d # ']'
                  add_token(TokenType::RBracket, "]")
                  @position += 1
                  @current_structural_ptr = cur_ptr + 1
                  return @streaming ? @last_token.not_nil! : @tokens.last
                elsif b == 0x5b # '['
                  add_token(TokenType::LBracket, "[")
                  @position += 1
                  @current_structural_ptr = cur_ptr + 1
                  return @streaming ? @last_token.not_nil! : @tokens.last
                end

                prev_len = @tokens.size
                @last_token = nil if @streaming

                if try_tokenize_next
                  # Sync @current_structural_ptr with the new @position after tokenization
                  pos = @position
                  cur_ptr = @current_structural_ptr
                  while cur_ptr < idx_size && unsafe_indices[cur_ptr] < pos
                    cur_ptr += 1
                  end
                  @current_structural_ptr = cur_ptr

                  if @streaming
                    return @last_token.not_nil! if @last_token
                  elsif @tokens.size > prev_len
                    return @tokens.last
                  end
                  # If try_tokenize_next returned true but didn't add a token (e.g. comment skip),
                  # continue loop with updated cur_ptr
                  break
                else
                  # Error recovery: skip character and report unknown
                  error = {} of Symbol => String | Int32 | TokenType | Symbol | Nil
                  error[:type] = "unknown_character"
                  error[:char] = current_char
                  error[:position] = @position
                  @errors << error
                  token = Token.new(TokenType::Unknown, current_char, @position)
                  advance
                  # Sync @current_structural_ptr after advance
                  cur_ptr = @current_structural_ptr
                  while cur_ptr < idx_size && unsafe_indices[cur_ptr] < @position
                    cur_ptr += 1
                  end
                  @current_structural_ptr = cur_ptr
                  if @streaming
                    @last_token = token
                  else
                    @tokens << token
                  end
                  return token
                end
              end
              cur_ptr += 1
            end

            if cur_ptr >= idx_size
              @current_structural_ptr = cur_ptr
              @position = @bytes.size
              token = Token.new(TokenType::Eof, nil, @position)
              if @streaming
                @last_token = token
              else
                @tokens << token unless @tokens.last? && @tokens.last.type == TokenType::Eof
              end
              return token
            end
          end
        end

        skip_whitespace

        # If at end, return EOF token
        if @position >= @bytes.size
          token = Token.new(TokenType::Eof, nil, @position)
          if @streaming
            @last_token = token
          else
            @tokens << token unless @tokens.last? && @tokens.last.type == TokenType::Eof
          end
          return token
        end

        prev_len = @tokens.size
        @last_token = nil if @streaming

        # Keep trying until a token has been added (skip_comment may not add tokens)
        loop do
          if try_tokenize_next
            if @streaming
              return @last_token.not_nil! if @last_token
            elsif @tokens.size > prev_len
              return @tokens.last
            end
          else
            # Error recovery: skip character and report unknown
            error = {} of Symbol => String | Int32 | TokenType | Symbol | Nil
            error[:type] = "unknown_character"
            error[:char] = current_char
            error[:position] = @position
            @errors << error
            token = Token.new(TokenType::Unknown, current_char, @position)
            advance
            if @streaming
              @last_token = token
            else
              @tokens << token
            end
            return token
          end

          # If we advanced to EOF while skipping, return EOF
          next unless @position >= @bytes.size

          token = Token.new(TokenType::Eof, nil, @position)
          if @streaming
            @last_token = token
          else
            @tokens << token unless @tokens.last? && @tokens.last.type == TokenType::Eof
          end
          return token
        end
      end

      # To be implemented by subclasses
      private def try_tokenize_next : Bool
        raise "Subclasses must implement try_tokenize_next"
      end

      def current_char : String?
        return nil if @position >= @bytes.size
        if @use_symbolic_utf8
          # Symbolic UTF-8: avoid byte_slice if it's ASCII
          b = @bytes[@position]
          return b.chr.to_s if b < 0x80
        end
        @source.byte_slice(@position, 1)
      end

      def peek_char(offset = 1) : String?
        pos = @position + offset
        return nil if pos >= @bytes.size
        @source.byte_slice(pos, 1)
      end

      def current_byte : UInt8?
        return nil if @position >= @bytes.size
        @bytes[@position]
      end

      def peek_byte(offset = 1) : UInt8?
        pos = @position + offset
        return nil if pos >= @bytes.size
        @bytes[pos]
      end

      def advance
        @position += 1
      end

      def skip_whitespace
        if @use_upfront_rules
          jump_to_next_structural
          return
        end

        if @use_simd
          ptr = @bytes.to_unsafe
          size = @bytes.size
          while @position + 15 < size
            mask, _ = SimdAccelerator.find_structural_bits(ptr + @position)

            # If no structural bits (which include whitespace), skip entire 16 bytes
            if mask == 0
              @position += 16
            else
              # Find first set bit (trailing zero count)
              tz = mask.trailing_zeros_count
              @position += tz

              # Now @position is at a structural char.
              # If it's whitespace, we consume it and continue, otherwise we stop.
              while (byte = current_byte)
                case byte
                when 0x20, 0x09, 0x0a, 0x0d, 0x0b, 0x0c
                  @position += 1
                else
                  return
                end
              end
              return
            end
          end
        end

        while (byte = current_byte)
          case byte
          when 0x20, 0x09, 0x0a, 0x0d, 0x0b, 0x0c
            advance
          else
            break
          end
        end
      end

      def add_token(type : TokenType, value : TokenValue = nil, extras : Hash(Symbol, TokenExtraValue)? = nil, position : Int32? = nil) : Token
        token_pos = position || @position
        token = Token.new(type, value, token_pos, extras)
        if @streaming
          @last_token = token
        else
          @tokens << token
        end
        token
      end
    end
  end
end
