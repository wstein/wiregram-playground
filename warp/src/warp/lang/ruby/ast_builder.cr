module Warp::Lang::Ruby::AST
  class Builder
    def self.from_cst(node : CST::RedNode, bytes : Bytes? = nil) : Node
      kind = map_cst_to_ast(node.kind)
      value = nil

      if tok = node.token
        # Extract the text from the bytes if provided
        if bytes && tok.start + tok.length <= bytes.size
          value = String.new(bytes[tok.start, tok.length])
        end
      end

      children = node.children.map { |c| from_cst(c, bytes) }

      # For a real implementation, we'd pass the original bytes
      Node.new(kind, children, value, 0, 0)
    end

    private def self.map_cst_to_ast(kind : CST::NodeKind) : NodeKind
      # Simple mapping between CST and AST NodeKinds
      case kind
      when CST::NodeKind::Root       then NodeKind::Root
      when CST::NodeKind::MethodDef  then NodeKind::MethodDef
      when CST::NodeKind::MethodCall then NodeKind::Call
      else                                NodeKind::Identifier
      end
    end
  end
end
