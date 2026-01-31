module Warp::Lang::Ruby::Annotations
  class RbsGenerator
    def self.inline_comment(sig : SigInfo) : String
      params = build_param_list(sig)
      return_type = sig.is_void ? "void" : (sig.return_type || "untyped")
      "#{sig.def_indent}# @rbs (#{params}) -> #{return_type}".rstrip
    end

    def self.rbs_definition(sig : SigInfo) : String
      params = build_param_list(sig)
      return_type = sig.is_void ? "void" : (sig.return_type || "untyped")
      "def #{sig.method_name}: (#{params}) -> #{return_type}"
    end

    private def self.build_param_list(sig : SigInfo) : String
      return "" if sig.param_list.empty?
      sig.param_list.map do |name|
        type = sig.params[name]? || "untyped"
        if name.ends_with?(':')
          key = name[0...-1]
          "#{key}: #{type}"
        elsif name.starts_with?('&')
          "#{name[1..-1]}: untyped"
        else
          type
        end
      end.join(", ")
    end
  end
end
