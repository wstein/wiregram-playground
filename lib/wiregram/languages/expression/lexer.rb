# frozen_string_literal: true

require 'strscan'
require_relative '../../core/lexer'

module WireGram
  module Languages
    module Expression
      # High-performance lexer for simple expression language using StringScanner
      # Supports: numbers, identifiers, operators, keywords (let)
      class Lexer < WireGram::Core::BaseLexer
        KEYWORDS = %w[let].freeze

        # Pre-compiled regex patterns for performance
        WHITESPACE_PATTERN = /\s+/
        NUMBER_PATTERN = /\d+(?:\.\d+)?/
        IDENTIFIER_PATTERN = /[a-zA-Z_][a-zA-Z0-9_]*/
        STRING_PATTERN = /"(?:\\.|[^"\\])*"/
        DIGIT_PATTERN = /\d/
        LETTER_PATTERN = /[a-zA-Z_]/

        def initialize(source)
          super(source)
          @scanner = StringScanner.new(source)
        end

        def skip_whitespace
          @scanner.pos = @position
          @scanner.skip(WHITESPACE_PATTERN)
          @position = @scanner.pos
        end

        protected

        def try_tokenize_next
          char = current_char

          case char
          when '+' then add_token(:plus, '+'); advance; true
          when '-' then add_token(:minus, '-'); advance; true
          when '*' then add_token(:star, '*'); advance; true
          when '/' then add_token(:slash, '/'); advance; true
          when '=' then add_token(:equals, '='); advance; true
          when '(' then add_token(:lparen, '('); advance; true
          when ')' then add_token(:rparen, ')'); advance; true
          when '"' then tokenize_string_fast
          when /\d/ then tokenize_number_fast
          when /[a-zA-Z_]/ then tokenize_identifier_fast
          else false
          end
        end

        private

        def tokenize_number_fast
          @scanner.pos = @position
          if @scanner.scan(NUMBER_PATTERN)
            matched = @scanner.matched
            value = matched.include?('.') ? matched.to_f : matched.to_i
            add_token(:number, value)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def tokenize_identifier_fast
          @scanner.pos = @position
          if @scanner.scan(IDENTIFIER_PATTERN)
            value = @scanner.matched
            type = KEYWORDS.include?(value) ? :keyword : :identifier
            add_token(type, value)
            @position = @scanner.pos
            true
          else
            false
          end
        end

        def tokenize_string_fast
          @scanner.pos = @position
          if matched = @scanner.scan(STRING_PATTERN)
            # Remove surrounding quotes and unescape
            content = matched[1...-1]
            unescaped = content.gsub(/\\(.)/) { |_| $1 }
            add_token(:string, unescaped)
            @position = @scanner.pos
            true
          else
            false
          end
        end
      end
    end
  end
end
