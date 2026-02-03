module Warp::Lang::Crystal
  module CST
    # Crystal-specific CST node kinds (Phase 1 minimal set)
    enum NodeKind
      Root
      RawText
      MethodDef
      ClassDef
      ModuleDef
      StructDef
      EnumDef
      MacroDef
      MethodCall
      Identifier
      StringLiteral
      Block
    end

    struct ParamInfo
      getter name : String
      getter type : String?

      def initialize(@name : String, @type : String? = nil)
      end
    end

    struct MethodDefPayload
      getter name : String
      getter params : Array(ParamInfo)
      getter return_type : String?
      getter body : String
      getter had_parens : Bool
      getter original_source : String?

      def initialize(
        @name : String,
        @params : Array(ParamInfo),
        @return_type : String?,
        @body : String,
        @had_parens : Bool,
        @original_source : String? = nil,
      )
      end
    end

    # GreenNode: immutable tree node holding structure and trivia
    class GreenNode
      getter kind : NodeKind
      getter children : Array(GreenNode)
      getter text : String?
      getter leading_trivia : Array(Warp::Lang::Crystal::Trivia)
      getter method_payload : MethodDefPayload?

      def initialize(
        @kind : NodeKind,
        @children : Array(GreenNode) = [] of GreenNode,
        @text : String? = nil,
        @leading_trivia : Array(Warp::Lang::Crystal::Trivia) = [] of Warp::Lang::Crystal::Trivia,
        @method_payload : MethodDefPayload? = nil,
      )
      end
    end

    # RedNode: provides parent/child navigation over GreenNode
    class RedNode
      getter green : GreenNode
      getter parent : RedNode?

      def initialize(@green : GreenNode, @parent : RedNode? = nil)
      end

      def kind : NodeKind
        @green.kind
      end

      def text : String?
        @green.text
      end

      def leading_trivia : Array(Warp::Lang::Crystal::Trivia)
        @green.leading_trivia
      end

      def method_payload : MethodDefPayload?
        @green.method_payload
      end

      def children : Array(RedNode)
        @green.children.map { |child| RedNode.new(child, self) }
      end
    end

    # Document: wraps output bytes and the root RedNode
    class Document
      getter bytes : Bytes
      getter root : RedNode

      def initialize(@bytes : Bytes, @root : RedNode)
      end
    end

    # Parser: builds CST from tokens preserving all trivia
    class Parser
      @bytes : Bytes
      @tokens : Array(Warp::Lang::Crystal::Token)
      @pos : Int32

      def initialize(@bytes, @tokens)
        @pos = 0
      end

      def self.parse(bytes : Bytes, tokens : Array(Warp::Lang::Crystal::Token)) : Tuple(GreenNode?, Warp::Core::ErrorCode)
        parser = new(bytes, tokens)
        root = parser.parse_program
        {root, Warp::Core::ErrorCode::Success}
      end

      def parse_program : GreenNode
        trivia = collect_trivia
        children = [] of GreenNode
        last_pos = 0

        while @pos < @tokens.size && current.kind != TokenKind::Eof
          case current.kind
          when TokenKind::Def
            # Capture any preceding text as RawText
            if last_pos < current.start
              raw_text = String.new(@bytes[last_pos, current.start - last_pos])
              children << GreenNode.new(NodeKind::RawText, [] of GreenNode, raw_text)
            end

            children << parse_method_def
            last_pos = @pos < @tokens.size ? current.start : @bytes.size
          when TokenKind::Class
            # Capture any preceding text as RawText
            if last_pos < current.start
              raw_text = String.new(@bytes[last_pos, current.start - last_pos])
              children << GreenNode.new(NodeKind::RawText, [] of GreenNode, raw_text)
            end

            children << parse_simple_block(NodeKind::ClassDef)
            last_pos = @pos < @tokens.size ? current.start : @bytes.size
          when TokenKind::Module
            if last_pos < current.start
              raw_text = String.new(@bytes[last_pos, current.start - last_pos])
              children << GreenNode.new(NodeKind::RawText, [] of GreenNode, raw_text)
            end
            children << parse_simple_block(NodeKind::ModuleDef)
            last_pos = @pos < @tokens.size ? current.start : @bytes.size
          when TokenKind::Struct
            if last_pos < current.start
              raw_text = String.new(@bytes[last_pos, current.start - last_pos])
              children << GreenNode.new(NodeKind::RawText, [] of GreenNode, raw_text)
            end
            children << parse_simple_block(NodeKind::StructDef)
            last_pos = @pos < @tokens.size ? current.start : @bytes.size
          when TokenKind::Enum
            if last_pos < current.start
              raw_text = String.new(@bytes[last_pos, current.start - last_pos])
              children << GreenNode.new(NodeKind::RawText, [] of GreenNode, raw_text)
            end
            children << parse_simple_block(NodeKind::EnumDef)
            last_pos = @pos < @tokens.size ? current.start : @bytes.size
          when TokenKind::Macro
            if last_pos < current.start
              raw_text = String.new(@bytes[last_pos, current.start - last_pos])
              children << GreenNode.new(NodeKind::RawText, [] of GreenNode, raw_text)
            end
            children << parse_simple_block(NodeKind::MacroDef)
            last_pos = @pos < @tokens.size ? current.start : @bytes.size
          else
            # Skip unknown tokens (will be captured as RawText at the end)
            advance
          end
        end

        # Capture any remaining text as RawText
        if last_pos < @bytes.size
          raw_text = String.new(@bytes[last_pos, @bytes.size - last_pos])
          children << GreenNode.new(NodeKind::RawText, [] of GreenNode, raw_text)
        end

        GreenNode.new(NodeKind::Root, children)
      end

      private def parse_expression : GreenNode
        tok = current
        tok_text = String.new(@bytes[tok.start, tok.length])
        node = GreenNode.new(NodeKind::Identifier, [] of GreenNode, tok_text)
        advance

        while @pos < @tokens.size
          case current.kind
          when TokenKind::Dot
            advance
            if current.kind == TokenKind::Identifier || current.kind == TokenKind::Constant
              method_tok = current
              method_text = String.new(@bytes[method_tok.start, method_tok.length])
              advance
              node = GreenNode.new(NodeKind::MethodCall, [node], method_text)
            else
              break
            end
          when TokenKind::LParen
            advance
            # Collect everything inside parens as raw text for now or just skip to RParen
            while @pos < @tokens.size && current.kind != TokenKind::RParen
              if current.kind == TokenKind::Ampersand
                # Could handle block shorthand here
                advance
              else
                advance
              end
            end
            advance if current.kind == TokenKind::RParen
            # Wrap as method call if we just had one, or keep same node
          else
            break
          end
        end
        node
      end

      private def parse_simple_block(kind : NodeKind) : GreenNode
        # Delegate method defs to the specialized parser
        return parse_method_def if kind == NodeKind::MethodDef

        # Record the start of the block (keyword position)
        block_start = current.start
        advance # consume the keyword

        # Skip header until end-of-line (if present)
        while @pos < @tokens.size && current.kind != TokenKind::Newline
          advance
        end
        advance if current.kind == TokenKind::Newline

        # Capture header text as a RawText child so it's preserved
        header_end = @pos < @tokens.size ? current.start : @bytes.size
        if header_end > block_start
          header_text = String.new(@bytes[block_start, header_end - block_start])
          children = [GreenNode.new(NodeKind::RawText, [] of GreenNode, header_text)]
        else
          children = [] of GreenNode
        end

        cursor = @pos < @tokens.size ? current.start : @bytes.size
        i = @pos

        while i < @tokens.size
          tok = @tokens[i]

          if tok.kind == TokenKind::Def
            def_start = tok.start
            if def_start > cursor
              children << GreenNode.new(NodeKind::RawText, [] of GreenNode, String.new(@bytes[cursor, def_start - cursor]))
            end

            # Re-position parser and parse method def
            @pos = i
            method_node = parse_method_def
            children << method_node
            # Update index and cursor
            i = @pos
            cursor = @pos < @tokens.size ? current.start : @bytes.size
            next
          elsif tok.kind == TokenKind::Class
            nested_start = tok.start
            if nested_start > cursor
              children << GreenNode.new(NodeKind::RawText, [] of GreenNode, String.new(@bytes[cursor, nested_start - cursor]))
            end
            @pos = i
            nested = parse_simple_block(NodeKind::ClassDef)
            children << nested
            i = @pos
            cursor = @pos < @tokens.size ? current.start : @bytes.size
            next
          elsif tok.kind == TokenKind::Module
            nested_start = tok.start
            if nested_start > cursor
              children << GreenNode.new(NodeKind::RawText, [] of GreenNode, String.new(@bytes[cursor, nested_start - cursor]))
            end
            @pos = i
            nested = parse_simple_block(NodeKind::ModuleDef)
            children << nested
            i = @pos
            cursor = @pos < @tokens.size ? current.start : @bytes.size
            next
          elsif tok.kind == TokenKind::Struct
            nested_start = tok.start
            if nested_start > cursor
              children << GreenNode.new(NodeKind::RawText, [] of GreenNode, String.new(@bytes[cursor, nested_start - cursor]))
            end
            @pos = i
            nested = parse_simple_block(NodeKind::StructDef)
            children << nested
            i = @pos
            cursor = @pos < @tokens.size ? current.start : @bytes.size
            next
          elsif tok.kind == TokenKind::End
            end_start = tok.start
            end_end = end_start + tok.length
            if end_start > cursor
              children << GreenNode.new(NodeKind::RawText, [] of GreenNode, String.new(@bytes[cursor, end_start - cursor]))
            end
            # Include the 'end' token text as well
            children << GreenNode.new(NodeKind::RawText, [] of GreenNode, String.new(@bytes[end_start, end_end - end_start]))
            # Advance parser after 'end' and return
            @pos = i + 1
            return GreenNode.new(kind, children)
          else
            i += 1
          end
        end

        # If we fell out without finding an 'end', capture remaining text
        if cursor < @bytes.size
          children << GreenNode.new(NodeKind::RawText, [] of GreenNode, String.new(@bytes[cursor, @bytes.size - cursor]))
        end

        GreenNode.new(kind, children)
      end

      private def parse_method_def : GreenNode
        def_pos = @pos
        def_start = current.start
        advance # consume 'def'

        # Collect method name and parameters
        method_name = ""
        params = [] of ParamInfo
        had_parens = false

        # Get method name (support `self.method` and simple identifiers)
        # Don't skip newlines yet - might have params/return type on same line
        if current.kind == TokenKind::Identifier
          method_name = String.new(@bytes[current.start, current.length])
          advance
        elsif current.kind == TokenKind::Self
          # Handle `self.foo` style
          name = String.new(@bytes[current.start, current.length])
          advance
          if current.kind == TokenKind::Dot
            advance
            if current.kind == TokenKind::Identifier || current.kind == TokenKind::Constant
              name = "#{name}.#{String.new(@bytes[current.start, current.length])}"
              advance
            end
          end
          method_name = name
        end

        # After method name, current might be:
        # - LParen (parameters)
        # - Colon (return type)
        # - Newline (end of header)
        # - Something else (implicit end of header)

        # Parse parameters if present
        if current.kind == TokenKind::LParen
          had_parens = true
          advance # consume '('

          while @pos < @tokens.size && current.kind != TokenKind::RParen
            if current.kind == TokenKind::Identifier
              param_name = String.new(@bytes[current.start, current.length])
              param_type : String? = nil
              advance

              # Skip newlines
              while @pos < @tokens.size && current.kind == TokenKind::Newline
                advance
              end

              # Check for type annotation (: Type)
              if current.kind == TokenKind::Colon
                advance
                # Skip newlines
                while @pos < @tokens.size && current.kind == TokenKind::Newline
                  advance
                end

                # Collect type tokens until comma or paren, handling nested parens
                type_start = @pos
                paren_depth = 0
                while @pos < @tokens.size
                  if current.kind == TokenKind::LParen
                    paren_depth += 1
                  elsif current.kind == TokenKind::RParen
                    if paren_depth > 0
                      paren_depth -= 1
                    else
                      break # End of parameters
                    end
                  elsif (current.kind == TokenKind::Comma || current.kind == TokenKind::RParen) && paren_depth == 0
                    break
                  end
                  advance
                end

                if type_start < @pos
                  # Extract type string
                  type_tokens = @tokens[type_start...@pos]
                  type_text = String.build do |io|
                    type_tokens.each do |t|
                      io << String.new(@bytes[t.start, t.length])
                    end
                  end
                  param_type = type_text
                end
              end

              params << ParamInfo.new(param_name, param_type)

              # Skip whitespace
              while @pos < @tokens.size && current.kind == TokenKind::Newline
                advance
              end

              # Skip comma
              if current.kind == TokenKind::Comma
                advance
                while @pos < @tokens.size && current.kind == TokenKind::Newline
                  advance
                end
              end
            else
              advance
            end
          end

          advance if current.kind == TokenKind::RParen
        end

        # Check for return type annotation (: Type)
        return_type : String? = nil
        if current.kind == TokenKind::Colon
          advance
          # Skip newlines
          while @pos < @tokens.size && current.kind == TokenKind::Newline
            advance
          end

          # Collect return type tokens until newline or semicolon
          type_start = @pos
          while @pos < @tokens.size && current.kind != TokenKind::Newline
            advance
          end

          if type_start < @pos
            # Extract return type string
            type_tokens = @tokens[type_start...@pos]
            type_text = String.build do |io|
              type_tokens.each do |t|
                io << String.new(@bytes[t.start, t.length])
              end
            end
            return_type = type_text
          end
        end

        # Now we should be at Newline (end of header) or EOF
        # Skip to end of header line (handle single-line methods like `def foo; end`)
        while @pos < @tokens.size && current.kind != TokenKind::Newline
          advance
        end

        header_end = current.start + (current.kind == TokenKind::Newline ? current.length : 0)
        if current.kind == TokenKind::Newline
          advance
        end

        # Collect body until 'end'
        # Include trivia (whitespace) from first token of body
        body_start = @pos
        body_byte_start = if !current.trivia.empty?
                            current.trivia.first.start
                          else
                            current.start
                          end

        while @pos < @tokens.size && current.kind != TokenKind::End
          advance
        end

        body_byte_end = current.start
        body_text = String.new(@bytes[body_byte_start, body_byte_end - body_byte_start])

        # Capture the entire method source including leading whitespace
        # This is used for preserving original indentation
        end_byte = current.start + (current.kind == TokenKind::End ? current.length : 0)
        original_source = String.new(@bytes[def_start, end_byte - def_start])

        advance if current.kind == TokenKind::End

        payload = CST::MethodDefPayload.new(method_name, params, return_type, body_text, had_parens, original_source)
        GreenNode.new(NodeKind::MethodDef, [] of GreenNode, nil, [] of Warp::Lang::Crystal::Trivia, payload)
      end

      private def collect_trivia : Array(Warp::Lang::Crystal::Trivia)
        return [] of Warp::Lang::Crystal::Trivia if @pos >= @tokens.size
        current.trivia
      end

      private def current : Warp::Lang::Crystal::Token
        return @tokens[-1] if @pos >= @tokens.size
        @tokens[@pos]
      end

      private def advance
        @pos += 1 if @pos < @tokens.size
      end

      private def collect_trivia : Array(Warp::Lang::Crystal::Trivia)
        return [] of Warp::Lang::Crystal::Trivia if @pos >= @tokens.size
        current.trivia
      end

      private def current : Warp::Lang::Crystal::Token
        return @tokens[-1] if @pos >= @tokens.size
        @tokens[@pos]
      end

      private def advance
        @pos += 1 if @pos < @tokens.size
      end
    end
  end
end
