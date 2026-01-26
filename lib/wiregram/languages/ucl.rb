# frozen_string_literal: true

require_relative 'ucl/lexer'
require_relative 'ucl/parser'
require_relative 'ucl/serializer'
require_relative '../core/token_stream'
require_relative 'ucl/transformer'
require_relative 'ucl/uom'

module WireGram
  module Languages
    # Universal Object Model for UCL (Universal Config Language)
    module Ucl
      # UCL Language module - provides lexer, parser, transformer, UOM and serializer
      def self.process(input, opts = {})
        lexer = WireGram::Languages::Ucl::Lexer.new(input)

        # Use a lazy token stream so parser requests tokens on demand
        token_stream = WireGram::Core::TokenStream.new(lexer)

        parser = WireGram::Languages::Ucl::Parser.new(token_stream)
        ast = parser.parse

        # Transform AST to UOM (normalization, merging, expansion will happen here)
        base_dir = opts[:source_path] ? File.dirname(opts[:source_path]) : nil
        vars = opts[:vars] || {}
        uom = WireGram::Languages::Ucl::Transformer.transform(ast, base_dir, Set.new, vars)

        # Convert UOM to normalized string
        normalized = uom.to_normalized_string

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

      # Tokenize input
      def self.tokenize(input)
        lexer = WireGram::Languages::Ucl::Lexer.new(input)
        token_stream = WireGram::Core::TokenStream.new(lexer)
        token_stream.tokens
      end

      # Stream tokens one-by-one (memory efficient for large files)
      def self.tokenize_stream(input)
        lexer = WireGram::Languages::Ucl::Lexer.new(input)
        lexer.enable_streaming!
        loop do
          token = lexer.next_token
          yield(token) if block_given?
          break if token && token[:type] == :eof
        end
      end

      # Parse input to AST
      def self.parse(input)
        lexer = WireGram::Languages::Ucl::Lexer.new(input)
        token_stream = WireGram::Core::TokenStream.new(lexer)
        parser = WireGram::Languages::Ucl::Parser.new(token_stream)
        parser.parse
      end

      def self.parse_stream(input)
        lexer = WireGram::Languages::Ucl::Lexer.new(input)
        lexer.enable_streaming!
        token_stream = WireGram::Core::StreamingTokenStream.new(lexer)
        parser = WireGram::Languages::Ucl::Parser.new(token_stream)
        parser.parse_stream do |node|
          yield(node) if block_given?
        end
      end
    end
  end
end
