module Warp::Lang::Crystal
  class Serializer
    def self.emit(doc : CST::Document) : String
      builder = String::Builder.new
      write_node(builder, doc.root)
      builder.to_s
    end

    private def self.write_node(io : String::Builder, node : CST::RedNode) : Nil
      case node.kind
      when CST::NodeKind::Root
        node.children.each do |child|
          write_node(io, child)
        end
      when CST::NodeKind::RawText
        io << (node.text || "")
      end
    end
  end
end
