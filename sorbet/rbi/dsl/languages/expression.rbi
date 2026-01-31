# typed: strong
module WireGram
  module Languages
    module Expression
      class Lexer < ::WireGram::Core::BaseLexer
        extend T::Sig

        sig { params(source: String).void }
        def initialize(source); end

        sig { returns(T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]) }
        def next_token; end

        sig { returns(T::Boolean) }
        def try_tokenize_next; end
      end

      class Parser < ::WireGram::Core::BaseParser
        extend T::Sig

        sig { params(tokens: T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]]).void }
        def initialize(tokens); end

        sig { returns(::WireGram::Core::Node) }
        def parse; end

        sig { returns(::WireGram::Core::Node) }
        def parse_term; end

        sig { returns(::WireGram::Core::Node) }
        def parse_factor; end
      end

      class Serializer
        extend T::Sig

        sig { params(node: ::WireGram::Core::Node).returns(String) }
        def self.serialize(node); end
      end

      class Uom
        extend T::Sig

        sig { params(source: String).returns(::WireGram::Core::Fabric) }
        def self.process(source); end

        sig { params(source: String).returns(T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]]) }
        def self.tokenize(source); end

        sig { params(tokens: T::Array[T::Hash[Symbol, T.any(String, Integer, Symbol, T::Boolean, NilClass, T::Array[T.any(String, Integer)])]]).returns(::WireGram::Core::Node) }
        def self.parse(tokens); end

        sig { params(source: String, transformation: T.nilable(T::Hash[Symbol, T.any(String, Integer, Symbol)])).returns(::WireGram::Core::Fabric) }
        def self.transform(source, transformation = nil); end

        sig { params(node: ::WireGram::Core::Node).returns(String) }
        def self.serialize(node); end
      end
    end
  end
end
