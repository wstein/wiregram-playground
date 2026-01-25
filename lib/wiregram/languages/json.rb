# frozen_string_literal: true

require_relative 'json/lexer'
require_relative 'json/parser'
require_relative 'json/transformer'
require_relative 'json/serializer'
require_relative 'json/uom'
require_relative '../core/token_stream'

module WireGram
  module Languages
    module Json
      # JSON Language module - provides lexer, parser, transformer, UOM and serializer
      def self.process(input)
        lexer = WireGram::Languages::Json::Lexer.new(input)

        # Use a lazy token stream so parser requests tokens on demand
        token_stream = WireGram::Core::TokenStream.new(lexer)

        parser = WireGram::Languages::Json::Parser.new(token_stream)
        ast = parser.parse

        # Transform AST to UOM (normalization)
        uom = WireGram::Languages::Json::Transformer.transform(ast)

        # Convert UOM to normalized string
        normalized = WireGram::Languages::Json::Serializer.serialize(uom)

        {
          input: input,
          tokens: token_stream.tokens,
          ast: ast,
          uom: uom,
          uom_json: uom.to_simple_json,
          output: normalized,
          errors: parser.errors
        }
      end

      # Process with pretty formatting
      def self.process_pretty(input, indent = '  ')
        result = process(input)
        if result[:uom]
          result[:output] = WireGram::Languages::Json::Serializer.serialize_pretty(result[:uom], indent)
        end
        result
      end

      # Process to simple Ruby structure
      def self.process_simple(input)
        result = process(input)
        if result[:uom]
          result[:output] = WireGram::Languages::Json::Serializer.serialize_simple(result[:uom])
        end
        result
      end

      # Tokenize input
      def self.tokenize(input)
        lexer = WireGram::Languages::Json::Lexer.new(input)
        token_stream = WireGram::Core::TokenStream.new(lexer)
        token_stream.tokens
      end

      # Stream tokens one-by-one (memory efficient for large files)
      def self.tokenize_stream(input)
        lexer = WireGram::Languages::Json::Lexer.new(input)
        lexer.enable_streaming!
        loop do
          token = lexer.next_token
          yield(token) if block_given?
          break if token && token[:type] == :eof
        end
      end

      # Parse input to AST
      def self.parse(input)
        lexer = WireGram::Languages::Json::Lexer.new(input)
        token_stream = WireGram::Core::TokenStream.new(lexer)
        parser = WireGram::Languages::Json::Parser.new(token_stream)
        parser.parse
      end

      # Stream AST nodes as they are parsed. Yields Node objects.
      def self.parse_stream(input)
        lexer = WireGram::Languages::Json::Lexer.new(input)
        lexer.enable_streaming!
        token_stream = WireGram::Core::StreamingTokenStream.new(lexer)
        parser = WireGram::Languages::Json::Parser.new(token_stream)
        parser.parse_stream do |node|
          yield(node) if block_given?
        end
      end
    end
  end
end
