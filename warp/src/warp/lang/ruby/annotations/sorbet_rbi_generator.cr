module Warp::Lang::Ruby::Annotations
  class SorbetRbiGenerator
    def self.rbi_definition(sig : SigInfo) : String
      params = sig.param_list.join(", ")
      params = "" if params.nil?
      lines = [] of String
      lines << sig.sig_text.rstrip
      lines << "def #{sig.method_name}(#{params}); end".gsub("()", "")
      lines.join("\n")
    end
  end
end
