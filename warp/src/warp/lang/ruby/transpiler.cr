# Ruby -> Crystal transpiler (Phase 2 core)

module Warp
  module Lang
    module Ruby
      module CrystalAst
        enum Kind
          Program
          Def
          Class
          Module
          Call
          Block
          Return
          If
          Unless
          While
          Literal
          Identifier
          Assignment
          Array
          Hash
          Binary
          Opaque
        end

        struct Node
          getter kind : Kind
          getter children : Array(Node)
          getter value : String?
          getter meta : Hash(String, String)?

          def initialize(
            @kind : Kind,
            @children : Array(Node) = [] of Node,
            @value : String? = nil,
            @meta : Hash(String, String)? = nil,
          )
          end
        end

        class Renderer
          def render(node : Node, indent : Int32 = 0) : String
            case node.kind
            when Kind::Program
              node.children.map { |c| render(c, indent) }.reject(&.empty?).join("\n")
            when Kind::Class
              name = node.value || "Anonymous"
              body = render_block(node.children, indent + 2)
              "#{indent_str(indent)}class #{name}\n#{body}\n#{indent_str(indent)}end"
            when Kind::Module
              name = node.value || "Anonymous"
              body = render_block(node.children, indent + 2)
              "#{indent_str(indent)}module #{name}\n#{body}\n#{indent_str(indent)}end"
            when Kind::Def
              name = node.value || "anonymous"
              params = extract_params(node.children)
              body_nodes = extract_body(node.children)
              return_type = node.meta ? node.meta.not_nil!["return_type"]? : nil
              signature = if params.empty?
                            return_type ? "def #{name} : #{return_type}" : "def #{name}"
                          else
                            return_type ? "def #{name}(#{params}) : #{return_type}" : "def #{name}(#{params})"
                          end
              body = render_block(body_nodes, indent + 2)
              "#{indent_str(indent)}#{signature}\n#{body}\n#{indent_str(indent)}end"
            when Kind::Call
              render_call(node, indent)
            when Kind::Block
              render_block_node(node, indent)
            when Kind::Return
              expr = node.children.first?
              expr_str = expr ? render(expr, indent) : ""
              "#{indent_str(indent)}return #{expr_str}".rstrip
            when Kind::If
              cond = node.children[0]?
              then_block = node.children[1]?
              else_block = node.children[2]?
              cond_str = cond ? render(cond, 0) : "true"
              then_str = then_block ? render_block(then_block.children, indent + 2) : ""
              else_str = else_block ? "\n#{indent_str(indent)}else\n#{render_block(else_block.children, indent + 2)}" : ""
              "#{indent_str(indent)}if #{cond_str}\n#{then_str}#{else_str}\n#{indent_str(indent)}end"
            when Kind::Unless
              cond = node.children[0]?
              body = node.children[1]?
              cond_str = cond ? render(cond, 0) : "false"
              body_str = body ? render_block(body.children, indent + 2) : ""
              "#{indent_str(indent)}unless #{cond_str}\n#{body_str}\n#{indent_str(indent)}end"
            when Kind::While
              cond = node.children[0]?
              body = node.children[1]?
              cond_str = cond ? render(cond, 0) : "true"
              body_str = body ? render_block(body.children, indent + 2) : ""
              "#{indent_str(indent)}while #{cond_str}\n#{body_str}\n#{indent_str(indent)}end"
            when Kind::Identifier
              node.value.to_s
            when Kind::Literal
              node.value.to_s
            when Kind::Assignment
              left = node.children[0]?
              right = node.children[1]?
              left_str = left ? render(left, 0) : ""
              right_str = right ? render(right, 0) : ""
              "#{indent_str(indent)}#{left_str} = #{right_str}"
            when Kind::Array
              elements = node.children.map { |c| render(c, 0) }.join(", ")
              "[#{elements}]"
            when Kind::Hash
              pairs = node.children.map { |c| render(c, 0) }.join(", ")
              "{#{pairs}}"
            when Kind::Binary
              left = node.children[0]?
              right = node.children[1]?
              op = node.value || "+"
              left_str = left ? render(left, 0) : ""
              right_str = right ? render(right, 0) : ""
              "#{left_str} #{op} #{right_str}"
            when Kind::Opaque
              "#{indent_str(indent)}# WARP_OPAQUE: #{node.value || "unhandled"}"
            else
              ""
            end
          end

          private def render_call(node : Node, indent : Int32) : String
            receiver_flag = node.meta ? node.meta.not_nil!["receiver"]? : nil
            block_flag = node.meta ? node.meta.not_nil!["block"]? : nil

            children = node.children.dup
            block_node = nil
            if block_flag == "true"
              block_node = children.pop?
            end

            receiver = nil
            if receiver_flag == "true" && children.size > 0
              receiver = children.shift?
            end

            args = children.map { |c| render(c, 0) }.join(", ")
            name = node.value || (receiver ? "call" : "call")
            call_head = receiver ? "#{render(receiver, 0)}.#{name}" : name
            call_str = args.empty? ? call_head : "#{call_head}(#{args})"

            if block_node
              block_str = render(block_node, indent)
              "#{indent_str(indent)}#{call_str} #{block_str}".rstrip
            else
              "#{indent_str(indent)}#{call_str}".rstrip
            end
          end

          private def render_block_node(node : Node, indent : Int32) : String
            params_node = node.children[0]?
            body_node = node.children[1]?
            params = params_node ? params_node.children.map { |c| render(c, 0) }.join(", ") : ""
            body = body_node ? render_block(body_node.children, indent + 2) : ""
            "do |#{params}|\n#{body}\n#{indent_str(indent)}end"
          end

          private def render_block(nodes : Array(Node), indent : Int32) : String
            return "#{indent_str(indent)}# empty" if nodes.empty?
            nodes.map { |c| "#{indent_str(indent)}#{render(c, indent)}" }.join("\n")
          end

          private def extract_params(children : Array(Node)) : String
            return "" if children.empty?
            params = children[0]? ? children[0].children : [] of Node
            params.map { |c| render(c, 0) }.join(", ")
          end

          private def extract_body(children : Array(Node)) : Array(Node)
            body = children[1]?
            body ? body.children : [] of Node
          end

          private def indent_str(indent : Int32) : String
            " " * indent
          end
        end
      end

      enum TypeKind
        Unknown
        Nil
        Bool
        Int
        Float
        String
        Regex
      end

      class TypeInferencer
        def infer(node : IR::Node) : TypeKind
          case node.kind
          when IR::Kind::Literal
            lit_kind = node.meta ? node.meta.not_nil!["literal_kind"]? : nil
            case lit_kind
            when "Nil"     then TypeKind::Nil
            when "Boolean" then TypeKind::Bool
            when "Number"  then TypeKind::Int
            when "Float"   then TypeKind::Float
            when "String"  then TypeKind::String
            when "Regex"   then TypeKind::Regex
            else
              TypeKind::Unknown
            end
          else
            TypeKind::Unknown
          end
        end
      end

      class Lowering
        def self.to_crystal(node : IR::Node) : CrystalAst::Node
          case node.kind
          when IR::Kind::Program
            CrystalAst::Node.new(CrystalAst::Kind::Program, node.children.map { |c| to_crystal(c) })
          when IR::Kind::Def
            meta = node.meta ? node.meta.dup : {} of String => String
            CrystalAst::Node.new(CrystalAst::Kind::Def, node.children.map { |c| to_crystal(c) }, node.value, meta)
          when IR::Kind::Class
            CrystalAst::Node.new(CrystalAst::Kind::Class, node.children.map { |c| to_crystal(c) }, node.value)
          when IR::Kind::Module
            CrystalAst::Node.new(CrystalAst::Kind::Module, node.children.map { |c| to_crystal(c) }, node.value)
          when IR::Kind::Call
            CrystalAst::Node.new(CrystalAst::Kind::Call, node.children.map { |c| to_crystal(c) }, node.value, node.meta)
          when IR::Kind::Block
            CrystalAst::Node.new(CrystalAst::Kind::Block, node.children.map { |c| to_crystal(c) }, node.value, node.meta)
          when IR::Kind::Return
            CrystalAst::Node.new(CrystalAst::Kind::Return, node.children.map { |c| to_crystal(c) }, node.value)
          when IR::Kind::If
            CrystalAst::Node.new(CrystalAst::Kind::If, node.children.map { |c| to_crystal(c) }, node.value)
          when IR::Kind::Unless
            CrystalAst::Node.new(CrystalAst::Kind::Unless, node.children.map { |c| to_crystal(c) }, node.value)
          when IR::Kind::While
            CrystalAst::Node.new(CrystalAst::Kind::While, node.children.map { |c| to_crystal(c) }, node.value)
          when IR::Kind::Identifier
            CrystalAst::Node.new(CrystalAst::Kind::Identifier, [] of CrystalAst::Node, node.value)
          when IR::Kind::Literal
            CrystalAst::Node.new(CrystalAst::Kind::Literal, [] of CrystalAst::Node, node.value, node.meta)
          when IR::Kind::Assignment
            CrystalAst::Node.new(CrystalAst::Kind::Assignment, node.children.map { |c| to_crystal(c) }, node.value)
          when IR::Kind::Array
            CrystalAst::Node.new(CrystalAst::Kind::Array, node.children.map { |c| to_crystal(c) }, node.value)
          when IR::Kind::Hash
            CrystalAst::Node.new(CrystalAst::Kind::Hash, node.children.map { |c| to_crystal(c) }, node.value)
          when IR::Kind::Binary
            CrystalAst::Node.new(CrystalAst::Kind::Binary, node.children.map { |c| to_crystal(c) }, node.value)
          else
            CrystalAst::Node.new(CrystalAst::Kind::Opaque, node.children.map { |c| to_crystal(c) }, node.value)
          end
        end
      end

      struct TranspileResult
        getter output : String
        getter diagnostics : Array(String)
        getter error : ErrorCode

        def initialize(@output : String, @diagnostics : Array(String), @error : ErrorCode)
        end
      end

      class Transpiler
        def self.transpile(bytes : Bytes) : TranspileResult
          ast_result = Parser.parse(bytes)
          return TranspileResult.new("", ["parser error"], ast_result.error) unless ast_result.error.success?

          ast = ast_result.node.not_nil!
          ir = IR::Builder.from_ast(ast)
          diagnostics = [] of String

          inferencer = TypeInferencer.new
          if ir.kind == IR::Kind::Program
            ir.children.each do |child|
              if child.kind == IR::Kind::Def
                type = infer_method_return(child, inferencer)
                if type
                  child.meta = child.meta || {} of String => String
                  child.meta.not_nil!["return_type"] = type
                end
              end
            end
          end

          crystal_ast = Lowering.to_crystal(ir)
          renderer = CrystalAst::Renderer.new
          output = renderer.render(crystal_ast)
          TranspileResult.new(output, diagnostics, ErrorCode::Success)
        end

        def self.transpile_source(source : String) : TranspileResult
          transpile(source.to_slice)
        end

        private def self.infer_method_return(def_node : IR::Node, inferencer : TypeInferencer) : String?
          body = def_node.children[1]? || def_node.children.last?
          return nil unless body
          last_expr = body.children.last?
          return nil unless last_expr
          type = inferencer.infer(last_expr)
          case type
          when TypeKind::Int
            "Int32"
          when TypeKind::Float
            "Float64"
          when TypeKind::String
            "String"
          when TypeKind::Bool
            "Bool"
          when TypeKind::Nil
            "Nil"
          when TypeKind::Regex
            "Regex"
          else
            nil
          end
        end
      end
    end
  end
end
