# typed: strong
module WireGram
  module Core
    class Node
      extend T::Sig

      sig { returns(Symbol) }
      def type; end

      sig { returns(T.nilable(T.any(String, Integer, Symbol, T::Boolean))) }
      def value; end

      sig { returns(T::Array[Node]) }
      def children; end

      sig { returns(T::Hash[Symbol, T.any(String, Integer, Symbol)]) }
      def metadata; end

      sig { params(type: Symbol, value: T.nilable(T.any(String, Integer, Symbol, T::Boolean)), children: T.nilable(T::Array[Node]), metadata: T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol)])).void }
      def initialize(type, value: nil, children: nil, metadata: nil); end

      sig { params(type: T.nilable(Symbol), value: T.nilable(T.any(String, Integer, Symbol, T::Boolean)), children: T.nilable(T::Array[Node]), metadata: T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol)])).returns(Node) }
      def with(type: nil, value: nil, children: nil, metadata: nil); end

      sig { params(block: T.proc.params(node: Node).void).void }
      def traverse(&block); end

      sig { params(block: T.proc.returns(T::Boolean)).returns(T::Array[Node]) }
      def find_all(&block); end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def to_h; end

      sig { returns(String) }
      def inspect; end

      sig { params(depth: T.nilable(Integer), max_depth: T.nilable(Integer)).returns(String) }
      def to_detailed_string(depth = nil, max_depth = nil); end

      sig { returns(String) }
      def to_json; end
    end
  end
end
