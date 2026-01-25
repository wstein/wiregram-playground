# frozen_string_literal: true

require_relative 'expression/lexer'
require_relative 'expression/parser'
require_relative 'expression/transformer'
require_relative 'expression/serializer'
require_relative 'expression/uom'

module WireGram
  module Languages
    module Expression
      # Main Expression Language module
      # Provides complete pipeline processing: tokenize -> parse -> transform -> serialize
      class << self
        def process(input, options = {})
          result = {}

          # Tokenize
          lexer = Lexer.new(input)
          tokens = lexer.tokenize
          result[:tokens] = tokens
          result[:errors] = lexer.errors.dup

          # Parse
          parser = Parser.new(tokens)
          ast = parser.parse
          result[:ast] = ast
          result[:errors].concat(parser.errors)

          # Transform to UOM
          transformer = Transformer.new
          uom = UOM.new(transformer.transform(ast))
          result[:uom] = uom

          # Serialize
          serializer = Serializer.new
          output = serializer.serialize(uom, options)
          result[:output] = output

          result
        end

        def process_pretty(input, indent_size = 2)
          process(input, pretty: true, indent_size: indent_size)
        end

        def process_simple(input)
          process(input, pretty: false)
        end

        def tokenize(input)
          lexer = Lexer.new(input)
          lexer.tokenize
        end

        def parse(input)
          tokens = tokenize(input)
          parser = Parser.new(tokens)
          parser.parse
        end

        def transform(input)
          ast = parse(input)
          transformer = Transformer.new
          UOM.new(transformer.transform(ast))
        end

        def serialize(input)
          uom = transform(input)
          serializer = Serializer.new
          serializer.serialize(uom)
        end

        def serialize_pretty(input, indent_size = 2)
          uom = transform(input)
          serializer = Serializer.new
          serializer.serialize_pretty(uom, indent_size)
        end

        def serialize_simple(input)
          uom = transform(input)
          serializer = Serializer.new
          serializer.serialize_simple(uom)
        end
      end
    end
  end
end
