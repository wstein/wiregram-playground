# frozen_string_literal: true

require_relative '../../core/parser'
require_relative '../../core/node'

module WireGram
  module Languages
    module Expression
      # Parser for simple expression language
      # Grammar:
      #   program    → statement*
      #   statement  → assignment | expression
      #   assignment → "let" IDENTIFIER "=" expression
      #   expression → term (("+"|"-") term)*
      #   term       → factor (("*"|"/") factor)*
      #   factor     → NUMBER | IDENTIFIER | STRING | "(" expression ")"
      class Parser < WireGram::Core::BaseParser
        def parse
          statements = []
          
          until at_end?
            begin
              stmt = parse_statement
              statements << stmt if stmt
            rescue => e
              @errors << { type: :parse_error, message: e.message, position: @position }
              synchronize
            end
          end

          WireGram::Core::Node.new(:program, children: statements)
        end

        private

        def parse_statement
          if current_token[:type] == :keyword && current_token[:value] == 'let'
            parse_assignment
          else
            parse_expression
          end
        end

        def parse_assignment
          expect(:keyword) # 'let'
          
          identifier_token = expect(:identifier)
          return nil unless identifier_token
          
          identifier = WireGram::Core::Node.new(:identifier, value: identifier_token[:value])
          
          expect(:equals)
          
          value = parse_expression
          return nil unless value
          
          WireGram::Core::Node.new(:assign, children: [identifier, value])
        end

        def parse_expression
          left = parse_term
          return nil unless left

          while [:plus, :minus].include?(current_token[:type])
            operator = current_token[:type]
            advance
            
            right = parse_term
            return nil unless right
            
            node_type = operator == :plus ? :add : :subtract
            left = WireGram::Core::Node.new(node_type, children: [left, right])
          end

          left
        end

        def parse_term
          left = parse_factor
          return nil unless left

          while [:star, :slash].include?(current_token[:type])
            operator = current_token[:type]
            advance
            
            right = parse_factor
            return nil unless right
            
            node_type = operator == :star ? :multiply : :divide
            left = WireGram::Core::Node.new(node_type, children: [left, right])
          end

          left
        end

        def parse_factor
          token = current_token

          case token[:type]
          when :number
            advance
            WireGram::Core::Node.new(:number, value: token[:value])
          when :string
            advance
            WireGram::Core::Node.new(:string, value: token[:value])
          when :identifier
            advance
            WireGram::Core::Node.new(:identifier, value: token[:value])
          when :lparen
            advance
            expr = parse_expression
            expect(:rparen)
            expr
          else
            @errors << { 
              type: :unexpected_token, 
              expected: "number, identifier, or '('",
              got: token[:type],
              position: token[:position]
            }
            advance # skip invalid token
            nil
          end
        end
      end
    end
  end
end
