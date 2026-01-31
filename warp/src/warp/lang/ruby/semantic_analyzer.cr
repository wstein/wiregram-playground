module Warp::Lang::Ruby
  # SemanticAnalyzer walks the Ruby Red CST to build an immutable TranspileContext.
  # Phase 1: minimal extraction scaffold (no transformations yet).
  class SemanticAnalyzer
    @bytes : Bytes
    @tokens : Array(Token)
    @ruby_root : CST::GreenNode
    @annotations : Annotations::AnnotationStore

    def initialize(
      @bytes : Bytes,
      @tokens : Array(Token),
      @ruby_root : CST::GreenNode,
      @annotations : Annotations::AnnotationStore = Annotations::AnnotationStore.new,
    )
    end

    def analyze : TranspileContext
      red_root = CST::RedNode.new(@ruby_root)
      diagnostics = [] of String

      # Inline Sorbet sigs (from Ruby source)
      begin
        extractor = Annotations::AnnotationExtractor.new(@bytes, @tokens)
        extractor.extract.each do |sig_info|
          rbs_sig = Annotations::SorbetRbsParser.new(sig_info.sig_text).parse_sig
          @annotations.add_sig(sig_info.method_name, rbs_sig)
        end
      rescue e
        diagnostics << "sig extraction failed: #{e.message}"
      end

      # Inline RBS comments (from Ruby source)
      begin
        inline = Annotations::InlineRbsParser.new.parse(String.new(@bytes))
        inline.each do |name, sig|
          @annotations.add_inline_rbs(name, sig)
        end
      rescue e
        diagnostics << "inline rbs parse failed: #{e.message}"
      end

      TranspileContext.new(@bytes, @tokens, @ruby_root, red_root, diagnostics, @annotations)
    end
  end
end
