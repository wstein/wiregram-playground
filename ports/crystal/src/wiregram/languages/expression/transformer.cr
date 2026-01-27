# frozen_string_literal: true

require "./uom"

module WireGram
  module Languages
    module Expression
      # Transformer for Expression Language
      # Converts AST nodes to UOM representation
      class Transformer
        def transform(ast)
          return nil unless ast

          case ast.type
          when WireGram::Core::NodeType::Program
            transform_program(ast)
          when WireGram::Core::NodeType::Assign
            transform_assignment(ast)
          when WireGram::Core::NodeType::Add, WireGram::Core::NodeType::Subtract, WireGram::Core::NodeType::Multiply, WireGram::Core::NodeType::Divide
            transform_binary_operation(ast)
          when WireGram::Core::NodeType::Identifier
            transform_identifier(ast)
          when WireGram::Core::NodeType::Number
            transform_number(ast)
          when WireGram::Core::NodeType::String
            transform_string(ast)
          when WireGram::Core::NodeType::Group
            transform_group(ast)
          else
            raise "Unknown AST node type: #{ast.type}"
          end
        end

        def transform_group(ast)
          inner = transform(ast.children[0])
          return nil unless inner
          UOM::Group.new(inner)
        end

        private def transform_program(ast)
          statements = [] of WireGram::Languages::Expression::UOM::NodeBase
          ast.children.each do |child|
            transformed = transform(child)
            statements << transformed if transformed
          end
          UOM::Program.new(statements)
        end

        def transform_assignment(ast)
          variable = transform(ast.children[0])
          value = transform(ast.children[1])
          return nil unless variable && value
          UOM::Assignment.new(variable, value)
        end

        def transform_binary_operation(ast)
          left = transform(ast.children[0])
          right = transform(ast.children[1])
          return nil unless left && right

          operator = case ast.type
                     when WireGram::Core::NodeType::Add then "+"
                     when WireGram::Core::NodeType::Subtract then "-"
                     when WireGram::Core::NodeType::Multiply then "*"
                     when WireGram::Core::NodeType::Divide then "/"
                     else ast.type.to_s
                     end

          UOM::BinaryOperation.new(operator, left, right)
        end

        def transform_identifier(ast)
          UOM::IdentifierValue.new(ast.value.as(String))
        end

        def transform_number(ast)
          UOM::NumberValue.new(ast.value.as(Int64 | Float64))
        end

        def transform_string(ast)
          UOM::StringValue.new(ast.value.as(String))
        end
      end
    end
  end
end
