# frozen_string_literal: true

require "../../core/parser"
require "../../core/node"
require "./transformer"
require "./serializer"

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
          statements = [] of WireGram::Core::Node

          until at_end?
            begin
              stmt = parse_statement
              statements << stmt if stmt
            rescue ex
              error = {} of Symbol => String | Int32 | WireGram::Core::TokenType | Symbol | Nil
              error[:type] = "parse_error"
              error[:message] = ex.message.to_s
              error[:position] = @position
              @errors << error
              synchronize
            end
          end

          WireGram::Core::Node.new(:program, children: statements)
        end

        # Stream statements as they are parsed (for large inputs / low memory)
        def parse_stream(&block : WireGram::Core::Node ->)
          until at_end?
            begin
              stmt = parse_statement
              yield(stmt) if stmt
            rescue ex
              error = {} of Symbol => String | Int32 | WireGram::Core::TokenType | Symbol | Nil
              error[:type] = "parse_error"
              error[:message] = ex.message.to_s
              error[:position] = @position
              @errors << error
              synchronize
            end
          end
        end

        # Enhanced parse method that returns complete pipeline results
        alias ExpressionResultValue = Array(WireGram::Core::Token) | WireGram::Core::Node | Array(Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil)) | WireGram::Languages::Expression::UOM | String | Nil

        def parse_with_pipeline(tokens)
          result = {} of Symbol => ExpressionResultValue

          # Store tokens
          result[:tokens] = tokens

          # Parse AST
          @tokens = tokens
          @position = 0
          @errors = [] of Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil)

          ast = parse
          result[:ast] = ast
          result[:errors] = @errors.dup

          # Transform to UOM
          transformer = Transformer.new
          uom = UOM.new(transformer.transform(ast))
          result[:uom] = uom

          # Serialize
          serializer = Serializer.new
          output = serializer.serialize(uom)
          result[:output] = output

          result
        end

        private def parse_statement
          token = current_token
          if token && token.type == WireGram::Core::TokenType::Keyword && token.value == "let"
            parse_assignment
          else
            parse_expression
          end
        end

        def parse_assignment
          expect(WireGram::Core::TokenType::Keyword) # "let"

          identifier_token = expect(WireGram::Core::TokenType::Identifier)
          return nil unless identifier_token

          identifier = WireGram::Core::Node.new(:identifier, value: identifier_token.value.as(String))

          expect(WireGram::Core::TokenType::Equals)

          value = parse_expression
          return nil unless value

          WireGram::Core::Node.new(:assign, children: [identifier, value])
        end

        def parse_expression : WireGram::Core::Node?
          left = parse_term
          return nil unless left

          while current_token && [WireGram::Core::TokenType::Plus, WireGram::Core::TokenType::Minus].includes?(current_token.not_nil!.type)
            operator = current_token.not_nil!.type
            advance

            right = parse_term
            return nil unless right

            node_type = operator == WireGram::Core::TokenType::Plus ? :add : :subtract
            left = WireGram::Core::Node.new(node_type, children: [left, right])
          end

          left
        end

        def parse_term : WireGram::Core::Node?
          left = parse_factor
          return nil unless left

          while current_token && [WireGram::Core::TokenType::Star, WireGram::Core::TokenType::Slash].includes?(current_token.not_nil!.type)
            operator = current_token.not_nil!.type
            advance

            right = parse_factor
            return nil unless right

            node_type = operator == WireGram::Core::TokenType::Star ? :multiply : :divide
            left = WireGram::Core::Node.new(node_type, children: [left, right])
          end

          left
        end

        def parse_factor : WireGram::Core::Node?
          token = current_token

          return nil unless token

          case token.type
          when WireGram::Core::TokenType::Number
            advance
            WireGram::Core::Node.new(:number, value: token.value)
          when WireGram::Core::TokenType::String
            advance
            WireGram::Core::Node.new(:string, value: token.value.as(String))
          when WireGram::Core::TokenType::Identifier
            advance
            WireGram::Core::Node.new(:identifier, value: token.value.as(String))
          when WireGram::Core::TokenType::LParen
            advance
            expr = parse_expression
            return nil unless expr
            expect(WireGram::Core::TokenType::RParen)
            # Preserve parentheses by wrapping expression in a group node
            WireGram::Core::Node.new(:group, children: [expr] of WireGram::Core::Node)
          else
            error = {} of Symbol => String | Int32 | WireGram::Core::TokenType | Symbol | Nil
            error[:type] = "unexpected_token"
            error[:expected] = "number, identifier, or '('"
            error[:got] = token.type
            error[:position] = token.position
            @errors << error
            advance # skip invalid token
            nil
          end
        end
      end
    end
  end
end
