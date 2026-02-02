module Warp::Lang::Ruby
  module Tape
    enum TapeType
      Root
      MethodDef
      ClassDef
      ModuleDef
      Call
      Block
      Identifier
      Literal
      Operator
      Parameter
      Trivia
      End
    end

    struct Entry
      getter type : TapeType
      getter trivia_start : Int32
      getter lexeme_start : Int32
      getter lexeme_end : Int32

      def initialize(@type : TapeType, @trivia_start : Int32, @lexeme_start : Int32, @lexeme_end : Int32)
      end
    end

    class Builder
      getter tape : Array(Entry)

      def initialize(@bytes : Bytes)
        @tape = [] of Entry
        @last_token_end = 0
      end

      def self.build(bytes : Bytes, root : CST::RedNode) : Array(Entry)
        builder = new(bytes)
        builder.build(root)
      end

      def build(root : CST::RedNode)
        @tape << Entry.new(TapeType::Root, 0, 0, 0)
        visit(root)
        @tape << Entry.new(TapeType::End, 0, 0, 0)
        @tape
      end

      private def visit(node : CST::RedNode)
        # Each node in CST that has a token should produce a tape entry
        type = map_kind_to_tape(node.kind)

        if tok = node.token
          trivia_start = @last_token_end
          lexeme_start = tok.start
          lexeme_end = tok.start + tok.length

          @tape << Entry.new(type, trivia_start, lexeme_start, lexeme_end)
          @last_token_end = lexeme_end
        end

        node.children.each do |child|
          visit(child)
        end
      end

      private def map_kind_to_tape(kind : CST::NodeKind) : TapeType
        case kind
        when CST::NodeKind::MethodDef                                                                 then TapeType::MethodDef
        when CST::NodeKind::ClassDef                                                                  then TapeType::ClassDef
        when CST::NodeKind::ModuleDef                                                                 then TapeType::ModuleDef
        when CST::NodeKind::MethodCall                                                                then TapeType::Call
        when CST::NodeKind::Block                                                                     then TapeType::Block
        when CST::NodeKind::Identifier                                                                then TapeType::Identifier
        when CST::NodeKind::StringLiteral, CST::NodeKind::NumberLiteral, CST::NodeKind::SymbolLiteral then TapeType::Literal
        when CST::NodeKind::BinaryOp, CST::NodeKind::UnaryOp                                          then TapeType::Operator
        when CST::NodeKind::Parameter                                                                 then TapeType::Parameter
        else                                                                                               TapeType::Trivia
        end
      end
    end
  end
end
