# Crystal Semantic Analyzer (Phase 3 of transpiler)
# Analyzes Crystal CST and extracts semantic information for transpilation
# Produces CrystalTranspileContext for use by RubyBuilder

module Warp
  module Lang
    module Crystal
      struct MethodInfo
        getter name : String
        getter params : Array(ParamInfo)
        getter return_type : String?
        getter body_start : Int32
        getter body_end : Int32
        getter source : String

        def initialize(@name, @params, @return_type, @body_start, @body_end, @source)
        end
      end

      struct ParamInfo
        getter name : String
        getter type : String?
        getter default_value : String?

        def initialize(@name, @type, @default_value = nil)
        end
      end

      struct ClassInfo
        getter name : String
        getter methods : Array(MethodInfo)
        getter body_start : Int32
        getter body_end : Int32
        getter source : String

        def initialize(@name, @methods, @body_start, @body_end, @source)
        end
      end

      struct CrystalTranspileContext
        property source : String
        getter methods : Hash(String, MethodInfo)
        getter classes : Hash(String, ClassInfo)
        getter diagnostics : Array(String)

        def initialize
          @methods = {} of String => MethodInfo
          @classes = {} of String => ClassInfo
          @source = ""
          @diagnostics = [] of String
        end

        def add_method(method : MethodInfo)
          @methods[method.name] = method
        end

        def add_class(klass : ClassInfo)
          @classes[klass.name] = klass
        end

        def add_diagnostic(msg : String)
          @diagnostics << msg
        end
      end

      class SemanticAnalyzer
        def initialize(@root : GreenNode, @source : String)
        end

        def analyze : CrystalTranspileContext
          context = CrystalTranspileContext.new
          context.source = @source
          visit(@root, context)
          context
        end

        private def visit(node : GreenNode, context : CrystalTranspileContext)
          case node.kind
          when NodeKind::Document
            visit_children(node, context)
          when NodeKind::MethodDef
            extract_method(node, context)
            visit_children(node, context)
          when NodeKind::ClassDef
            extract_class(node, context)
            visit_children(node, context)
          else
            visit_children(node, context)
          end
        end

        private def visit_children(node : GreenNode, context : CrystalTranspileContext)
          node.children.each do |child|
            visit(child, context)
          end
        end

        private def extract_method(node : GreenNode, context : CrystalTranspileContext)
          # Extract method name, parameters, and return type from MethodDef node
          name = extract_name_from_method(node)
          params = extract_params_from_method(node)
          return_type = extract_return_type_from_method(node)
          body_start = node.start
          body_end = node.end
          source_text = @source.byte_slice(node.start, node.end - node.start)

          method_info = MethodInfo.new(name, params, return_type, body_start, body_end, source_text)
          context.add_method(method_info)
        end

        private def extract_class(node : GreenNode, context : CrystalTranspileContext)
          # Extract class name and methods from ClassDef node
          name = extract_name_from_class(node)
          methods = extract_methods_from_class(node, context)
          body_start = node.start
          body_end = node.end
          source_text = @source.byte_slice(node.start, node.end - node.start)

          class_info = ClassInfo.new(name, methods, body_start, body_end, source_text)
          context.add_class(class_info)
        end

        private def extract_name_from_method(node : GreenNode) : String
          # Find the method name token/node
          node.children.each do |child|
            if child.is_a?(GreenNode) && child.kind == NodeKind::Identifier
              return @source.byte_slice(child.start, child.end - child.start)
            end
            if child.is_a?(GreenToken) && child.kind == TokenKind::Identifier
              return @source.byte_slice(child.start, child.end - child.start)
            end
          end
          "unknown"
        end

        private def extract_name_from_class(node : GreenNode) : String
          # Find the class name token/node
          node.children.each do |child|
            if child.is_a?(GreenNode) && child.kind == NodeKind::Identifier
              return @source.byte_slice(child.start, child.end - child.start)
            end
            if child.is_a?(GreenToken) && child.kind == TokenKind::Constant
              return @source.byte_slice(child.start, child.end - child.start)
            end
          end
          "Unknown"
        end

        private def extract_params_from_method(node : GreenNode) : Array(ParamInfo)
          params = [] of ParamInfo
          # Walk through the MethodDef node to find parameter list
          node.children.each do |child|
            if child.is_a?(GreenNode) && child.kind == NodeKind::ParameterList
              child.children.each do |param_node|
                if param_node.is_a?(GreenNode) && param_node.kind == NodeKind::Parameter
                  param_info = extract_single_param(param_node)
                  params << param_info if param_info
                end
              end
            end
          end
          params
        end

        private def extract_single_param(node : GreenNode) : ParamInfo?
          name = ""
          type = nil
          default_value = nil

          node.children.each do |child|
            if child.is_a?(GreenToken) && child.kind == TokenKind::Identifier
              name = @source.byte_slice(child.start, child.end - child.start)
            elsif child.is_a?(GreenNode) && child.kind == NodeKind::TypeAnnotation
              type = extract_type_annotation(child)
            elsif child.is_a?(GreenNode) && child.kind == NodeKind::Assignment
              default_value = @source.byte_slice(child.start, child.end - child.start)
            end
          end

          name.empty? ? nil : ParamInfo.new(name, type, default_value)
        end

        private def extract_return_type_from_method(node : GreenNode) : String?
          # Look for return type annotation in MethodDef
          node.children.each do |child|
            if child.is_a?(GreenNode) && child.kind == NodeKind::TypeAnnotation
              return extract_type_annotation(child)
            end
          end
          nil
        end

        private def extract_type_annotation(node : GreenNode) : String?
          @source.byte_slice(node.start, node.end - node.start)
        end

        private def extract_methods_from_class(node : GreenNode, context : CrystalTranspileContext) : Array(MethodInfo)
          methods = [] of MethodInfo
          # Recursively find MethodDef nodes within ClassDef
          node.children.each do |child|
            if child.is_a?(GreenNode)
              case child.kind
              when NodeKind::MethodDef
                extract_method(child, context)
                name = extract_name_from_method(child)
                if method_info = context.methods[name]?
                  methods << method_info
                end
              else
                nested_methods = extract_methods_from_class(child, context)
                methods.concat(nested_methods)
              end
            end
          end
          methods
        end
      end
    end
  end
end
