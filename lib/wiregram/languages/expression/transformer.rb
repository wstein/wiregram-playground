# frozen_string_literal: true

require_relative 'uom'

module WireGram
  module Languages
    module Expression
      # Transformer for Expression Language
      # Converts AST nodes to UOM representation
      class Transformer
        def transform(ast)
          return nil unless ast

          case ast.type
          when :program
            transform_program(ast)
          when :assign
            transform_assignment(ast)
          when :add, :subtract, :multiply, :divide
            transform_binary_operation(ast)
          when :identifier
            transform_identifier(ast)
          when :number
            transform_number(ast)
          when :string
            transform_string(ast)
          when :group
            transform_group(ast)
          else
            raise "Unknown AST node type: #{ast.type}"
          end
        end

        def transform_group(ast)
          inner = transform(ast.children[0])
          UOM::Group.new(inner)
        end

        private

        def transform_program(ast)
          statements = ast.children.map { |child| transform(child) }.compact
          UOM::Program.new(statements)
        end

        def transform_assignment(ast)
          variable = transform(ast.children[0])
          value = transform(ast.children[1])
          UOM::Assignment.new(variable, value)
        end

        def transform_binary_operation(ast)
          left = transform(ast.children[0])
          right = transform(ast.children[1])

          operator = case ast.type
                     when :add then '+'
                     when :subtract then '-'
                     when :multiply then '*'
                     when :divide then '/'
                     else ast.type.to_s
                     end

          UOM::BinaryOperation.new(operator, left, right)
        end

        def transform_identifier(ast)
          UOM::IdentifierValue.new(ast.value)
        end

        def transform_number(ast)
          UOM::NumberValue.new(ast.value)
        end

        def transform_string(ast)
          UOM::StringValue.new(ast.value)
        end
      end
    end
  end
end
