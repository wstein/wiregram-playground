# frozen_string_literal: true

# WireGram - A universal, declarative framework for code analysis and transformation
#
# WireGram treats source code as a reversible digital fabric, providing a high-fidelity
# engine for processing any structured language.
module WireGram
  VERSION = '0.1.0'

  class Error < StandardError; end
  class ParseError < Error; end
  class TransformError < Error; end

  # Weave source code into a digital fabric
  #
  # @param source [String] Source code to weave
  # @param language [Symbol] Language type (default: :expression)
  # @return [WireGram::Core::Fabric] Digital fabric representation
  def self.weave(source, language: :expression)
    require_relative 'wiregram/core/fabric'
    require_relative 'wiregram/languages/expression/lexer'
    require_relative 'wiregram/languages/expression/parser'
    require_relative 'wiregram/languages/json/lexer'
    require_relative 'wiregram/languages/json/parser'
    require_relative 'wiregram/languages/ucl/lexer'
    require_relative 'wiregram/languages/ucl/parser'

    lexer = case language
            when :expression
              WireGram::Languages::Expression::Lexer.new(source)
            when :json
              WireGram::Languages::Json::Lexer.new(source)
            when :ucl
              WireGram::Languages::Ucl::Lexer.new(source)
            else
              raise Error, "Unsupported language: #{language}"
            end

    tokens = lexer.tokenize

    parser = case language
             when :expression
               WireGram::Languages::Expression::Parser.new(tokens)
             when :json
               WireGram::Languages::Json::Parser.new(tokens)
             when :ucl
               WireGram::Languages::Ucl::Parser.new(tokens)
             end

    ast = parser.parse

    WireGram::Core::Fabric.new(source, ast, tokens)
  end
end

# Auto-require language modules (so examples and tests can instantiate lexers/parsers)
require_relative 'wiregram/languages/expression/lexer'
require_relative 'wiregram/languages/expression/parser'
require_relative 'wiregram/languages/json/lexer'
require_relative 'wiregram/languages/json/parser'
require_relative 'wiregram/languages/ucl/lexer'
require_relative 'wiregram/languages/ucl/parser'
require_relative 'wiregram/languages/ucl/serializer'

# Auto-require core components
require_relative 'wiregram/core/node'
require_relative 'wiregram/core/fabric'
require_relative 'wiregram/engines/analyzer'
require_relative 'wiregram/engines/transformer'
