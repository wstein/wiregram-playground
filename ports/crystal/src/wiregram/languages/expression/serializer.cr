# frozen_string_literal: true

module WireGram
  module Languages
    module Expression
      # Serializer for Expression Language
      # Converts UOM back to normalized expression strings
      class Serializer
        def serialize(uom, options = {})
          return '' unless uom&.root

          @options = {
            pretty: false,
            indent_size: 2
          }.merge(options)

          serialize_node(uom.root)
        end

        def serialize_pretty(uom, indent_size = 2)
          serialize(uom, pretty: true, indent_size: indent_size)
        end

        def serialize_simple(uom)
          serialize(uom, pretty: false)
        end

        private

        def serialize_node(node)
          case node
          when UOM::Program
            serialize_program(node)
          when UOM::Assignment
            serialize_assignment(node)
          when UOM::BinaryOperation
            serialize_binary_operation(node)
          when UOM::UnaryOperation
            serialize_unary_operation(node)
          when UOM::FunctionCall
            serialize_function_call(node)
          when UOM::Group
            serialize_group(node)
          when UOM::Value
            serialize_value(node)
          else
            raise "Unknown UOM node type: #{node.class}"
          end
        end

        def serialize_group(group)
          inner = serialize_node(group.inner)
          "(#{inner})"
        end

        def serialize_program(program)
          statements = program.statements.map { |stmt| serialize_node(stmt) }
          statements.join("\n")
        end

        def serialize_assignment(assignment)
          "let #{serialize_node(assignment.variable)} = #{serialize_node(assignment.value)}"
        end

        def serialize_binary_operation(binary_op)
          left = serialize_node(binary_op.left)
          right = serialize_node(binary_op.right)

          # Add parentheses for precedence if needed using UOM logic
          left = "(#{left})" if binary_op.needs_parentheses?(binary_op.left, binary_op.operator)
          right = "(#{right})" if binary_op.needs_parentheses?(binary_op.right, binary_op.operator, :right)

          "#{left} #{binary_op.operator} #{right}"
        end

        def serialize_unary_operation(unary_op)
          operand = serialize_node(unary_op.operand)
          operand = "(#{operand})" if unary_op.operand.is_a?(UOM::BinaryOperation)
          "#{unary_op.operator}#{operand}"
        end

        def serialize_function_call(func_call)
          args = func_call.arguments.map { |arg| serialize_node(arg) }.join(', ')
          "#{func_call.name}(#{args})"
        end

        def serialize_value(value)
          value.to_expression
        end
      end
    end
  end
end
