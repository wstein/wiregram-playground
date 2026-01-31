module Warp::Lang::Ruby::Annotations
  # Stores method signatures collected from inline sigs, RBS, and RBI files.
  class AnnotationStore
    getter rbs_methods : Hash(String, RbsMethodSignature)
    getter rbi_methods : Hash(String, RbsMethodSignature)
    getter inline_rbs_methods : Hash(String, RbsMethodSignature)
    getter sig_methods : Hash(String, RbsMethodSignature)

    def initialize
      @rbs_methods = {} of String => RbsMethodSignature
      @rbi_methods = {} of String => RbsMethodSignature
      @inline_rbs_methods = {} of String => RbsMethodSignature
      @sig_methods = {} of String => RbsMethodSignature
    end

    def add_rbs(method_name : String, sig : RbsMethodSignature)
      @rbs_methods[method_name] = sig
    end

    def add_rbi(method_name : String, sig : RbsMethodSignature)
      @rbi_methods[method_name] = sig
    end

    def add_inline_rbs(method_name : String, sig : RbsMethodSignature)
      @inline_rbs_methods[method_name] = sig
    end

    def add_sig(method_name : String, sig : RbsMethodSignature)
      @sig_methods[method_name] = sig
    end

    # Priority: inline RBS > RBS file > RBI file > sig blocks
    def resolve(method_name : String) : RbsMethodSignature?
      @inline_rbs_methods[method_name]? || @rbs_methods[method_name]? || @rbi_methods[method_name]? || @sig_methods[method_name]?
    end
  end
end
