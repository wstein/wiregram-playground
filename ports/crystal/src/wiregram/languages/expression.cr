# frozen_string_literal: true

require "./expression/lexer"
require "./expression/parser"
require "./expression/transformer"
require "./expression/serializer"
require "./expression/uom"

module WireGram
  module Languages
    # Universal Object Model for Expression Language
    module Expression
      # Main Expression Language module
      # Provides complete pipeline processing: tokenize -> parse -> transform -> serialize

      alias ExpressionResultValue = Array(WireGram::Core::Token) | WireGram::Core::Node | Array(Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil)) | WireGram::Languages::Expression::UOM | String | Nil

      def self.process(input, **options)
        result = {} of Symbol => ExpressionResultValue

        # Tokenize
        lexer = Lexer.new(input)
        tokens = lexer.tokenize
        result[:tokens] = tokens
        result[:errors] = lexer.errors.dup

        # Parse
        parser = Parser.new(tokens)
        ast = parser.parse
        result[:ast] = ast
        result[:errors].as(Array(Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil))).concat(parser.errors)

        # Transform to UOM
        transformer = Transformer.new
        uom = UOM.new(transformer.transform(ast))
        result[:uom] = uom

        # Serialize
        serializer = Serializer.new
        output = serializer.serialize(uom, **options)
        result[:output] = output

        result
      end

      def self.process_pretty(input, indent_size = 2)
        process(input, pretty: true, indent_size: indent_size)
      end

      def self.process_simple(input)
        process(input, pretty: false)
      end

      def self.tokenize(input)
        lexer = WireGram::Languages::Expression::Lexer.new(input)
        token_stream = WireGram::Core::TokenStream.new(lexer)
        token_stream.tokens
      end

      def self.tokenize_stream(input, &block : WireGram::Core::Token ->)
        lexer = WireGram::Languages::Expression::Lexer.new(input)
        lexer.enable_streaming!
        loop do
          token = lexer.next_token
          yield(token)
          break if token.type == WireGram::Core::TokenType::Eof
        end
      end

      def self.parse(input)
        lexer = WireGram::Languages::Expression::Lexer.new(input)
        token_stream = WireGram::Core::TokenStream.new(lexer)
        parser = WireGram::Languages::Expression::Parser.new(token_stream)
        parser.parse
      end

      def self.parse_stream(input, &block : WireGram::Core::Node? ->)
        lexer = WireGram::Languages::Expression::Lexer.new(input)
        lexer.enable_streaming!
        token_stream = WireGram::Core::StreamingTokenStream.new(lexer)
        parser = WireGram::Languages::Expression::Parser.new(token_stream)
        parser.parse_stream do |node|
          yield(node)
        end
      end

      def self.transform(input)
        ast = parse(input)
        transformer = Transformer.new
        UOM.new(transformer.transform(ast))
      end

      def self.serialize(input)
        uom = transform(input)
        serializer = Serializer.new
        serializer.serialize(uom)
      end

      def self.serialize_pretty(input, indent_size = 2)
        uom = transform(input)
        serializer = Serializer.new
        serializer.serialize_pretty(uom, indent_size)
      end

      def self.serialize_simple(input)
        uom = transform(input)
        serializer = Serializer.new
        serializer.serialize_simple(uom)
      end
    end
  end
end
