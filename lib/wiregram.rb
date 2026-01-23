# frozen_string_literal: true

# WireGram - A universal, declarative framework for code analysis and transformation
#
# WireGram treats source code as a reversible digital fabric, providing a high-fidelity
# engine for processing any structured language.
module WireGram
  VERSION = "0.1.0"

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
    
    lexer = case language
            when :expression
              WireGram::Languages::Expression::Lexer.new(source)
            else
              raise Error, "Unsupported language: #{language}"
            end
    
    tokens = lexer.tokenize
    parser = WireGram::Languages::Expression::Parser.new(tokens)
    ast = parser.parse
    
    WireGram::Core::Fabric.new(source, ast, tokens)
  end
end

# Auto-require core components
require_relative 'wiregram/core/node'
require_relative 'wiregram/core/fabric'
require_relative 'wiregram/engines/analyzer'
require_relative 'wiregram/engines/transformer'
