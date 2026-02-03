module Warp::Lang::Ruby
  module CST
    # NodeKind: Ruby-specific syntax tree node types
    enum NodeKind
      Root # Top-level program

      # Declarations
      ClassDef  # class Foo ... end
      ModuleDef # module Bar ... end
      MethodDef # def hello ... end
      SorbetSig # sig { returns(String) } or sig do ... end

      # Statements
      Assignment      # x = 5
      IfStatement     # if cond ... end
      UnlessStatement # unless cond ... end
      WhileStatement  # while cond ... end
      UntilStatement  # until cond ... end
      ForStatement    # for x in array ... end
      ReturnStatement # return value
      BreakStatement  # break
      NextStatement   # next

      # Expressions
      MethodCall    # obj.method(args)
      Identifier    # variable name
      Constant      # CLASS_NAME or Foo::Bar
      StringLiteral # "hello" or 'world'
      NumberLiteral # 123 or 4.56
      SymbolLiteral # :symbol
      ArrayLiteral  # [1, 2, 3]
      HashLiteral   # { a: 1, b: 2 }

      # Blocks
      Block       # { |x| x + 1 } or do |x| ... end
      BlockParams # |x, y|

      # Operators
      BinaryOp # +, -, *, /, etc.
      UnaryOp  # -, +, !

      # Misc
      Argument  # method argument
      Parameter # method parameter
      Type      # : String (for transpiled signatures)
    end

    # GreenNode: immutable tree node holding structure and trivia
    # Follows the same pattern as JSON CST
    class GreenNode
      getter kind : NodeKind
      getter children : Array(GreenNode)
      getter token : Token?
      getter leading_trivia : Array(Trivia)

      def initialize(
        @kind : NodeKind,
        @children : Array(GreenNode) = [] of GreenNode,
        @token : Token? = nil,
        @leading_trivia : Array(Trivia) = [] of Trivia,
      )
      end
    end

    # RedNode: provides parent/child navigation over GreenNode
    # Used for efficient tree traversal
    class RedNode
      getter green : GreenNode
      getter parent : RedNode?

      def initialize(@green : GreenNode, @parent : RedNode? = nil)
      end

      def kind : NodeKind
        @green.kind
      end

      def token : Token?
        @green.token
      end

      def leading_trivia : Array(Trivia)
        @green.leading_trivia
      end

      def children : Array(RedNode)
        @green.children.map { |child| RedNode.new(child, self) }
      end
    end

    # Parser: builds CST from tokens preserving all trivia
    class Parser
      @bytes : Bytes
      @tokens : Array(Token)
      @pos : Int32

      enum Precedence
        Lowest
        Assignment     # =
        Conditional    # ? :
        LogicalOr      # ||
        LogicalAnd     # &&
        Equality       # ==, !=
        Relational     # <, >, <=, >=
        Additive       # +, -
        Multiplicative # *, /, %
        Unary          # !, ~, +, -
        Call           # .
      end

      def initialize(@bytes, @tokens)
        @pos = 0
      end

      def self.parse(bytes : Bytes, tokens : Array(Token)) : Tuple(GreenNode?, Warp::Core::ErrorCode)
        parser = new(bytes, tokens)
        root = parser.parse_program
        {root, Warp::Core::ErrorCode::Success}
      end

      # Parse entire program
      def parse_program : GreenNode
        trivia = collect_trivia
        children = [] of GreenNode

        while @pos < @tokens.size && current.kind != TokenKind::Eof
          if current.kind == TokenKind::Def
            children << parse_method_def
          elsif is_sig_start?
            children << parse_sorbet_sig
          elsif current.kind == TokenKind::Identifier
            # Handle top-level require/require_relative and simple calls
            txt = String.new(@bytes[current.start, current.length])
            if txt == "require_relative" || txt == "require"
              children << parse_require_stmt
            else
              # Fallback: attempt to parse expression
              children << parse_expression
            end
          else
            # Skip other tokens for now
            advance
          end
        end

        GreenNode.new(NodeKind::Root, children, leading_trivia: trivia)
      end

      # Parse method definition: def name(params) ... end
      private def parse_method_def : GreenNode
        trivia = collect_trivia
        def_token = current
        advance # skip 'def'

        children = [] of GreenNode

        # 1. Skip whitespace/newlines to find method name
        while @pos < @tokens.size && current.kind == TokenKind::Newline
          advance
        end

        # 2. Method Name
        if current.kind == TokenKind::Identifier || current.kind == TokenKind::Constant
          name_tok = current
          children << GreenNode.new(NodeKind::Identifier, [] of GreenNode, name_tok)
          advance
        end

        # 3. Optional Parameters
        if current.kind == TokenKind::LParen
          advance # (
          while @pos < @tokens.size && current.kind != TokenKind::RParen
            if current.kind == TokenKind::Identifier
              children << GreenNode.new(NodeKind::Parameter, [] of GreenNode, current)
            end
            advance
          end
          advance if current.kind == TokenKind::RParen
        end

        # 4. Skip until end of line / start of body
        while @pos < @tokens.size && current.kind != TokenKind::Newline && current.kind != TokenKind::Semicolon
          # Handle cases where there might be something else on the line, but for now just advance
          if current.kind == TokenKind::End # Oops, empty method?
            break
          end
          advance
        end

        # 5. Body
        while @pos < @tokens.size && current.kind != TokenKind::End
          if current.kind == TokenKind::Newline
            advance
            next
          end

          children << parse_expression
        end

        # consume 'end' if present
        advance if current.kind == TokenKind::End

        GreenNode.new(NodeKind::MethodDef, children, def_token, trivia)
      end

      # Parse a basic expression supporting Pratt precedence
      private def parse_expression(precedence : Precedence = Precedence::Lowest) : GreenNode
        start_trivia = collect_trivia
        left = parse_prefix

        loop do
          # Peek for next significant token to determine precedence
          # We might have whitespace/newlines here
          saved_pos = @pos
          trivia = collect_trivia
          prec = get_precedence(current)

          if precedence >= prec
            @pos = saved_pos # backtrack trivia
            break
          end

          left = parse_infix(left)
        end

        left
      end

      private def parse_prefix : GreenNode
        case current.kind
        when TokenKind::Identifier
          tok = current
          advance
          GreenNode.new(NodeKind::Identifier, [] of GreenNode, tok)
        when TokenKind::String
          tok = current
          advance
          GreenNode.new(NodeKind::StringLiteral, [] of GreenNode, tok)
        when TokenKind::Number, TokenKind::Float
          tok = current
          advance
          GreenNode.new(NodeKind::NumberLiteral, [] of GreenNode, tok)
        when TokenKind::LParen
          advance # (
          node = parse_expression
          advance if current.kind == TokenKind::RParen
          node
        else
          # Fallback
          tok = current
          advance
          GreenNode.new(NodeKind::Identifier, [] of GreenNode, tok)
        end
      end

      private def parse_infix(left : GreenNode) : GreenNode
        case current.kind
        when TokenKind::Dot
          op_tok = current
          advance # .
          if current.kind == TokenKind::Identifier
            name_tok = current
            advance
            # Check for block
            children = [left, GreenNode.new(NodeKind::Identifier, [] of GreenNode, name_tok)]
            if current.kind == TokenKind::LBrace
              children << parse_block
            end
            GreenNode.new(NodeKind::MethodCall, children, op_tok)
          else
            left
          end
        when TokenKind::Plus, TokenKind::Minus, TokenKind::Star, TokenKind::Slash
          op_tok = current
          prec = get_precedence(current)
          advance
          right = parse_expression(prec)
          GreenNode.new(NodeKind::BinaryOp, [left, right], op_tok)
        when TokenKind::LBrace
          # block attached to previous node
          block = parse_block
          GreenNode.new(NodeKind::MethodCall, [left, block], left.token)
        else
          advance
          left
        end
      end

      private def get_precedence(token : Token) : Precedence
        case token.kind
        when TokenKind::Dot
          Precedence::Call
        when TokenKind::Star, TokenKind::Slash, TokenKind::Percent
          Precedence::Multiplicative
        when TokenKind::Plus, TokenKind::Minus
          Precedence::Additive
        when TokenKind::Equal
          Precedence::Assignment
        when TokenKind::LBrace
          Precedence::Call
        else
          Precedence::Lowest
        end
      end

      # Parse a small inline block: { |params| body }
      private def parse_block : GreenNode
        brace_tok = current
        advance # consume '{'

        params = [] of GreenNode
        # optional whitespace
        if current.kind == TokenKind::Pipe
          advance
          while @pos < @tokens.size && current.kind != TokenKind::Pipe
            if current.kind == TokenKind::Identifier
              params << GreenNode.new(NodeKind::Parameter, [] of GreenNode, current)
            end
            advance
          end
          advance if current.kind == TokenKind::Pipe
        end

        # parse a single expression as block body (simple heuristic)
        body_node : GreenNode? = nil
        while @pos < @tokens.size && current.kind != TokenKind::RBrace
          if current.kind == TokenKind::Newline
            advance
            next
          end

          if current.kind == TokenKind::Identifier
            body_node = parse_expression
          else
            advance
          end
        end

        advance if current.kind == TokenKind::RBrace

        children = [] of GreenNode
        if params.size > 0
          children << GreenNode.new(NodeKind::BlockParams, params)
        end
        if body_node
          children << (body_node.not_nil!)
        end

        GreenNode.new(NodeKind::Block, children, brace_tok)
      end

      # Parse Sorbet sig block: sig { ... } or sig do ... end
      private def parse_sorbet_sig : GreenNode
        trivia = collect_trivia
        sig_token = current
        advance # skip 'sig'

        children = [] of GreenNode

        # Handle both { ... } and do ... end forms
        if current.kind == TokenKind::LBrace
          # sig { ... }
          advance # skip '{'
          while @pos < @tokens.size && current.kind != TokenKind::RBrace
            advance
          end
          advance if current.kind == TokenKind::RBrace
        elsif current.kind == TokenKind::Do
          # sig do ... end
          advance # skip 'do'
          while @pos < @tokens.size && current.kind != TokenKind::End
            advance
          end
          advance if current.kind == TokenKind::End
        end

        GreenNode.new(NodeKind::SorbetSig, children, sig_token, trivia)
      end

      # Check if current position is start of sig block
      private def is_sig_start? : Bool
        return false unless current.kind == TokenKind::Identifier

        # Check if the identifier text is "sig"
        token_text = String.new(@bytes[current.start, current.length])
        token_text == "sig"
      end

      # Parse a simple require/require_relative statement: require "path"
      private def parse_require_stmt : GreenNode
        trivia = collect_trivia
        id_tok = current
        advance # consume require(_relative)

        # skip whitespace
        str_tok = current if current.kind == TokenKind::String
        advance if current.kind == TokenKind::String

        child = if str_tok
                  GreenNode.new(NodeKind::StringLiteral, [] of GreenNode, str_tok)
                else
                  GreenNode.new(NodeKind::Identifier, [] of GreenNode, id_tok)
                end

        GreenNode.new(NodeKind::MethodCall, [child], id_tok, trivia)
      end

      # Collect leading trivia (whitespace, comments, newlines)
      private def collect_trivia : Array(Trivia)
        return [] of Trivia if @pos >= @tokens.size
        current.trivia
      end

      private def current : Token
        return @tokens[-1] if @pos >= @tokens.size
        @tokens[@pos]
      end

      private def advance
        @pos += 1 if @pos < @tokens.size
      end
    end
  end
end
