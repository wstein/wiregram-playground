# frozen_string_literal: true

require_relative '../../core/parser'
require_relative '../../core/node'

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
        def parse_stream
          # If top-level array, stream each item
          if current_token && current_token[:type] == :lbracket
            expect(:lbracket)

            unless current_token[:type] == :rbracket
              loop do
                node = parse_value
                yield(node) if block_given?
                break if current_token[:type] == :rbracket
                expect(:comma)
              end
            end

            expect(:rbracket)
          else
            node = parse_value
            yield(node) if block_given?
          end
        end

        private

        def parse_value
          token = current_token
          case token[:type]
          when :lbrace
            parse_object
          when :lbracket
            parse_array
          when :string
            advance
            WireGram::Core::Node.new(:string, value: token[:value])
          when :number
            advance
            WireGram::Core::Node.new(:number, value: token[:value])
          when :boolean
            advance
            WireGram::Core::Node.new(:boolean, value: token[:value])
          when :null
            advance
            WireGram::Core::Node.new(:null, value: nil)
          else
            @errors << { type: :unexpected_token, got: token[:type], position: token[:position] }
            advance
            nil
          end
        end

        def parse_object
          expect(:lbrace)
          members = []

          unless current_token && current_token[:type] == :rbrace
            loop do
              key_token = expect(:string)
              expect(:colon)
              value = parse_value

              if key_token
                members << WireGram::Core::Node.new(:pair, children: [WireGram::Core::Node.new(:string, value: key_token[:value]), value])
              end

              break unless current_token && current_token[:type] == :comma
              expect(:comma)
            end
          end

          expect(:rbrace)
          WireGram::Core::Node.new(:object, children: members)
        end

        def parse_array
          expect(:lbracket)
          items = []

          unless current_token[:type] == :rbracket
            loop do
              value = parse_value
              items << value
              break if current_token[:type] == :rbracket
              expect(:comma)
            end
          end

          expect(:rbracket)
          WireGram::Core::Node.new(:array, children: items)
        end
      end
    end
  end
end
