# frozen_string_literal: true

require 'spec_helper'
require 'wiregram/core/token_stream'

RSpec.describe 'Streaming mode' do
  context 'BaseLexer streaming' do
    it 'does not accumulate tokens in @tokens when streaming is enabled' do
      # Use a real language lexer to ensure we test concrete behavior
      lexer = WireGram::Languages::Ucl::Lexer.new("a: 1\nb: 2\nc: 3\n")

      lexer.enable_streaming!

      # Consume all tokens
      loop do
        token = lexer.next_token
        break if token && token[:type] == :eof
      end

      # In streaming mode the internal @tokens array should remain empty
      expect(lexer.tokens).to be_empty
    end

    it 'accumulates tokens when not streaming (sanity check)' do
      lexer = WireGram::Languages::Ucl::Lexer.new("a: 1\nb: 2\nc: 3\n")

      # Non-streaming tokenize should populate @tokens
      tokens = lexer.tokenize
      expect(tokens.length).to be > 1
      expect(lexer.tokens.length).to eq(tokens.length)
    end
  end

  context 'StreamingTokenStream buffer behavior' do
    class DummyLexer
      def initialize(count)
        @i = 0
        @count = count
      end

      def next_token
        if @i >= @count
          { type: :eof, value: nil, position: @i }
        else
          tok = { type: :id, value: "t#{@i}", position: @i }
          @i += 1
          tok
        end
      end
    end

    it 'keeps the internal buffer bounded by buffer_size when used correctly' do
      total = 100
      buffer_size = 8
      lexer = DummyLexer.new(total)
      stream = WireGram::Core::StreamingTokenStream.new(lexer, buffer_size)

      total.times do |i|
        # Peek ahead within the buffer window (0..buffer_size-1)
        peek_index = stream.instance_variable_get(:@base) + (i % buffer_size)
        _ = stream[peek_index]

        # Now advance by one
        token = stream.next
        break if token[:type] == :eof

        # Buffer should never exceed configured buffer_size
        buffer_len = stream.instance_variable_get(:@buffer).length
        expect(buffer_len).to be <= buffer_size
      end
    end

    it 'does not grow unbounded when only calling #next repeatedly' do
      total = 50
      buffer_size = 4
      lexer = DummyLexer.new(total)
      stream = WireGram::Core::StreamingTokenStream.new(lexer, buffer_size)

      total.times do
        token = stream.next
        break if token[:type] == :eof
        buffer_len = stream.instance_variable_get(:@buffer).length
        # With only next calls the buffer should be extremely small (<=1)
        expect(buffer_len).to be <= 1
      end
    end
  end
end
