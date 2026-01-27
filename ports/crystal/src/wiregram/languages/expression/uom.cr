# frozen_string_literal: true

require 'json'

module WireGram
  module Languages
    module Expression
      # Universal Object Model for Expression Language
      # Represents expressions in a normalized, language-agnostic format
      class UOM
        attr_accessor :root

        def initialize(root = nil)
          @root = root
        end

        def to_normalized_string
          return '' if @root.nil?

          @root.to_expression
        end

        def to_simple_json
          return nil if @root.nil?

          @root.to_simple_json
        end

        # Expression Value base class
        class Value
          attr_reader :type, :value

          def initialize(type, value)
            @type = type
            @value = value
            freeze
          end

          def to_expression
            case @type
            when :number
              @value.to_s
            when :string
              "\"#{@value}\""
            when :identifier
              @value.to_s
            when :boolean
              @value.to_s
            when :null
              'null'
            else
              @value.to_s
            end
          end

          def ==(other)
            other.is_a?(Value) && other.type == @type && other.value == @value
          end

          def inspect
            "#<#{self.class.name} type=#{@type} value=#{@value.inspect}>"
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return '...' if depth > max_depth

            indent = '  ' * depth
            case @type
            when :string
              "#{indent}#<Expression::UOM::Value type=:string value=\"#{@value}\">"
            when :number, :boolean, :null, :identifier
              "#{indent}#<Expression::UOM::Value type=#{@type} value=#{@value.inspect}>"
            else
              "#{indent}#<Expression::UOM::Value type=#{@type} value=#{@value.inspect}>"
            end
          end

          # Pretty-print UOM for snapshots
          def to_pretty_string(indent = 0)
            indent_str = '  ' * indent
            case @type
            when :string
              "#{indent_str}#<WireGram::Languages::Expression::UOM::Value:0xXXXXXXXX @type=:string, @value=\"#{@value}\">"
            when :number, :boolean, :null, :identifier
              "#{indent_str}#<WireGram::Languages::Expression::UOM::Value:0xXXXXXXXX @type=#{@type}, @value=#{@value.inspect}>"
            else
              "#{indent_str}#<WireGram::Languages::Expression::UOM::Value:0xXXXXXXXX @type=#{@type}, @value=#{@value.inspect}>"
            end
          end

          # Convert UOM value to JSON format
          def to_json_format
            {
              type: @type,
              value: @value
            }
          end

          # Simple JSON - just the value (keep for backward compatibility)
          def to_simple_json
            case @type
            when :string, :number, :boolean, :identifier
              @value
            when :null
              nil
            else
              @value
            end
          end

          # Snapshot-friendly hash (type => value)
          def to_snapshot_hash
            # In Lisp-like snapshot form, primitives are emitted directly
            to_simple_json
          end

          # Pretty JSON string for snapshots
          def to_json(*_args)
            JSON.pretty_generate(to_snapshot_hash, indent: '  ')
          end
        end

        # Number value
        class NumberValue < Value
          def initialize(value)
            super(:number, value)
          end
        end

        # String value
        class StringValue < Value
          def initialize(value)
            super(:string, value.to_s)
          end
        end

        # Identifier value
        class IdentifierValue < Value
          def initialize(value)
            super(:identifier, value.to_s)
          end
        end

        # Boolean value
        class BooleanValue < Value
          def initialize(value)
            super(:boolean, value ? true : false)
          end
        end

        # Null value
        class NullValue < Value
          def initialize
            super(:null, nil)
          end
        end

        # Binary operation (e.g., +, -, *, /, ==, !=, <, >, <=, >=, &&, ||)
        class BinaryOperation
          attr_reader :operator, :left, :right

          def initialize(operator, left, right)
            @operator = operator.to_sym
            @left = left
            @right = right
            freeze
          end

          def to_expression
            left_expr = @left.to_expression
            right_expr = @right.to_expression

            # Add parentheses for precedence if needed
            left_expr = "(#{left_expr})" if needs_parentheses?(@left, @operator)
            right_expr = "(#{right_expr})" if needs_parentheses?(@right, @operator, :right)

            "#{left_expr} #{@operator} #{right_expr}"
          end

          def to_simple_json
            {
              type: :binary_operation,
              operator: @operator,
              left: @left.to_simple_json,
              right: @right.to_simple_json
            }
          end

          def ==(other)
            other.is_a?(BinaryOperation) &&
              other.operator == @operator &&
              other.left == @left &&
              other.right == @right
          end

          def inspect
            "#<Expression::UOM::BinaryOperation operator=#{@operator} left=#{@left.inspect} right=#{@right.inspect}>"
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return '...' if depth > max_depth

            indent = '  ' * depth
            result = "#{indent}#<Expression::UOM::BinaryOperation operator=#{@operator}>"

            if @left
              result += "\n#{indent}  left:"
              result += "\n#{@left.to_detailed_string(depth + 2, max_depth)}"
            end

            if @right
              result += "\n#{indent}  right:"
              result += "\n#{@right.to_detailed_string(depth + 2, max_depth)}"
            end

            result
          end

          # Pretty-print UOM binary operation for snapshots
          def to_pretty_string(indent = 0)
            indent_str = '  ' * indent
            result = "#{indent_str}#<WireGram::Languages::Expression::UOM::BinaryOperation:0xXXXXXXXX @operator=#{@operator}>"

            result += "\n#{indent_str}  #<WireGram::Languages::Expression::UOM::Value:0xXXXXXXXX @type=#{@left.type}, @value=#{@left.value.inspect}>" if @left

            result += "\n#{indent_str}  #<WireGram::Languages::Expression::UOM::Value:0xXXXXXXXX @type=#{@right.type}, @value=#{@right.value.inspect}>" if @right

            result
          end

          # Convert UOM binary operation to JSON format
          def to_json_format
            {
              type: :binary_operation,
              operator: @operator,
              left: @left.to_json_format,
              right: @right.to_json_format
            }
          end

          # Simplified JSON format for snapshots
          # Snapshot-friendly hash
          def to_snapshot_hash
            [
              @operator.to_s,
              @left.to_snapshot_hash,
              @right.to_snapshot_hash
            ]
          end

          # Pretty JSON for snapshots - simplified format
          def to_json(*_args)
            JSON.pretty_generate(to_snapshot_hash, indent: '  ')
          end

          def needs_parentheses?(operand, operator, side = :left)
            return false unless operand.is_a?(BinaryOperation)

            # Define operator precedence (higher number = higher precedence)
            precedence = {
              :** => 10,
              :* => 8, :/   => 8, :% => 8,
              :+ => 6, :-   => 6,
              :== => 4, :!= => 4, :< => 4, :> => 4, :<= => 4, :>= => 4,
              :'&&' => 2, :'||' => 1
            }

            # Ensure operator is a symbol for lookup
            operator_sym = operator.is_a?(Symbol) ? operator : operator.to_sym
            current_prec = precedence[operator_sym] || 0
            operand_prec = precedence[operand.operator] || 0

            # For left side: add parentheses if operand has lower precedence
            # For right side: add parentheses if operand has lower or equal precedence (right-associative)
            if side == :left
              operand_prec < current_prec
            else
              operand_prec <= current_prec
            end
          end
        end

        # Unary operation (e.g., !, -)
        class UnaryOperation
          attr_reader :operator, :operand

          def initialize(operator, operand)
            @operator = operator.to_sym
            @operand = operand
            freeze
          end

          def to_expression
            operand_expr = @operand.to_expression
            operand_expr = "(#{operand_expr})" if @operand.is_a?(BinaryOperation)
            "#{@operator}#{operand_expr}"
          end

          def to_simple_json
            {
              type: :unary_operation,
              operator: @operator,
              operand: @operand.to_simple_json
            }
          end

          def ==(other)
            other.is_a?(UnaryOperation) &&
              other.operator == @operator &&
              other.operand == @operand
          end

          def inspect
            "#<Expression::UOM::UnaryOperation operator=#{@operator} operand=#{@operand.inspect}>"
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return '...' if depth > max_depth

            indent = '  ' * depth
            result = "#{indent}#<Expression::UOM::UnaryOperation operator=#{@operator}>"

            if @operand
              result += "\n#{indent}  operand:"
              result += "\n#{@operand.to_detailed_string(depth + 2, max_depth)}"
            end

            result
          end

          # Pretty-print UOM unary operation for snapshots
          def to_pretty_string(indent = 0)
            indent_str = '  ' * indent
            result = "#{indent_str}#<WireGram::Languages::Expression::UOM::UnaryOperation:0xXXXXXXXX @operator=#{@operator}>"

            result += "\n#{indent_str}  #<WireGram::Languages::Expression::UOM::Value:0xXXXXXXXX @type=#{@operand.type}, @value=#{@operand.value.inspect}>" if @operand

            result
          end

          # Convert UOM unary operation to JSON format
          def to_json_format
            {
              type: :unary_operation,
              operator: @operator,
              operand: @operand.to_json_format
            }
          end

          # Simplified JSON format for snapshots
          # Snapshot-friendly hash
          def to_snapshot_hash
            [
              @operator.to_s,
              @operand.to_snapshot_hash
            ]
          end

          # Pretty JSON for snapshots - simplified format
          def to_json(*_args)
            JSON.pretty_generate(to_snapshot_hash, indent: '  ')
          end
        end

        # Function call
        class FunctionCall
          attr_reader :name, :arguments

          def initialize(name, arguments = [])
            @name = name.to_s
            @arguments = arguments.freeze
            freeze
          end

          def to_expression
            args_expr = @arguments.map(&:to_expression).join(', ')
            "#{@name}(#{args_expr})"
          end

          def to_simple_json
            {
              type: :function_call,
              name: @name,
              arguments: @arguments.map(&:to_simple_json)
            }
          end

          def ==(other)
            other.is_a?(FunctionCall) &&
              other.name == @name &&
              other.arguments == @arguments
          end

          def inspect
            "#<Expression::UOM::FunctionCall name=#{@name} arguments=#{@arguments.inspect}>"
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return '...' if depth > max_depth

            indent = '  ' * depth
            result = "#{indent}#<Expression::UOM::FunctionCall name=#{@name}>"

            if @arguments.any?
              result += "\n#{indent}  arguments:"
              @arguments.each_with_index do |arg, index|
                result += "\n#{indent}    [#{index}]:"
                result += "\n#{arg.to_detailed_string(depth + 3, max_depth)}"
              end
            end

            result
          end

          # Pretty-print UOM function call for snapshots
          def to_pretty_string(indent = 0)
            indent_str = '  ' * indent
            result = "#{indent_str}#<WireGram::Languages::Expression::UOM::FunctionCall:0xXXXXXXXX @name=\"#{@name}\", @arguments=#{@arguments.length}>"

            if @arguments.any?
              @arguments.each_with_index do |arg, index|
                result += "\n#{indent_str}  [#{index}]"
                result += "\n#{arg.to_pretty_string(indent + 2)}"
              end
            end

            result
          end

          # Convert UOM function call to JSON format
          def to_json_format
            {
              type: :function_call,
              name: @name,
              arguments: @arguments.map(&:to_json_format)
            }
          end

          # Simplified JSON format for snapshots
          # Snapshot-friendly hash
          def to_snapshot_hash
            [
              'call',
              @name,
              *@arguments.map(&:to_snapshot_hash)
            ]
          end

          # Pretty JSON for snapshots - simplified format
          def to_json(*_args)
            JSON.pretty_generate(to_snapshot_hash, indent: '  ')
          end
        end

        # Assignment statement
        class Assignment
          attr_reader :variable, :value

          def initialize(variable, value)
            @variable = variable
            @value = value
            freeze
          end

          def to_expression
            "#{@variable.to_expression} = #{@value.to_expression}"
          end

          def to_simple_json
            {
              type: :assignment,
              variable: @variable.to_simple_json,
              value: @value.to_simple_json
            }
          end

          def ==(other)
            other.is_a?(Assignment) &&
              other.variable == @variable &&
              other.value == @value
          end

          def inspect
            "#<Expression::UOM::Assignment variable=#{@variable.inspect} value=#{@value.inspect}>"
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return '...' if depth > max_depth

            indent = '  ' * depth
            result = "#{indent}#<Expression::UOM::Assignment>"

            if @variable
              result += "\n#{indent}  variable:"
              result += "\n#{@variable.to_detailed_string(depth + 2, max_depth)}"
            end

            if @value
              result += "\n#{indent}  value:"
              result += "\n#{@value.to_detailed_string(depth + 2, max_depth)}"
            end

            result
          end

          # Pretty-print UOM assignment for snapshots
          def to_pretty_string(indent = 0)
            indent_str = '  ' * indent
            result = "#{indent_str}#<WireGram::Languages::Expression::UOM::Assignment:0xXXXXXXXX>"

            result += "\n#{indent_str}  #<WireGram::Languages::Expression::UOM::Value:0xXXXXXXXX @type=#{@variable.type}, @value=#{@variable.value.inspect}>" if @variable

            result += "\n#{indent_str}  #<WireGram::Languages::Expression::UOM::Value:0xXXXXXXXX @type=#{@value.type}, @value=#{@value.value.inspect}>" if @value

            result
          end

          # Convert UOM assignment to JSON format
          def to_json_format
            {
              type: :assignment,
              variable: @variable.to_json_format,
              value: @value.to_json_format
            }
          end

          # Simplified JSON format for snapshots
          # Snapshot-friendly hash
          def to_snapshot_hash
            [
              'assignment',
              @variable.to_snapshot_hash,
              @value.to_snapshot_hash
            ]
          end

          # Pretty JSON for snapshots
          def to_json(*_args)
            JSON.pretty_generate(to_snapshot_hash, indent: '  ')
          end
        end

        # Program (collection of statements)
        class Program
          attr_reader :statements

          def initialize(statements = [])
            @statements = statements.freeze
            freeze
          end

          def to_expression
            @statements.map(&:to_expression).join("\n")
          end

          def to_simple_json
            @statements.map(&:to_simple_json)
          end

          def to_snapshot_hash
            {
              'program' => {
                'statements' => @statements.map(&:to_snapshot_hash)
              }
            }
          end

          def ==(other)
            other.is_a?(Program) && other.statements == @statements
          end

          def inspect
            "#<Expression::UOM::Program statements=#{@statements.length}>"
          end

          # Deep serialization for snapshots - shows actual content
          def to_detailed_string(depth = 0, max_depth = 3)
            return '...' if depth > max_depth

            indent = '  ' * depth
            result = "#{indent}#<Expression::UOM::Program statements=#{@statements.length}>"

            if @statements.any?
              @statements.each_with_index do |stmt, index|
                result += "\n#{indent}  [#{index}]:"
                result += "\n#{stmt.to_detailed_string(depth + 2, max_depth)}"
              end
            end

            result
          end

          # Pretty-print UOM program for snapshots
          def to_pretty_string(indent = 0)
            indent_str = '  ' * indent
            result = "#{indent_str}#<WireGram::Languages::Expression::UOM::Program:0xXXXXXXXX @statements=#{@statements.length}>"

            if @statements.any?
              @statements.each_with_index do |stmt, index|
                result += "\n#{indent_str}  [#{index}]"
                result += "\n#{stmt.to_pretty_string(indent + 2)}"
              end
            end

            result
          end

          # Convert UOM program to JSON format
          def to_json_format
            {
              type: :program,
              statements: @statements.map(&:to_json_format)
            }
          end

          # Pretty JSON for snapshots
          def to_json(*_args)
            JSON.pretty_generate(to_snapshot_hash, indent: '  ')
          end
        end

        # Grouped expression to preserve parentheses
        class Group
          attr_reader :inner

          def initialize(inner)
            @inner = inner
            freeze
          end

          def to_expression
            "(#{@inner.to_expression})"
          end

          def to_simple_json
            { type: :group, value: @inner.to_simple_json }
          end

          def ==(other)
            other.is_a?(Group) && other.inner == @inner
          end

          def inspect
            "#<Expression::UOM::Group inner=#{@inner.inspect}>"
          end

          def to_detailed_string(depth = 0, max_depth = 3)
            return '...' if depth > max_depth

            indent = '  ' * depth
            result = "#{indent}#<Expression::UOM::Group>"
            result += "\n#{@inner.to_detailed_string(depth + 1, max_depth)}"
            result
          end

          def to_pretty_string(indent = 0)
            indent_str = '  ' * indent
            result = "#{indent_str}#<WireGram::Languages::Expression::UOM::Group:0xXXXXXXXX>"
            result += "\n#{@inner.to_pretty_string(indent + 1)}"
            result
          end

          def to_json_format
            { type: :group, value: @inner.to_json_format }
          end

          def to_snapshot_hash
            # Groups are structural only; emit the inner snapshot directly
            @inner.to_snapshot_hash
          end

          # Pretty JSON for snapshots
          def to_json(*_args)
            JSON.pretty_generate(to_snapshot_hash, indent: '  ')
          end
        end
      end
    end
  end
end
