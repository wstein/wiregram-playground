# typed: strong
module WireGram
  module Core
    class TokenStream
      extend T::Sig

      sig { params(lexer: BaseLexer).void }
      def initialize(lexer); end

      sig { params(index: Integer).returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
      def [](index); end

      sig { returns(Integer) }
      def length; end

      sig { returns(T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]]) }
      def tokens; end

      private

      sig { params(index: Integer).void }
      def ensure_filled(index); end

      sig { void }
      def ensure_all; end
    end

    class StreamingTokenStream
      extend T::Sig

      sig { params(lexer: BaseLexer, buffer_size: T.nilable(Integer)).void }
      def initialize(lexer, buffer_size = nil); end

      sig { params(index: Integer).returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
      def [](index); end

      sig { params(position: Integer).void }
      def consume_to(position); end

      sig { returns(T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])])) }
      def next; end
    end
  end
end
