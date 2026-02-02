module Warp::Lang::Ruby
  # CST-to-CST transpiler (Phase 1 core)
  # Ruby Green/Red CST -> TranspileContext -> Crystal Green/Red CST -> emit
  class CSTToCSTTranspiler
    struct Result
      property output : String
      property error : Warp::Core::ErrorCode
      property diagnostics : Array(String)
      property crystal_doc : Warp::Lang::Crystal::CST::Document?

      def initialize(@output, @error, @diagnostics = [] of String, @crystal_doc = nil)
      end
    end

    def self.transpile(bytes : Bytes, annotations : Annotations::AnnotationStore? = nil) : Result
      # Step 1: Lex Ruby
      tokens, lex_error = Lexer.scan(bytes)
      return Result.new("", lex_error, ["lex error"], nil) unless lex_error == Warp::Core::ErrorCode::Success

      # Step 2: Parse Ruby CST
      ruby_root, parse_error = CST::Parser.parse(bytes, tokens)
      return Result.new("", parse_error, ["parse error"], nil) unless parse_error == Warp::Core::ErrorCode::Success
      return Result.new("", Warp::Core::ErrorCode::UnexpectedError, ["nil CST root"], nil) if ruby_root.nil?

      # Step 3: Semantic analysis (Ruby Red traversal)
      analyzer = SemanticAnalyzer.new(bytes, tokens, ruby_root, annotations || Annotations::AnnotationStore.new)
      context = analyzer.analyze

      # Step 4: Build Crystal CST (Green/Red)
      builder = Warp::Lang::Crystal::CSTBuilder.new
      crystal_doc = builder.build_from_context(context)

      # Step 5: Emit Crystal source
      output = Warp::Lang::Crystal::Serializer.emit(crystal_doc)

      # Step 6: Apply language-specific transformations (Ruby -> Crystal mappings)
      output = apply_ruby_to_crystal_mappings(output)

      Result.new(output, Warp::Core::ErrorCode::Success, context.diagnostics, crystal_doc)
    end

    private def self.apply_ruby_to_crystal_mappings(source : String) : String
      # Convert require_relative to require (Ruby -> Crystal)
      output = source.gsub(/require_relative\s+/, "require ")
      output
    end
  end
end
