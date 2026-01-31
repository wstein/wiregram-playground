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
      getter leading_trivia : Array(Token)

      def initialize(
        @kind : NodeKind,
        @children : Array(GreenNode) = [] of GreenNode,
        @token : Token? = nil,
        @leading_trivia : Array(Token) = [] of Token,
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

      def leading_trivia : Array(Token)
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

        # Collect method name and params as children
        children = [] of GreenNode

        # Skip to 'end' for now (simplified)
        while @pos < @tokens.size && current.kind != TokenKind::End
          advance
        end

        if current.kind == TokenKind::End
          advance # skip 'end'
        end

        GreenNode.new(NodeKind::MethodDef, children, def_token, trivia)
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

      # Collect leading trivia (whitespace, comments, newlines)
      private def collect_trivia : Array(Token)
        trivia = [] of Token

        while @pos < @tokens.size
          kind = current.kind
          if kind == TokenKind::Whitespace || kind == TokenKind::Newline || kind == TokenKind::CommentLine
            trivia << current
            advance
          else
            break
          end
        end

        trivia
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
