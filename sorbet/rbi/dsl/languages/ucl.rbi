# typed: strong
module WireGram
  module Languages
    module Ucl
      class Lexer < ::WireGram::Core::BaseLexer
        WHITESPACE_PATTERN = T.let(/.*/o, Regexp)
        IDENTIFIER_PATTERN = T.let(/.*/o, Regexp)
        URL_PATTERN = T.let(/.*/o, Regexp)
        HEX_PATTERN = T.let(/.*/o, Regexp)
        NUMBER_PATTERN = T.let(/.*/o, Regexp)
        INVALID_HEX_REMAIN = T.let(/.*/o, Regexp)
        FLAG_PATTERN = T.let(/.*/o, Regexp)
        DIRECTIVE_PATTERN = T.let(/.*/o, Regexp)
        QUOTED_STRING_PATTERN = T.let(/.*/o, Regexp)
        SINGLE_QUOTED_PATTERN = T.let(/.*/o, Regexp)
        STRUCTURAL_PATTERN = T.let(/.*/o, Regexp)
        KEYWORDS = T.let({}, T::Hash[String, T.nilable(T::Boolean)])
        STRUCTURAL_MAP = T.let({}, T::Hash[String, Symbol])

        extend T::Sig

        sig { params(source: String).void }
        def initialize(source); end

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
        def parse_object; end

        sig { returns(::WireGram::Core::Node) }
        def parse_array; end

        sig { returns(::WireGram::Core::Node) }
        def parse_value; end

        sig { returns(::WireGram::Core::Node) }
        def parse_pair; end
      end

      class Serializer
        extend T::Sig

        sig { params(node: ::WireGram::Core::Node, renumber: T.nilable(T::Boolean)).returns(String) }
        def self.serialize(node, renumber = nil); end

        sig { params(node: ::WireGram::Core::Node, renumber: T.nilable(T::Boolean)).returns(String) }
        def self.serialize_program(node, renumber = nil); end
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

      class Transformer
        extend T::Sig

        sig { params(ast: ::WireGram::Core::Node, transformation: T.nilable(Symbol)).returns(::WireGram::Core::Node) }
        def self.apply(ast, transformation = nil); end
      end
    end
  end
end
