module Warp
  module CST
    class Parser
      alias ErrorCode = Core::ErrorCode
      alias TokenKind = CST::TokenKind

      class Stream
        getter tokens : Array(Token)
        getter index : Int32
        getter jsonc : Bool

        def initialize(@tokens : Array(Token), @jsonc : Bool)
          @index = 0
        end

        def at_eof? : Bool
          peek.kind == TokenKind::Eof
        end

        def peek : Token
          @tokens[@index]
        end

        def next : Token
          tok = @tokens[@index]
          @index += 1 if @index < @tokens.size
          tok
        end

        def skip_trivia : Array(Token)
          trivia = [] of Token
          while !at_eof? && trivia_token?(peek)
            trivia << self.next
          end
          trivia
        end

        def trivia_token?(token : Token) : Bool
          case token.kind
          when TokenKind::Whitespace, TokenKind::Newline, TokenKind::CommentLine, TokenKind::CommentBlock
            true
          else
            false
          end
        end
      end

      def self.parse(bytes : Bytes, jsonc : Bool = false) : Result
        tokens, error = Lexer::TokenScanner.scan(bytes, jsonc)
        return Result.new(nil, error) unless error.success?

        stream = Stream.new(tokens, jsonc)
        root_trivia = stream.skip_trivia
        node, parse_error = parse_value(stream)
        return Result.new(nil, parse_error) unless parse_error.success?

        stream.skip_trivia
        return Result.new(nil, ErrorCode::TapeError) unless stream.at_eof?

        root = GreenNode.new(NodeKind::Root, [node], nil, root_trivia)
        Result.new(Document.new(bytes, RedNode.new(root)), ErrorCode::Success)
      end

      private def self.parse_value(stream : Stream) : Tuple(GreenNode, ErrorCode)
        leading = stream.skip_trivia
        token = stream.peek
        case token.kind
        when TokenKind::LBrace
          parse_object(stream, leading)
        when TokenKind::LBracket
          parse_array(stream, leading)
        when TokenKind::String
          stream.next
          {GreenNode.new(NodeKind::String, [] of GreenNode, token, leading), ErrorCode::Success}
        when TokenKind::Number
          stream.next
          {GreenNode.new(NodeKind::Number, [] of GreenNode, token, leading), ErrorCode::Success}
        when TokenKind::True
          stream.next
          {GreenNode.new(NodeKind::True, [] of GreenNode, token, leading), ErrorCode::Success}
        when TokenKind::False
          stream.next
          {GreenNode.new(NodeKind::False, [] of GreenNode, token, leading), ErrorCode::Success}
        when TokenKind::Null
          stream.next
          {GreenNode.new(NodeKind::Null, [] of GreenNode, token, leading), ErrorCode::Success}
        else
          {GreenNode.new(NodeKind::Null, [] of GreenNode, token, leading), ErrorCode::TapeError}
        end
      end

      private def self.parse_object(stream : Stream, leading : Array(Token)) : Tuple(GreenNode, ErrorCode)
        stream.next
        children = [] of GreenNode
        pending_trivia = stream.skip_trivia
        if stream.peek.kind == TokenKind::RBrace
          stream.next
          return {GreenNode.new(NodeKind::Object, children, nil, leading), ErrorCode::Success}
        end

        loop do
          pair, err = parse_pair(stream, pending_trivia)
          return {GreenNode.new(NodeKind::Object, children, nil, leading), err} unless err.success?
          children << pair
          pending_trivia = stream.skip_trivia
          case stream.peek.kind
          when TokenKind::Comma
            stream.next
            pending_trivia = stream.skip_trivia
            if stream.jsonc && stream.peek.kind == TokenKind::RBrace
              stream.next
              break
            end
            next
          when TokenKind::RBrace
            stream.next
            break
          else
            return {GreenNode.new(NodeKind::Object, children, nil, leading), ErrorCode::TapeError}
          end
        end

        {GreenNode.new(NodeKind::Object, children, nil, leading), ErrorCode::Success}
      end

      private def self.parse_pair(stream : Stream, leading : Array(Token)) : Tuple(GreenNode, ErrorCode)
        key_leading = leading
        key_token = stream.peek
        return {GreenNode.new(NodeKind::Pair), ErrorCode::TapeError} unless key_token.kind == TokenKind::String
        stream.next
        key_node = GreenNode.new(NodeKind::String, [] of GreenNode, key_token, key_leading)

        stream.skip_trivia
        return {GreenNode.new(NodeKind::Pair), ErrorCode::TapeError} unless stream.peek.kind == TokenKind::Colon
        stream.next

        value_node, err = parse_value(stream)
        return {GreenNode.new(NodeKind::Pair), err} unless err.success?

        {GreenNode.new(NodeKind::Pair, [key_node, value_node]), ErrorCode::Success}
      end

      private def self.parse_array(stream : Stream, leading : Array(Token)) : Tuple(GreenNode, ErrorCode)
        stream.next
        children = [] of GreenNode
        pending_trivia = stream.skip_trivia
        if stream.peek.kind == TokenKind::RBracket
          stream.next
          return {GreenNode.new(NodeKind::Array, children, nil, leading), ErrorCode::Success}
        end

        loop do
          value_node, err = parse_value_with_leading(stream, pending_trivia)
          return {GreenNode.new(NodeKind::Array, children, nil, leading), err} unless err.success?
          children << value_node
          pending_trivia = stream.skip_trivia
          case stream.peek.kind
          when TokenKind::Comma
            stream.next
            pending_trivia = stream.skip_trivia
            if stream.jsonc && stream.peek.kind == TokenKind::RBracket
              stream.next
              break
            end
            next
          when TokenKind::RBracket
            stream.next
            break
          else
            return {GreenNode.new(NodeKind::Array, children, nil, leading), ErrorCode::TapeError}
          end
        end

        {GreenNode.new(NodeKind::Array, children, nil, leading), ErrorCode::Success}
      end

      private def self.parse_value_with_leading(stream : Stream, leading : Array(Token)) : Tuple(GreenNode, ErrorCode)
        token = stream.peek
        case token.kind
        when TokenKind::LBrace
          parse_object(stream, leading)
        when TokenKind::LBracket
          parse_array(stream, leading)
        when TokenKind::String
          stream.next
          {GreenNode.new(NodeKind::String, [] of GreenNode, token, leading), ErrorCode::Success}
        when TokenKind::Number
          stream.next
          {GreenNode.new(NodeKind::Number, [] of GreenNode, token, leading), ErrorCode::Success}
        when TokenKind::True
          stream.next
          {GreenNode.new(NodeKind::True, [] of GreenNode, token, leading), ErrorCode::Success}
        when TokenKind::False
          stream.next
          {GreenNode.new(NodeKind::False, [] of GreenNode, token, leading), ErrorCode::Success}
        when TokenKind::Null
          stream.next
          {GreenNode.new(NodeKind::Null, [] of GreenNode, token, leading), ErrorCode::Success}
        else
          {GreenNode.new(NodeKind::Null, [] of GreenNode, token, leading), ErrorCode::TapeError}
        end
      end
    end
  end
end
