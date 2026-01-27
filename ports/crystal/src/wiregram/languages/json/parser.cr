# frozen_string_literal: true

require "../../core/parser"
require "../../core/node"

module WireGram
  module Languages
    module Json
      # Parser for JSON
      # Grammar (simplified):
      # value -> object | array | string | number | true | false | null
      # object -> '{' (pair (',' pair)*)? '}'
      # pair -> string ':' value
      # array -> '[' (value (',' value)*)? ']'
      class Parser < WireGram::Core::BaseParser
        def parse
          parse_value
        end

        # Stream parsed nodes as they are built. For arrays, yields each item as it is parsed.
        def parse_stream(&block : WireGram::Core::Node? ->)
          # If top-level array, stream each item
          token = current_token
          if token && token.type == WireGram::Core::TokenType::LBracket
            expect(WireGram::Core::TokenType::LBracket)

            unless current_token.try(&.type) == WireGram::Core::TokenType::RBracket
              loop do
                node = parse_value
                yield(node)
                break if current_token.try(&.type) == WireGram::Core::TokenType::RBracket

                expect(WireGram::Core::TokenType::Comma)
              end
            end

            expect(WireGram::Core::TokenType::RBracket)
          else
            node = parse_value
            yield(node)
          end
        end

        private def parse_value
          token = current_token
          return nil unless token

          case token.type
          when WireGram::Core::TokenType::LBrace
            parse_object
          when WireGram::Core::TokenType::LBracket
            parse_array
          when WireGram::Core::TokenType::String
            advance
            WireGram::Core::Node.new(:string, value: token.value.as(String))
          when WireGram::Core::TokenType::Number
            advance
            WireGram::Core::Node.new(:number, value: token.value)
          when WireGram::Core::TokenType::Boolean
            advance
            WireGram::Core::Node.new(:boolean, value: token.value)
          when WireGram::Core::TokenType::Null
            advance
            WireGram::Core::Node.new(:null, value: nil)
          else
            error = {} of Symbol => String | Int32 | WireGram::Core::TokenType | Symbol | Nil
            error[:type] = "unexpected_token"
            error[:got] = token.type
            error[:position] = token.position
            @errors << error
            advance
            nil
          end
        end

        def parse_object
          expect(WireGram::Core::TokenType::LBrace)
          members = [] of WireGram::Core::Node

          token = current_token
          unless token && token.type == WireGram::Core::TokenType::RBrace
            loop do
              key_token = expect(WireGram::Core::TokenType::String)
              expect(WireGram::Core::TokenType::Colon)
              value = parse_value

              if key_token && value
                members << WireGram::Core::Node.new(:pair,
                                                    children: [
                                                      WireGram::Core::Node.new(:string, value: key_token.value.as(String)), value
                                                    ] of WireGram::Core::Node)
              end

              comma_token = current_token
              break unless comma_token && comma_token.type == WireGram::Core::TokenType::Comma

              expect(WireGram::Core::TokenType::Comma)
            end
          end

          expect(WireGram::Core::TokenType::RBrace)
          WireGram::Core::Node.new(:object, children: members)
        end

        def parse_array
          expect(WireGram::Core::TokenType::LBracket)
          items = [] of WireGram::Core::Node

          token = current_token
          unless token && token.type == WireGram::Core::TokenType::RBracket
            loop do
              value = parse_value
              items << value if value
              array_token = current_token
              break if array_token && array_token.type == WireGram::Core::TokenType::RBracket

              expect(WireGram::Core::TokenType::Comma)
            end
          end

          expect(WireGram::Core::TokenType::RBracket)
          WireGram::Core::Node.new(:array, children: items)
        end
      end
    end
  end
end
