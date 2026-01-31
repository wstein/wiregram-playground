module Warp::Lang::Crystal
  # Crystal CST builder (Phase 1 scaffold)
  class CSTBuilder
    def build_from_context(context : Warp::Lang::Ruby::TranspileContext) : CST::Document
      # Phase 1: no-op build that preserves original source as raw text.
      output = context.source
      bytes = output.to_slice

      raw = CST::GreenNode.new(CST::NodeKind::RawText, [] of CST::GreenNode, output)
      root = CST::GreenNode.new(CST::NodeKind::Root, [raw])

      CST::Document.new(bytes, CST::RedNode.new(root))
    end
  end
end
