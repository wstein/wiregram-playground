# typed: strong
module WireGram
  module Core
    class BaseParser
      extend T::Sig

      sig { params(tokens: T.any(TokenStream, T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]])).void }
      def initialize(tokens); end

      sig { returns(T.any(TokenStream, T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]])) }
      def tokens; end

      sig { returns(Integer) }
      def position; end

      sig { returns(T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Array[String])]]) }
      def errors; end

      sig { returns(T.nilable(Node)) }
      def parse; end

      sig { returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
      def current_token; end

      sig { params(offset: T.nilable(Integer)).returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
      def peek_token(offset = nil); end

      sig { void }
      def advance; end

      sig { params(type: Symbol).returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
      def expect(type); end

      sig { returns(T::Boolean) }
      def at_end?; end

      sig { void }
      def synchronize; end
    end
  end
end
