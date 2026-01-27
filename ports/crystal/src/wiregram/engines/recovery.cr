# frozen_string_literal: true

require "../core/token"

module WireGram
  module Engines
    # Recovery - Error recovery mechanisms for resilient parsing
    class Recovery
      # Recover from parse errors by finding synchronization points
      def self.synchronize_after_error(tokens : Array(WireGram::Core::Token), position : Int32)
        # Find next statement boundary or safe point
        while position < tokens.size
          token = tokens[position]
          return position if [WireGram::Core::TokenType::Semicolon, WireGram::Core::TokenType::Eof].includes?(token.type)

          position += 1
        end
        position
      end

      # Attempt to recover a partial AST from errors
      def self.recover_partial_ast(_errors, partial_ast)
        # In a real implementation, this would use error patterns
        # to construct a best-effort AST
        partial_ast
      end

      # Suggest fixes for common errors
      def self.suggest_fix(error : Hash(Symbol, String | Int32 | WireGram::Core::TokenType))
        case error[:type]
        when "unexpected_token"
          "Expected #{error[:expected]}, but got #{error[:got]}"
        when "unknown_character"
          "Unknown character '#{error[:char]}' at position #{error[:position]}"
        else
          "Parse error at position #{error[:position]}"
        end
      end
    end
  end
end
