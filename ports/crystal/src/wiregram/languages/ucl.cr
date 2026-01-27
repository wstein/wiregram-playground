# frozen_string_literal: true

require "./ucl/lexer"
require "./ucl/parser"
require "./ucl/serializer"
require "../core/token_stream"
require "./ucl/transformer"
require "./ucl/uom"

module WireGram
  module Languages
    # Universal Object Model for UCL (Universal Config Language)
    module Ucl
      alias UclResultValue = String | WireGram::Core::Node | Array(WireGram::Core::Token) | WireGram::Languages::Ucl::UOM | Array(Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil)) | Nil

      # UCL Language module - provides lexer, parser, transformer, UOM and serializer
      def self.process(input, source_path : String? = nil, vars = {} of String => String)
        result = {} of Symbol => UclResultValue

        lexer = WireGram::Languages::Ucl::Lexer.new(input)

        # Use a lazy token stream so parser requests tokens on demand
        token_stream = WireGram::Core::TokenStream.new(lexer)

        parser = WireGram::Languages::Ucl::Parser.new(token_stream)
        ast = parser.parse

        # Transform AST to UOM (normalization, merging, expansion will happen here)
        base_dir = source_path ? File.dirname(source_path) : nil
        uom = WireGram::Languages::Ucl::Transformer.transform(ast, base_dir, Set(String).new, vars)

        # Convert UOM to normalized string
        normalized = uom.to_normalized_string

        result[:input] = input
        result[:tokens] = token_stream.tokens
        result[:ast] = ast
        result[:uom] = uom
        result[:uom_json] = uom.to_normalized_string
        result[:output] = normalized
        result[:errors] = parser.errors
        result
      end

      # Tokenize input
      def self.tokenize(input)
        lexer = WireGram::Languages::Ucl::Lexer.new(input)
        token_stream = WireGram::Core::TokenStream.new(lexer)
        token_stream.tokens
      end

      # Stream tokens one-by-one (memory efficient for large files)
      def self.tokenize_stream(input, &block : WireGram::Core::Token ->)
        lexer = WireGram::Languages::Ucl::Lexer.new(input)
        lexer.enable_streaming!
        loop do
          token = lexer.next_token
          yield(token)
          break if token.type == WireGram::Core::TokenType::Eof
        end
      end

      # Parse input to AST
      def self.parse(input)
        lexer = WireGram::Languages::Ucl::Lexer.new(input)
        token_stream = WireGram::Core::TokenStream.new(lexer)
        parser = WireGram::Languages::Ucl::Parser.new(token_stream)
        parser.parse
      end

      def self.parse_stream(input, &block : WireGram::Core::Node? ->)
        lexer = WireGram::Languages::Ucl::Lexer.new(input)
        lexer.enable_streaming!
        token_stream = WireGram::Core::StreamingTokenStream.new(lexer)
        parser = WireGram::Languages::Ucl::Parser.new(token_stream)
        parser.parse_stream do |node|
          yield(node)
        end
      end
    end
  end
end
