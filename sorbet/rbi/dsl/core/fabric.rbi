# typed: strong
module WireGram
  module Core
    class Fabric
      extend T::Sig

      sig { returns(String) }
      def source; end

      sig { returns(Node) }
      def ast; end

      sig { returns(T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]]) }
      def tokens; end

      sig { params(source: String, ast: Node, tokens: T.nilable(T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]])).void }
      def initialize(source, ast, tokens = nil); end

      sig { returns(String) }
      def to_source; end

      sig { params(pattern_type: Symbol).returns(T::Array[Node]) }
      def find_patterns(pattern_type); end

      sig { returns(WireGram::Engines::Analyzer) }
      def analyze; end

      sig { params(transformation: T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol)])).returns(WireGram::Engines::Transformer) }
      def transform(transformation = nil, &blk); end

      private

      sig { params(node: Node).returns(String) }
      def unweave(node); end
    end
  end
end
