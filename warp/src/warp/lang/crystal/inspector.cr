module Warp::Lang::Crystal
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
      tokens, err, pos = Lexer.scan(bytes)
      if err != Warp::Core::ErrorCode::Success
        diag = Warp::Diagnostics.lex_error("lexer fail", bytes, pos)
        puts diag.to_s
        return
      end

      root_green, parse_err = CST::Parser.parse(bytes, tokens)
      if parse_err != Warp::Core::ErrorCode::Success
        puts "Parser error: #{parse_err}"
        return
      end

      root_red = CST::RedNode.new(root_green)
      puts "CST (Red Tree):"
      print_red(root_red)
    end

    private def self.print_red(node : CST::RedNode, depth = 0)
      indent = "  " * depth
      parts = [] of String

      if text = node.text
        # Show full text for leaf nodes, truncate for non-leaves
        if node.children.empty?
          parts << "text=#{text.inspect}"
        else
          parts << "text=#{format_text(text)}"
        end
      end

      if payload = node.method_payload
        parts << "name=#{payload.name.inspect}"
        unless payload.params.empty?
          param_list = payload.params.map do |p|
            t = p.type ? p.type : "untyped"
            "#{p.name}:#{t}"
          end.join(", ")
          parts << "params=[#{param_list}]"
        end
        if payload.return_type
          parts << "return=#{payload.return_type}"
        end
        if payload.original_source
          # Show a short snippet of original source for context
          parts << "orig=#{format_text(payload.original_source.not_nil!, 120)}"
        end
      end

      suffix = parts.empty? ? "" : " #{parts.join(" ")}"
      puts "#{indent}- #{node.kind}#{suffix}"

      node.children.each do |child|
        print_red(child, depth + 1)
      end
    end

    private def self.format_text(text : String, max = 80) : String
      snippet = text
      if snippet.size > max
        snippet = snippet[0, max] + "…"
      end
      snippet.inspect
    end
  end
end
