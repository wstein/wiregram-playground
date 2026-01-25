# frozen_string_literal: true

require_relative 'ucl/lexer'
require_relative 'ucl/parser'
require_relative 'ucl/serializer'
require_relative '../core/token_stream'
require_relative 'ucl/transformer'
require_relative 'ucl/uom'

module WireGram
  module Languages
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
    end
  end
end
