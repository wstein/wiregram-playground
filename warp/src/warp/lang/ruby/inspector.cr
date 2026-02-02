module Warp::Lang::Ruby
  class Inspector
    def self.dump_tokens(bytes : Bytes)
      tokens, err, pos = Lexer.scan(bytes)
      if err != Warp::Core::ErrorCode::Success
        diag = Warp::Diagnostics.lex_error("lexer fail", bytes, pos)
        puts diag.to_s
        return
      end

      puts "Tokens:"
      tokens.each_with_index do |t, i|
        txt = String.new(bytes[t.start, t.length])
        puts "#{i}: #{t.kind} (start=#{t.start}, len=#{t.length}) -> #{txt.inspect}"
      end
    end

    def self.dump_cst(bytes : Bytes)
      tokens, _, _ = Lexer.scan(bytes)
      root_green, err = CST::Parser.parse(bytes, tokens)
      if err != Warp::Core::ErrorCode::Success
        puts "Parser error: #{err}"
        return
      end

      root_red = CST::RedNode.new(root_green)
      puts "CST (Red Tree):"
      print_red(root_red, bytes)
    end

    private def self.print_red(node, bytes, depth = 0)
      indent = "  " * depth
      txt = ""
      if tok = node.token
        tok_text = ""
        if tok.length > 0
          tok_text = String.new(bytes[tok.start, tok.length])
        end
        txt = " token=#{tok.kind}:'#{tok_text}'"
      end
      puts "#{indent}- #{node.kind}#{txt}"
      node.children.each do |child|
        print_red(child, bytes, depth + 1)
      end
    end

    def self.dump_ast(bytes : Bytes)
      tokens, _, _ = Lexer.scan(bytes)
      root_green, _ = CST::Parser.parse(bytes, tokens)
      root_red = CST::RedNode.new(root_green)

      ast_root = AST::Builder.from_cst(root_red)
      puts "AST (Semantic Tree):"
      print_ast(ast_root)
    end

    private def self.print_ast(node : AST::Node, depth = 0)
      indent = "  " * depth
      puts "#{indent}- #{node.kind} #{node.value ? "(#{node.value})" : ""}"
      node.children.each do |child|
        print_ast(child, depth + 1)
      end
    end

    def self.dump_tape(bytes : Bytes)
      tokens, _, _ = Lexer.scan(bytes)
      root_green, _ = CST::Parser.parse(bytes, tokens)
      root_red = CST::RedNode.new(root_green)

      tape = Tape::Builder.build(bytes, root_red)

      puts "Tape IR:"
      tape.each_with_index do |entry, i|
        trivia = String.new(bytes[entry.trivia_start...entry.lexeme_start]).inspect if entry.lexeme_start > entry.trivia_start
        lexeme = String.new(bytes[entry.lexeme_start...entry.lexeme_end]).inspect if entry.lexeme_end > entry.lexeme_start
        puts "#{i.to_s.rjust(3)}: #{entry.type.to_s.ljust(12)} trivia=#{trivia || "\"\"\"\""} lexeme=#{lexeme || "\"\"\"\""}"
      end
    end

    def self.dump_simd(bytes : Bytes)
      puts "SIMD Structural Scan (SIMULATED):"
      # In a full implementation, this calls Warp::Lexer::StructuralScan
      # Here we simulate by showing positions of key structural symbols
      structurals = [] of {Int32, Char}
      bytes.each_with_index do |b, i|
        c = b.chr
        if "{}[],.:()".includes?(c)
          structurals << {i, c}
        end
      end

      structurals.each do |pos, char|
        puts "  Pos #{pos.to_s.rjust(4)}: '#{char}'"
      end
    end
  end
end
