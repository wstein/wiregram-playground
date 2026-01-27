# frozen_string_literal: true

require "json"

module WireGram
  module Core
    enum NodeType
      Program
      Assign
      Add
      Subtract
      Multiply
      Divide
      Group
      Identifier
      Number
      String
      Boolean
      Null
      Object
      Pair
      Array
      Directive
      UclProgram
      HexNumber
    end

    alias NodeValue = String | Int64 | Float64 | Bool | Nil
    alias MetadataValue = String | Int64 | Float64 | Bool | Nil
    alias Metadata = Hash(Symbol, MetadataValue)

    struct DirectiveInfo
      getter name : String
      getter args : Hash(String, String | Bool | Int64 | Float64)?
      getter path : String?

      def initialize(@name : String, @args : Hash(String, String | Bool | Int64 | Float64)? = nil, @path : String? = nil)
      end
    end

    # Base AST node. Concrete subclasses provide typed fields while still exposing
    # a Ruby-like shape (type/value/children) for minimal porting friction.
    abstract class Node
      abstract def type : NodeType

      def value : NodeValue | DirectiveInfo | Nil
        nil
      end

      def children : Array(Node)
        [] of Node
      end

      def metadata : Metadata?
        nil
      end

      def with(type : NodeType = self.type, value = self.value, children = self.children, metadata = self.metadata) : Node
        Node.new(type, value: value, children: children, metadata: metadata)
      end

      def traverse(&block : Node ->)
        block.call(self)
        children.each { |child| child.traverse { |n| yield n } }
      end

      def find_all(&block : Node -> Bool) : Array(Node)
        results = [] of Node
        traverse do |node|
          results << node if yield node
        end
        results
      end

      def to_h : Hash(String, JSON::Any)
        hash = {} of String => JSON::Any
        hash["type"] = JSON::Any.new(type_name)
        hash["value"] = json_any(value)
        child_any = children.map { |child| JSON::Any.new(child.to_h) }
        hash["children"] = JSON::Any.new(child_any)

        md_hash = {} of String => JSON::Any
        (metadata || {} of Symbol => MetadataValue).each do |key, val|
          next if key == :raw
          md_hash[key.to_s] = json_any(val)
        end
        hash["metadata"] = JSON::Any.new(md_hash)
        hash
      end

      def inspect : String
        "#<Node type=#{type_name} value=#{value.inspect} children=#{children.size}>"
      end

      # Deep serialization for snapshots - shows actual content with depth limiting
      def to_detailed_string(depth = 0, max_depth = 3) : String
        return "..." if depth > max_depth

        indent = "  " * depth
        result = "#{indent}#<Node type=#{type_name}"
        result += " value=#{value.inspect}" if value

        if children.any?
          result += " children=#{children.size}>"
          children.each do |child|
            result += "\n#{child.to_detailed_string(depth + 1, max_depth)}"
          end
        else
          result += ">"
        end

        result
      end

      def to_json(builder : JSON::Builder)
        to_h.to_json(builder)
      end

      def to_json : String
        JSON.build(indent: "  ") do |json|
          to_h.to_json(json)
        end
      end

      def self.new(type : NodeType | Symbol, value : NodeValue | DirectiveInfo | Nil = nil, children : Array(Node)? = nil, metadata : Metadata? = nil) : Node
        resolved = type.is_a?(Symbol) ? symbol_to_type(type) : type
        build(resolved, value, children, metadata)
      end

      private def self.build(type : NodeType, value : NodeValue | DirectiveInfo | Nil, children : Array(Node)?, metadata : Metadata?) : Node
        case type
        when NodeType::Program
          ProgramNode.new(children || [] of Node)
        when NodeType::Assign
          AssignNode.new(children || [] of Node)
        when NodeType::Add, NodeType::Subtract, NodeType::Multiply, NodeType::Divide
          BinaryNode.new(type, children || [] of Node)
        when NodeType::Group
          GroupNode.new(children || [] of Node)
        when NodeType::Identifier
          name = value.as?(String)
          raise "Identifier node requires a String value" unless name
          IdentifierNode.new(name)
        when NodeType::Number
          NumberNode.new(value, metadata)
        when NodeType::String
          text = value.as?(String)
          raise "String node requires a String value" unless text
          StringNode.new(text, metadata)
        when NodeType::Boolean
          unless value.is_a?(Bool)
            raise "Boolean node requires a Bool value"
          end
          BooleanNode.new(value)
        when NodeType::Null
          NullNode.new
        when NodeType::Object
          ObjectNode.new(children || [] of Node)
        when NodeType::Pair
          PairNode.new(children || [] of Node)
        when NodeType::Array
          ArrayNode.new(children || [] of Node)
        when NodeType::Directive
          info = value.as?(DirectiveInfo)
          raise "Directive node requires DirectiveInfo" unless info
          DirectiveNode.new(info)
        when NodeType::UclProgram
          UclProgramNode.new(children || [] of Node)
        when NodeType::HexNumber
          literal = value.as?(String)
          raise "HexNumber node requires a String value" unless literal
          HexNumberNode.new(literal)
        else
          raise "Unknown node type: #{type}"
        end
      end

      private def type_name : String
        case type
        when NodeType::Program then "program"
        when NodeType::Assign then "assign"
        when NodeType::Add then "add"
        when NodeType::Subtract then "subtract"
        when NodeType::Multiply then "multiply"
        when NodeType::Divide then "divide"
        when NodeType::Group then "group"
        when NodeType::Identifier then "identifier"
        when NodeType::Number then "number"
        when NodeType::String then "string"
        when NodeType::Boolean then "boolean"
        when NodeType::Null then "null"
        when NodeType::Object then "object"
        when NodeType::Pair then "pair"
        when NodeType::Array then "array"
        when NodeType::Directive then "directive"
        when NodeType::UclProgram then "ucl_program"
        when NodeType::HexNumber then "hex_number"
        else
          type.to_s.downcase
        end
      end

      private def self.symbol_to_type(sym : Symbol) : NodeType
        case sym
        when :program then NodeType::Program
        when :assign then NodeType::Assign
        when :add then NodeType::Add
        when :subtract then NodeType::Subtract
        when :multiply then NodeType::Multiply
        when :divide then NodeType::Divide
        when :group then NodeType::Group
        when :identifier then NodeType::Identifier
        when :number then NodeType::Number
        when :string then NodeType::String
        when :boolean then NodeType::Boolean
        when :null then NodeType::Null
        when :object then NodeType::Object
        when :pair then NodeType::Pair
        when :array then NodeType::Array
        when :directive then NodeType::Directive
        when :ucl_program then NodeType::UclProgram
        when :hex_number then NodeType::HexNumber
        else
          raise "Unknown node symbol: #{sym}"
        end
      end

      private def json_any(val)
        case val
        when Nil
          JSON::Any.new(nil)
        when Float64
          if val.infinite?
            JSON::Any.new(val.positive? ? "Infinity" : "-Infinity")
          else
            JSON::Any.new(val)
          end
        when NodeValue
          JSON::Any.new(val)
        when DirectiveInfo
          args_hash = {} of String => JSON::Any
          if (args = val.args)
            args.each do |key, item|
              args_hash[key] = JSON::Any.new(item)
            end
          end
          JSON::Any.new({
            "name" => JSON::Any.new(val.name),
            "args" => JSON::Any.new(args_hash),
            "path" => JSON::Any.new(val.path)
          })
        else
          JSON::Any.new(val.to_s)
        end
      end
    end

    class ProgramNode < Node
      getter statements : Array(Node)
      def initialize(@statements : Array(Node))
      end
      def type : NodeType
        NodeType::Program
      end
      def children : Array(Node)
        @statements
      end
    end

    class UclProgramNode < Node
      getter items : Array(Node)
      def initialize(@items : Array(Node))
      end
      def type : NodeType
        NodeType::UclProgram
      end
      def children : Array(Node)
        @items
      end
    end

    class AssignNode < Node
      getter identifier : Node
      getter expression : Node
      def initialize(children : Array(Node))
        @identifier = children[0]
        @expression = children[1]
      end
      def type : NodeType
        NodeType::Assign
      end
      def children : Array(Node)
        [@identifier, @expression]
      end
    end

    class BinaryNode < Node
      getter operator_type : NodeType
      getter left : Node
      getter right : Node
      def initialize(@operator_type : NodeType, children : Array(Node))
        @left = children[0]
        @right = children[1]
      end
      def type : NodeType
        @operator_type
      end
      def children : Array(Node)
        [@left, @right]
      end
    end

    class GroupNode < Node
      getter inner : Node
      def initialize(children : Array(Node))
        @inner = children[0]
      end
      def type : NodeType
        NodeType::Group
      end
      def children : Array(Node)
        [@inner]
      end
    end

    class IdentifierNode < Node
      getter name : String
      def initialize(@name : String)
      end
      def type : NodeType
        NodeType::Identifier
      end
      def value
        @name
      end
    end

    class NumberNode < Node
      getter number : NodeValue
      getter meta : Metadata?
      def initialize(value, metadata = nil)
        raw = metadata && metadata[:raw]? == true
        @number = case value
                  when Float64
                    value
                  when Float32
                    value.to_f64
                  when Int32
                    value.to_i64
                  when Int64
                    value
                  when String
                    if raw
                      value
                    else
                      value.includes?(".") || value.includes?("e") || value.includes?("E") ? value.to_f64 : value.to_i64
                    end
                  else
                    value.to_s.to_i64
                  end
        @meta = metadata
      end
      def type : NodeType
        NodeType::Number
      end
      def value
        @number
      end
      def metadata : Metadata?
        @meta
      end
    end

    class StringNode < Node
      getter text : String
      getter meta : Metadata?
      def initialize(value : String, metadata = nil)
        @text = value
        @meta = metadata
      end
      def type : NodeType
        NodeType::String
      end
      def value
        @text
      end
      def metadata : Metadata?
        @meta
      end
    end

    class BooleanNode < Node
      getter flag : Bool
      def initialize(@flag : Bool)
      end
      def type : NodeType
        NodeType::Boolean
      end
      def value
        @flag
      end
    end

    class NullNode < Node
      def type : NodeType
        NodeType::Null
      end
    end

    class HexNumberNode < Node
      getter literal : String
      def initialize(@literal : String)
      end
      def type : NodeType
        NodeType::HexNumber
      end
      def value
        @literal
      end
    end

    class ObjectNode < Node
      getter pairs : Array(Node)
      def initialize(@pairs : Array(Node))
      end
      def type : NodeType
        NodeType::Object
      end
      def children : Array(Node)
        @pairs
      end
    end

    class PairNode < Node
      getter key : Node
      getter value_node : Node
      def initialize(children : Array(Node))
        @key = children[0]
        @value_node = children[1]
      end
      def type : NodeType
        NodeType::Pair
      end
      def children : Array(Node)
        [@key, @value_node]
      end
    end

    class ArrayNode < Node
      getter items : Array(Node)
      def initialize(@items : Array(Node))
      end
      def type : NodeType
        NodeType::Array
      end
      def children : Array(Node)
        @items
      end
    end

    class DirectiveNode < Node
      getter info : DirectiveInfo
      def initialize(@info : DirectiveInfo)
      end
      def type : NodeType
        NodeType::Directive
      end
      def value
        @info
      end
    end
  end
end
