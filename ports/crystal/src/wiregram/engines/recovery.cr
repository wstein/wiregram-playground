# frozen_string_literal: true

module WireGram
  module Engines
    # Recovery - Error recovery mechanisms for resilient parsing
    class Recovery
      # Recover from parse errors by finding synchronization points
      def self.synchronize_after_error(tokens, position)
        # Find next statement boundary or safe point
        while position < tokens.length
          token = tokens[position]
          return position if %i[semicolon newline eof].include?(token[:type])

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
      def self.suggest_fix(error)
        case error[:type]
        when :unexpected_token
          "Expected #{error[:expected]}, but got #{error[:got]}"
        when :unknown_character
          "Unknown character '#{error[:char]}' at position #{error[:position]}"
        else
          "Parse error at position #{error[:position]}"
        end
      end
    end
  end
end
