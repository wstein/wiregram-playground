module Warp::Lang::Ruby::Annotations
  # Parses RBI files (Ruby with Sorbet sigs) to method signatures.
  class RbiFileParser
    def parse(source : String) : Hash(String, RbsMethodSignature)
      bytes = source.to_slice
      tokens, err = Warp::Lang::Ruby::Lexer.scan(bytes)
      return {} of String => RbsMethodSignature unless err == Warp::Core::ErrorCode::Success

      extractor = AnnotationExtractor.new(bytes, tokens)
      sigs = extractor.extract

      signatures = {} of String => RbsMethodSignature
      sigs.each do |sig_info|
        parser = SorbetRbsParser.new(sig_info.sig_text)
        rbs_sig = parser.parse_sig
        signatures[sig_info.method_name] = rbs_sig
      end
      signatures
    end
  end
end
