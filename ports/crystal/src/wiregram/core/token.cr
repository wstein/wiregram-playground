# frozen_string_literal: true

module WireGram
  module Core
    enum TokenType
      Eof
      Unknown
      Plus
      Minus
      Star
      Slash
      Equals
      LParen
      RParen
      LBrace
      RBrace
      LBracket
      RBracket
      Colon
      Comma
      Semicolon
      String
      Number
      Boolean
      Null
      Identifier
      Keyword
      Directive
      InvalidHex
      HexNumber

      def self.from_symbol(sym : Symbol) : TokenType
        case sym
        when :eof then Eof
        when :unknown then Unknown
        when :plus then Plus
        when :minus then Minus
        when :star then Star
        when :slash then Slash
        when :equals then Equals
        when :lparen then LParen
        when :rparen then RParen
        when :lbrace then LBrace
        when :rbrace then RBrace
        when :lbracket then LBracket
        when :rbracket then RBracket
        when :colon then Colon
        when :comma then Comma
        when :semicolon then Semicolon
        when :string then String
        when :number then Number
        when :boolean then Boolean
        when :null then Null
        when :identifier then Identifier
        when :keyword then Keyword
        when :directive then Directive
        when :invalid_hex then InvalidHex
        when :hex_number then HexNumber
        else
          Unknown
        end
      end
    end

    alias TokenValue = String | Int64 | Float64 | Bool | Nil
    alias TokenExtraValue = String | Int64 | Float64 | Bool | Nil | Symbol

    struct Token
      getter type : TokenType
      getter value : TokenValue
      getter position : Int32
      getter extras : Hash(Symbol, TokenExtraValue)?

      def initialize(@type : TokenType, @value : TokenValue = nil, @position : Int32 = 0, @extras : Hash(Symbol, TokenExtraValue)? = nil)
      end

      def extra(key : Symbol) : TokenExtraValue?
        @extras.try(&.[key])
      end

      def extra?(key : Symbol) : Bool
        @extras.try(&.has_key?(key)) || false
      end

      def [](key : Symbol)
        case key
        when :type
          type_symbol
        when :value
          value
        when :position
          position
        else
          @extras.try(&.[key])
        end
      end

      def key?(key : Symbol) : Bool
        case key
        when :type, :value, :position
          true
        else
          @extras.try(&.has_key?(key)) || false
        end
      end

      def type_symbol : Symbol
        case type
        when TokenType::Eof then :eof
        when TokenType::Unknown then :unknown
        when TokenType::Plus then :plus
        when TokenType::Minus then :minus
        when TokenType::Star then :star
        when TokenType::Slash then :slash
        when TokenType::Equals then :equals
        when TokenType::LParen then :lparen
        when TokenType::RParen then :rparen
        when TokenType::LBrace then :lbrace
        when TokenType::RBrace then :rbrace
        when TokenType::LBracket then :lbracket
        when TokenType::RBracket then :rbracket
        when TokenType::Colon then :colon
        when TokenType::Comma then :comma
        when TokenType::Semicolon then :semicolon
        when TokenType::String then :string
        when TokenType::Number then :number
        when TokenType::Boolean then :boolean
        when TokenType::Null then :null
        when TokenType::Identifier then :identifier
        when TokenType::Keyword then :keyword
        when TokenType::Directive then :directive
        when TokenType::InvalidHex then :invalid_hex
        when TokenType::HexNumber then :hex_number
        else
          :unknown
        end
      end

      def to_json(builder : JSON::Builder)
        builder.object do
          builder.field "type", type_symbol.to_s
          builder.field "value", value
          builder.field "position", position
          if extras = @extras
            extras.each do |key, val|
              builder.field key.to_s, val
            end
          end
        end
      end

      def to_h
        result = {} of String => (TokenValue | TokenExtraValue | Int32)
        result["type"] = type_symbol.to_s
        result["value"] = value
        result["position"] = position
        if extras = @extras
          extras.each do |key, val|
            result[key.to_s] = val
          end
        end
        result
      end
    end
  end
end
