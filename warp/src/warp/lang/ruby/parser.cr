# Ruby Parser: builds a semantic AST from Ruby tokens

module Warp
  module Lang
    module Ruby
      class Parser
        alias ErrorCode = Warp::Core::ErrorCode
        alias AstNode = AST::Node
        alias AstResult = AST::Result

        @bytes : Bytes
        @tokens : Array(Token)
        @index : Int32
        @error : ErrorCode

        def initialize(@bytes : Bytes, @tokens : Array(Token))
          @index = 0
          @error = ErrorCode::Success
        end

        def self.parse(bytes : Bytes) : AstResult
          tokens, err = Lexer.scan(bytes)
          return AstResult.new(nil, err) unless err.success?

          parser = new(bytes, tokens)
          node = parser.parse_program
          AstResult.new(node, parser.error)
        end

        def error : ErrorCode
          @error
        end

        def parse_program : AstNode
          nodes = [] of AstNode
          skip_trivia
          while (tok = current) && tok.kind != TokenKind::Eof
            stmt = parse_statement
            nodes << stmt if stmt
            skip_trivia
          end
          span_start = nodes.first?.try(&.start) || 0
          span_end = nodes.last?.try(&.span_end) || span_start
          AstNode.new(NodeKind::Program, nodes, nil, span_start, span_end - span_start)
        end

        private def parse_statement : AstNode?
          skip_trivia
          tok = current
          return nil unless tok

          case tok.kind
          when TokenKind::Def
            parse_def
          when TokenKind::Class
            parse_class
          when TokenKind::Module
            parse_module
          when TokenKind::If
            parse_if
          when TokenKind::Unless
            parse_unless
          when TokenKind::While
            parse_while
          when TokenKind::Return
            parse_return
          else
            parse_expression
          end
        end

        private def parse_def : AstNode
          def_tok = consume(TokenKind::Def)
          skip_trivia
          name_tok = consume_identifier
          name_node = name_tok ? node_from_token(NodeKind::Identifier, name_tok) : node_unknown("<anonymous>")
          params_node = parse_param_list
          body_node = parse_block_until(TokenKind::End)
          end_tok = consume(TokenKind::End)
          span_start = def_tok ? def_tok.start : name_node.start
          span_end = end_tok ? end_tok.start + end_tok.length : body_node.span_end
          AstNode.new(NodeKind::MethodDef, [params_node, body_node], name_node.value, span_start, span_end - span_start)
        end

        private def parse_class : AstNode
          class_tok = consume(TokenKind::Class)
          skip_trivia
          name_tok = consume_identifier
          name_node = name_tok ? node_from_token(NodeKind::Constant, name_tok) : node_unknown("<anon_class>")
          body_node = parse_block_until(TokenKind::End)
          end_tok = consume(TokenKind::End)
          span_start = class_tok ? class_tok.start : name_node.start
          span_end = end_tok ? end_tok.start + end_tok.length : body_node.span_end
          AstNode.new(NodeKind::ClassDef, [body_node], name_node.value, span_start, span_end - span_start)
        end

        private def parse_module : AstNode
          mod_tok = consume(TokenKind::Module)
          skip_trivia
          name_tok = consume_identifier
          name_node = name_tok ? node_from_token(NodeKind::Constant, name_tok) : node_unknown("<anon_module>")
          body_node = parse_block_until(TokenKind::End)
          end_tok = consume(TokenKind::End)
          span_start = mod_tok ? mod_tok.start : name_node.start
          span_end = end_tok ? end_tok.start + end_tok.length : body_node.span_end
          AstNode.new(NodeKind::ModuleDef, [body_node], name_node.value, span_start, span_end - span_start)
        end

        private def parse_if : AstNode
          if_tok = consume(TokenKind::If)
          skip_trivia
          cond = parse_expression
          then_block = parse_block_until(TokenKind::End, TokenKind::Else, TokenKind::Elsif)
          else_block = nil
          if match(TokenKind::Else)
            else_block = parse_block_until(TokenKind::End)
          end
          end_tok = consume(TokenKind::End)
          children = [cond, then_block] of AstNode
          children << else_block if else_block
          span_start = if_tok ? if_tok.start : cond.start
          span_end = end_tok ? end_tok.start + end_tok.length : then_block.span_end
          AstNode.new(NodeKind::If, children, nil, span_start, span_end - span_start)
        end

        private def parse_unless : AstNode
          unless_tok = consume(TokenKind::Unless)
          skip_trivia
          cond = parse_expression
          body = parse_block_until(TokenKind::End)
          end_tok = consume(TokenKind::End)
          span_start = unless_tok ? unless_tok.start : cond.start
          span_end = end_tok ? end_tok.start + end_tok.length : body.span_end
          AstNode.new(NodeKind::Unless, [cond, body], nil, span_start, span_end - span_start)
        end

        private def parse_while : AstNode
          while_tok = consume(TokenKind::While)
          skip_trivia
          cond = parse_expression
          body = parse_block_until(TokenKind::End)
          end_tok = consume(TokenKind::End)
          span_start = while_tok ? while_tok.start : cond.start
          span_end = end_tok ? end_tok.start + end_tok.length : body.span_end
          AstNode.new(NodeKind::While, [cond, body], nil, span_start, span_end - span_start)
        end

        private def parse_return : AstNode
          ret_tok = consume(TokenKind::Return)
          skip_trivia
          expr = current && current.not_nil!.kind != TokenKind::Newline ? parse_expression : nil
          span_start = ret_tok ? ret_tok.start : 0
          span_end = expr ? expr.span_end : (ret_tok ? ret_tok.start + ret_tok.length : 0)
          children = expr ? [expr] : [] of AstNode
          AstNode.new(NodeKind::Return, children, nil, span_start, span_end - span_start)
        end

        private def parse_param_list : AstNode
          params = [] of AstNode
          if match(TokenKind::LParen)
            skip_trivia
            while (tok = current) && tok.kind != TokenKind::RParen && tok.kind != TokenKind::Eof
              if tok.kind == TokenKind::Identifier
                params << node_from_token(NodeKind::Identifier, tok)
                advance
              else
                advance
              end
              skip_trivia
              match(TokenKind::Comma)
              skip_trivia
            end
            consume(TokenKind::RParen)
          end
          span_start = params.first?.try(&.start) || 0
          span_end = params.last?.try(&.span_end) || span_start
          AstNode.new(NodeKind::Program, params, nil, span_start, span_end - span_start)
        end

        private def parse_block_until(*terminators : TokenKind) : AstNode
          nodes = [] of AstNode
          skip_trivia
          while (tok = current)
            break if terminators.includes?(tok.kind) || tok.kind == TokenKind::Eof
            stmt = parse_statement
            nodes << stmt if stmt
            skip_trivia
          end
          span_start = nodes.first?.try(&.start) || (current ? current.not_nil!.start : 0)
          span_end = nodes.last?.try(&.span_end) || span_start
          AstNode.new(NodeKind::Program, nodes, nil, span_start, span_end - span_start)
        end

        private def parse_expression : AstNode
          left = parse_postfix
          skip_trivia
          while (tok = current) && binary_operator?(tok.kind)
            op_tok = advance
            skip_trivia
            right = parse_postfix
            op_value = op_tok ? token_text(op_tok) : "?"
            span_start = left.start
            span_end = right.span_end
            left = AstNode.new(NodeKind::Binary, [left, right], op_value, span_start, span_end - span_start)
            skip_trivia
          end
          left
        end

        private def parse_postfix : AstNode
          node = parse_primary
          loop do
            skip_trivia
            tok = current
            break unless tok

            if tok.kind == TokenKind::Dot
              advance
              name_tok = consume_identifier
              call_name = name_tok ? token_text(name_tok) : "<missing>"
              args = parse_call_args
              node = AstNode.new(NodeKind::Call, [node] + args, call_name, node.start, node.span_end - node.start, {"receiver" => "true"})
              next
            end

            if tok.kind == TokenKind::LParen
              args = parse_call_args
              if node.kind == NodeKind::Identifier
                node = AstNode.new(NodeKind::Call, args, node.value, node.start, node.span_end - node.start, {"receiver" => "false"})
              else
                node = AstNode.new(NodeKind::Call, [node] + args, nil, node.start, node.span_end - node.start, {"receiver" => "true"})
              end
              next
            end

            if tok.kind == TokenKind::LBrace || tok.kind == TokenKind::Do
              block = parse_block
              node = AstNode.new(NodeKind::Call, node.children + [block], node.value, node.start, block.span_end - node.start, {"receiver" => "false", "block" => "true"})
              next
            end

            if node.kind == NodeKind::Identifier && bare_arg_start?(tok.kind)
              args = parse_bare_args
              node = AstNode.new(NodeKind::Call, args, node.value, node.start, args.last.span_end - node.start, {"receiver" => "false"})
              next
            end

            break
          end

          node
        end

        private def parse_primary : AstNode
          tok = current
          return node_unknown("<eof>") unless tok

          case tok.kind
          when TokenKind::Identifier
            node = node_from_token(NodeKind::Identifier, tok)
            advance
            node
          when TokenKind::Constant
            node = node_from_token(NodeKind::Constant, tok)
            advance
            node
          when TokenKind::InstanceVar
            node = node_from_token(NodeKind::InstanceVar, tok)
            advance
            node
          when TokenKind::ClassVar
            node = node_from_token(NodeKind::ClassVar, tok)
            advance
            node
          when TokenKind::GlobalVar
            node = node_from_token(NodeKind::GlobalVar, tok)
            advance
            node
          when TokenKind::String
            node = node_from_token(NodeKind::String, tok)
            advance
            node
          when TokenKind::Regex
            node = node_from_token(NodeKind::Regex, tok)
            advance
            node
          when TokenKind::Heredoc
            node = node_from_token(NodeKind::String, tok)
            advance
            node
          when TokenKind::Number
            node = node_from_token(NodeKind::Number, tok)
            advance
            node
          when TokenKind::Float
            node = node_from_token(NodeKind::Number, tok)
            advance
            node
          when TokenKind::Symbol
            node = node_from_token(NodeKind::Symbol, tok)
            advance
            node
          when TokenKind::LParen
            advance
            expr = parse_expression
            consume(TokenKind::RParen)
            expr
          when TokenKind::LBracket
            parse_array
          when TokenKind::LBrace
            parse_hash
          when TokenKind::True
            node = node_from_token(NodeKind::Boolean, tok)
            advance
            node
          when TokenKind::False
            node = node_from_token(NodeKind::Boolean, tok)
            advance
            node
          when TokenKind::Nil
            node = node_from_token(NodeKind::Nil, tok)
            advance
            node
          else
            node = node_unknown(token_text(tok))
            advance
            node
          end
        end

        private def parse_array : AstNode
          start_tok = consume(TokenKind::LBracket)
          elements = [] of AstNode
          skip_trivia
          while (tok = current) && tok.kind != TokenKind::RBracket && tok.kind != TokenKind::Eof
            elements << parse_expression
            skip_trivia
            match(TokenKind::Comma)
            skip_trivia
          end
          end_tok = consume(TokenKind::RBracket)
          span_start = start_tok ? start_tok.start : 0
          span_end = end_tok ? end_tok.start + end_tok.length : (elements.last?.try(&.span_end) || span_start)
          AstNode.new(NodeKind::Array, elements, nil, span_start, span_end - span_start)
        end

        private def parse_hash : AstNode
          start_tok = consume(TokenKind::LBrace)
          pairs = [] of AstNode
          skip_trivia
          while (tok = current) && tok.kind != TokenKind::RBrace && tok.kind != TokenKind::Eof
            key = parse_expression
            skip_trivia
            if match(TokenKind::Arrow) || match(TokenKind::Colon)
              skip_trivia
              value = parse_expression
              pair = AstNode.new(NodeKind::Assignment, [key, value], nil, key.start, value.span_end - key.start)
              pairs << pair
            else
              pairs << key
            end
            skip_trivia
            match(TokenKind::Comma)
            skip_trivia
          end
          end_tok = consume(TokenKind::RBrace)
          span_start = start_tok ? start_tok.start : 0
          span_end = end_tok ? end_tok.start + end_tok.length : (pairs.last?.try(&.span_end) || span_start)
          AstNode.new(NodeKind::Hash, pairs, nil, span_start, span_end - span_start)
        end

        private def parse_call_args : Array(AstNode)
          args = [] of AstNode
          if match(TokenKind::LParen)
            skip_trivia
            while (tok = current) && tok.kind != TokenKind::RParen && tok.kind != TokenKind::Eof
              args << parse_expression
              skip_trivia
              match(TokenKind::Comma)
              skip_trivia
            end
            consume(TokenKind::RParen)
          end
          args
        end

        private def parse_bare_args : Array(AstNode)
          args = [] of AstNode
          while (tok = current) && bare_arg_start?(tok.kind)
            args << parse_expression
            skip_trivia
            match(TokenKind::Comma)
            skip_trivia
          end
          args
        end

        private def parse_block : AstNode
          start_tok = current
          if match(TokenKind::LBrace)
            params = parse_block_params
            body = parse_block_until(TokenKind::RBrace)
            end_tok = consume(TokenKind::RBrace)
            span_start = start_tok ? start_tok.start : 0
            span_end = end_tok ? end_tok.start + end_tok.length : body.span_end
            AstNode.new(NodeKind::Block, [params, body], nil, span_start, span_end - span_start)
          else
            consume(TokenKind::Do)
            params = parse_block_params
            body = parse_block_until(TokenKind::End)
            end_tok = consume(TokenKind::End)
            span_start = start_tok ? start_tok.start : 0
            span_end = end_tok ? end_tok.start + end_tok.length : body.span_end
            AstNode.new(NodeKind::Block, [params, body], nil, span_start, span_end - span_start)
          end
        end

        private def parse_block_params : AstNode
          params = [] of AstNode
          skip_trivia
          if match(TokenKind::Pipe)
            skip_trivia
            while (tok = current) && tok.kind != TokenKind::Pipe && tok.kind != TokenKind::Eof
              if tok.kind == TokenKind::Identifier
                params << node_from_token(NodeKind::Identifier, tok)
                advance
              else
                advance
              end
              skip_trivia
              match(TokenKind::Comma)
              skip_trivia
            end
            consume(TokenKind::Pipe)
          end
          span_start = params.first?.try(&.start) || 0
          span_end = params.last?.try(&.span_end) || span_start
          AstNode.new(NodeKind::Program, params, nil, span_start, span_end - span_start)
        end

        private def bare_arg_start?(kind : TokenKind) : Bool
          case kind
          when TokenKind::Identifier, TokenKind::String, TokenKind::Number, TokenKind::Float,
               TokenKind::Symbol, TokenKind::Regex, TokenKind::Heredoc, TokenKind::LParen,
               TokenKind::LBracket, TokenKind::LBrace, TokenKind::True, TokenKind::False, TokenKind::Nil
            true
          else
            false
          end
        end

        private def binary_operator?(kind : TokenKind) : Bool
          case kind
          when TokenKind::Plus, TokenKind::Minus, TokenKind::Star, TokenKind::Slash, TokenKind::Percent,
               TokenKind::Power, TokenKind::Equal, TokenKind::Match, TokenKind::NotMatch, TokenKind::LessThan,
               TokenKind::GreaterThan, TokenKind::LessEqual, TokenKind::GreaterEqual, TokenKind::LogicalAnd,
               TokenKind::LogicalOr
            true
          else
            false
          end
        end

        private def node_from_token(kind : NodeKind, tok : Token) : AstNode
          text = token_text(tok)
          AstNode.new(kind, [] of AstNode, text, tok.start, tok.length)
        end

        private def node_unknown(value : String) : AstNode
          AstNode.new(NodeKind::Identifier, [] of AstNode, value, 0, 0)
        end

        private def token_text(tok : Token) : String
          String.new(@bytes[tok.start, tok.length])
        end

        private def current : Token?
          @tokens[@index]?
        end

        private def advance : Token?
          tok = @tokens[@index]?
          @index += 1 if tok
          tok
        end

        private def match(kind : TokenKind) : Bool
          tok = current
          return false unless tok
          if tok.kind == kind
            advance
            true
          else
            false
          end
        end

        private def consume(kind : TokenKind) : Token?
          tok = current
          return nil unless tok
          if tok.kind == kind
            advance
            tok
          else
            nil
          end
        end

        private def consume_identifier : Token?
          tok = current
          return nil unless tok
          if tok.kind == TokenKind::Identifier || tok.kind == TokenKind::Constant
            advance
            tok
          else
            nil
          end
        end

        private def skip_trivia
          while (tok = current)
            if tok.kind == TokenKind::Whitespace || tok.kind == TokenKind::Newline || tok.kind == TokenKind::CommentLine
              advance
            else
              break
            end
          end
        end
      end
    end
  end
end
