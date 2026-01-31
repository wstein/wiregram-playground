module Warp::Lang::Ruby
  struct TranspileContext
    getter bytes : Bytes
    getter tokens : Array(Token)
    getter ruby_root : CST::GreenNode
    getter ruby_red_root : CST::RedNode
    getter diagnostics : Array(String)
    getter annotations : Annotations::AnnotationStore

    def initialize(
      @bytes : Bytes,
      @tokens : Array(Token),
      @ruby_root : CST::GreenNode,
      @ruby_red_root : CST::RedNode,
      @diagnostics : Array(String) = [] of String,
      @annotations : Annotations::AnnotationStore = Annotations::AnnotationStore.new,
    )
    end

    def source : String
      String.new(@bytes)
    end
  end
end
