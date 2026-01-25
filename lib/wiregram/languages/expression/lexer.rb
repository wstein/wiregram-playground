# frozen_string_literal: true

require_relative '../../core/lexer'

module WireGram
  module Languages
    module Expression
      # Lexer for simple expression language
      # Supports: numbers, identifiers, operators, keywords (let)
      class Lexer < WireGram::Core::BaseLexer
        KEYWORDS = %w[let].freeze

        protected

        def try_tokenize_next
          char = current_char

          case char
          when /\d/
            tokenize_number
          when /[a-zA-Z_]/
            tokenize_identifier
          when '+'
            add_token(:plus, '+')
            advance
            true
          when '-'
            add_token(:minus, '-')
            advance
            true
          when '*'
            add_token(:star, '*')
            advance
            true
          when '/'
            add_token(:slash, '/')
            advance
            true
          when '='
            add_token(:equals, '=')
            advance
            true
          when '('
            add_token(:lparen, '(')
            advance
            true
          when ')'
            add_token(:rparen, ')')
            advance
            true
          when '"'
            tokenize_string
          else
            false
          end
        end

        private

        def tokenize_number
          start = @position
          advance while current_char&.match?(/\d/)

          # Handle decimal point
          if current_char == '.' && peek_char&.match?(/\d/)
            advance # skip '.'
            advance while current_char&.match?(/\d/)
          end

          value = @source[start...@position].to_f
          value = value.to_i if value == value.to_i
          add_token(:number, value)
          true
        end

        def tokenize_identifier
          start = @position
          advance while current_char&.match?(/[a-zA-Z0-9_]/)

          value = @source[start...@position]
          type = KEYWORDS.include?(value) ? :keyword : :identifier
          add_token(type, value)
          true
        end

        def tokenize_string
          advance # skip opening quote
          start = @position

          while current_char && current_char != '"'
            advance
          end

          value = @source[start...@position]

          if current_char == '"'
            advance # skip closing quote
            add_token(:string, value)
          else
            # Unterminated string - report error and add token with captured value
            @errors << { type: :unexpected_token, message: 'Unterminated string', position: start }
            add_token(:string, value)
          end

          true
        end
      end
    end
  end
end
