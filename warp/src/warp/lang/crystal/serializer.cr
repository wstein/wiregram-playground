require "file_utils"

module Warp::Lang::Crystal
  class Serializer
    def self.emit(doc : CST::Document) : String
      builder = String::Builder.new
      write_node(builder, doc.root)
      builder.to_s
    end

    def self.emit_to_file(doc : CST::Document, path : String) : Nil
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, emit(doc))
    end

    private def self.write_node(io : String::Builder, node : CST::RedNode) : Nil
      case node.kind
      when CST::NodeKind::Root
        node.children.each do |child|
          write_node(io, child)
        end
      when CST::NodeKind::RawText
        io << (node.text || "")
      when CST::NodeKind::MethodDef
        payload = node.method_payload
        if payload
          io << build_method_header(payload)
          io << payload.body
        end
      end
    end

    private def self.build_method_header(payload : CST::MethodDefPayload) : String
      parts = payload.params.map do |param|
        param.type ? "#{param.name} : #{param.type}" : param.name
      end

      header = "def #{payload.name}"
      if payload.had_parens || parts.size > 0
        header += "(#{parts.join(", ")})"
      end
      header += " : #{payload.return_type}" if payload.return_type
      header + "\n"
    end
  end
end
