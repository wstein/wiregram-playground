# frozen_string_literal: true

require "json"
require "./json/uom"
require "./json/lexer"
require "./json/parser"
require "./json/transformer"
require "./json/serializer"
require "../core/token_stream"

module WireGram
  module Languages
    # Universal Object Model for JSON
    module Json
      # JSON Language module - provides lexer, parser, transformer, UOM and serializer
      alias JsonResultValue = String | WireGram::Core::Node | Array(WireGram::Core::Token) | WireGram::Languages::Json::UOM | WireGram::Languages::Json::UOM::SimpleJson | Array(Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil)) | Nil

      def self.process(input, use_simd = false, use_symbolic_utf8 = false, use_upfront_rules = false, use_branchless = false, use_brzozowski = false, use_gpu = false, verbose = false)
        result = {} of Symbol => JsonResultValue

        lexer = WireGram::Languages::Json::Lexer.new(input, use_simd: use_simd, use_symbolic_utf8: use_symbolic_utf8, use_upfront_rules: use_upfront_rules, use_branchless: use_branchless, use_brzozowski: use_brzozowski, use_gpu: use_gpu, verbose: verbose)
        # Use a lazy token stream so parser requests tokens on demand
        token_stream = WireGram::Core::TokenStream.new(lexer)

        parser = WireGram::Languages::Json::Parser.new(token_stream)
        ast = parser.parse

        # Transform AST to UOM (normalization)
        uom = WireGram::Languages::Json::Transformer.transform(ast)

        # Convert UOM to normalized string
        normalized = WireGram::Languages::Json::Serializer.serialize(uom)

        result[:input] = input
        result[:tokens] = token_stream.tokens
        result[:ast] = ast
        result[:uom] = uom
        result[:uom_json] = uom.to_normalized_string
        result[:output] = normalized
        result[:errors] = parser.errors
        result
      end

      # Process with pretty formatting
      def self.process_pretty(input, indent : String = "  ", use_simd = false, use_symbolic_utf8 = false, use_upfront_rules = false, use_branchless = false, use_brzozowski = false, use_gpu = false, verbose = false)
        result = process(input, use_simd: use_simd, use_symbolic_utf8: use_symbolic_utf8, use_upfront_rules: use_upfront_rules, use_branchless: use_branchless, use_brzozowski: use_brzozowski, use_gpu: use_gpu, verbose: verbose)
        uom = result[:uom].as(WireGram::Languages::Json::UOM)
        result[:output] = WireGram::Languages::Json::Serializer.serialize_pretty(uom, indent)
        result
      end

      # Process to simple Ruby structure
      def self.process_simple(input, use_simd = false, use_symbolic_utf8 = false, use_upfront_rules = false, use_branchless = false, use_brzozowski = false, use_gpu = false, verbose = false)
        result = process(input, use_simd: use_simd, use_symbolic_utf8: use_symbolic_utf8, use_upfront_rules: use_upfront_rules, use_branchless: use_branchless, use_brzozowski: use_brzozowski, use_gpu: use_gpu, verbose: verbose)
        uom = result[:uom].as(WireGram::Languages::Json::UOM)
        result[:output] = WireGram::Languages::Json::Serializer.serialize_simple(uom)
        result
      end

      # Tokenize input
      def self.tokenize(input, use_simd = false, use_symbolic_utf8 = false, use_upfront_rules = false, use_branchless = false, use_brzozowski = false, use_gpu = false, verbose = false)
        lexer = WireGram::Languages::Json::Lexer.new(input, use_simd: use_simd, use_symbolic_utf8: use_symbolic_utf8, use_upfront_rules: use_upfront_rules, use_branchless: use_branchless, use_brzozowski: use_brzozowski, use_gpu: use_gpu, verbose: verbose)
        lexer.tokenize
      end

      # Stream tokens one-by-one (memory efficient for large files)
      def self.tokenize_stream(input, use_simd = false, use_symbolic_utf8 = false, use_upfront_rules = false, use_branchless = false, use_brzozowski = false, use_gpu = false, verbose = false, &block : WireGram::Core::Token ->)
        lexer = WireGram::Languages::Json::Lexer.new(input, use_simd: use_simd, use_symbolic_utf8: use_symbolic_utf8, use_upfront_rules: use_upfront_rules, use_branchless: use_branchless, use_brzozowski: use_brzozowski, use_gpu: use_gpu, verbose: verbose)
        lexer.enable_streaming!
        loop do
          token = lexer.next_token
          yield(token)
          break if token.type == WireGram::Core::TokenType::Eof
        end
      end

      # Parse input to AST
      def self.parse(input, use_simd = false, use_symbolic_utf8 = false, use_upfront_rules = false, use_branchless = false, use_brzozowski = false, use_gpu = false, verbose = false)
        lexer = WireGram::Languages::Json::Lexer.new(input, use_simd: use_simd, use_symbolic_utf8: use_symbolic_utf8, use_upfront_rules: use_upfront_rules, use_branchless: use_branchless, use_brzozowski: use_brzozowski, use_gpu: use_gpu, verbose: verbose)
        token_stream = WireGram::Core::TokenStream.new(lexer)
        parser = WireGram::Languages::Json::Parser.new(token_stream)
        parser.parse
      end

      # Stream AST nodes as they are parsed. Yields Node objects.
      def self.parse_stream(input, use_simd = false, use_symbolic_utf8 = false, use_upfront_rules = false, use_branchless = false, use_brzozowski = false, use_gpu = false, verbose = false, &block : WireGram::Core::Node? ->)
        lexer = WireGram::Languages::Json::Lexer.new(input, use_simd: use_simd, use_symbolic_utf8: use_symbolic_utf8, use_upfront_rules: use_upfront_rules, use_branchless: use_branchless, use_brzozowski: use_brzozowski, use_gpu: use_gpu, verbose: verbose)
        lexer.enable_streaming!
        token_stream = WireGram::Core::StreamingTokenStream.new(lexer)
        parser = WireGram::Languages::Json::Parser.new(token_stream)
        parser.parse_stream do |node|
          yield(node)
        end
      end
    end
  end
end
