# typed: strong
module WireGram
  module Core
    class BaseLexer
      extend T::Sig

      sig { returns(String) }
      def source; end

      sig { returns(Integer) }
      def position; end

      sig { returns(T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]]) }
      def tokens; end

      sig { returns(T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Array[String])]]) }
      def errors; end

      sig { params(source: String).void }
      def initialize(source); end

      sig { void }
      def enable_streaming!; end

      sig { void }
      def disable_streaming!; end

      sig { returns(T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]]) }
      def tokenize; end

      sig { returns(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]) }
      def next_token; end

      sig { returns(T::Boolean) }
      def try_tokenize_next; end

      sig { returns(T.nilable(String)) }
      def current_char; end

      sig { params(offset: T.nilable(Integer)).returns(T.nilable(String)) }
      def peek_char(offset = nil); end

      sig { void }
      def advance; end

      sig { void }
      def skip_whitespace; end

      sig { params(type: Symbol, value: T.untyped, extras: T.nilable(T::Hash[Symbol, T.untyped])).returns(T.untyped) }
      def add_token(type, value = nil, extras = nil); end
    end
  end
end
