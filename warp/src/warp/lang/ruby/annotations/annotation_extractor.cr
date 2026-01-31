module Warp::Lang::Ruby::Annotations
  struct SigInfo
    getter sig_text : String
    getter method_name : String
    getter params : Hash(String, String)
    getter return_type : String?
    getter is_void : Bool
    getter param_list : Array(String)
    getter def_start : Int32
    getter def_indent : String

    def initialize(
      @sig_text : String,
      @method_name : String,
      @params : Hash(String, String),
      @return_type : String?,
      @is_void : Bool,
      @param_list : Array(String),
      @def_start : Int32,
      @def_indent : String,
    )
    end
  end

  # Extracts Sorbet sig blocks and corresponding method definitions using token scanning.
  class AnnotationExtractor
    @bytes : Bytes
    @tokens : Array(Token)

    def initialize(@bytes : Bytes, @tokens : Array(Token))
    end

    def extract : Array(SigInfo)
      results = [] of SigInfo
      idx = 0
      while idx < @tokens.size
        tok = @tokens[idx]
        if tok.kind == TokenKind::Identifier && token_text(tok) == "sig"
          sig_end_idx, sig_text = extract_sig_block(idx)
          if sig_end_idx >= 0
            def_idx = find_next_def(sig_end_idx + 1)
            if def_idx >= 0
              method_name, param_list, def_start, def_indent = extract_def_signature(def_idx)
              parser = SorbetRbsParser.new(sig_text)
              sig = parser.parse_sig
              results << SigInfo.new(
                sig_text,
                method_name,
                sig.params,
                sig.return_type,
                sig.is_void,
                param_list,
                def_start,
                def_indent,
              )
              idx = def_idx
            else
              idx = sig_end_idx
            end
          end
        end
        idx += 1
      end
      results
    end

    private def find_next_def(start_idx : Int32) : Int32
      idx = start_idx
      while idx < @tokens.size
        if @tokens[idx].kind == TokenKind::Def
          return idx
        end
        idx += 1
      end
      -1
    end

    private def extract_def_signature(def_idx : Int32) : {String, Array(String), Int32, String}
      def_tok = @tokens[def_idx]
      start_pos = def_tok.start
      indent = leading_indent(start_pos)

      idx = next_non_trivia_index(def_idx + 1)
      method_name = "unknown"

      if idx >= 0
        if token_text(@tokens[idx]) == "self"
          dot_idx = next_non_trivia_index(idx + 1)
          name_idx = next_non_trivia_index(dot_idx + 1)
          if dot_idx >= 0 && @tokens[dot_idx].kind == TokenKind::Dot && name_idx >= 0
            method_name = token_text(@tokens[name_idx])
            idx = name_idx + 1
          end
        else
          method_name = token_text(@tokens[idx])
          idx += 1
        end
      end

      param_list = [] of String
      idx = next_non_trivia_index(idx)
      if idx >= 0 && @tokens[idx].kind == TokenKind::LParen
        close_idx = find_matching_rparen(idx)
        if close_idx > idx
          params_text = slice_between(@tokens[idx].start + @tokens[idx].length, @tokens[close_idx].start)
          param_list = ParamParser.parse_param_names(params_text)
        end
      else
        # no parens - read until newline or end
        params_text = read_until_newline_or_end(idx)
        param_list = ParamParser.parse_param_names(params_text)
      end

      {method_name, param_list, start_pos, indent}
    end

    private def extract_sig_block(sig_idx : Int32) : {Int32, String}
      start_tok = @tokens[sig_idx]
      idx = next_non_trivia_index(sig_idx + 1)
      return {-1, ""} if idx < 0

      if @tokens[idx].kind == TokenKind::LBrace
        depth = 1
        j = idx + 1
        while j < @tokens.size && depth > 0
          case @tokens[j].kind
          when TokenKind::LBrace
            depth += 1
          when TokenKind::RBrace
            depth -= 1
          end
          j += 1
        end
        end_idx = j - 1
        end_pos = @tokens[end_idx].start + @tokens[end_idx].length
        sig_text = slice_between(start_tok.start, end_pos)
        {end_idx, sig_text}
      elsif @tokens[idx].kind == TokenKind::Do
        depth = 1
        j = idx + 1
        while j < @tokens.size && depth > 0
          case @tokens[j].kind
          when TokenKind::Do
            depth += 1
          when TokenKind::End
            depth -= 1
          end
          j += 1
        end
        end_idx = j - 1
        end_pos = @tokens[end_idx].start + @tokens[end_idx].length
        sig_text = slice_between(start_tok.start, end_pos)
        {end_idx, sig_text}
      else
        {-1, ""}
      end
    end

    private def read_until_newline_or_end(idx : Int32) : String
      return "" if idx < 0
      start_pos = @tokens[idx].start
      j = idx
      while j < @tokens.size
        kind = @tokens[j].kind
        break if kind == TokenKind::Newline || kind == TokenKind::End
        j += 1
      end
      end_pos = j < @tokens.size ? @tokens[j].start : @bytes.size
      slice_between(start_pos, end_pos)
    end

    private def find_matching_rparen(start_idx : Int32) : Int32
      depth = 0
      j = start_idx
      while j < @tokens.size
        case @tokens[j].kind
        when TokenKind::LParen
          depth += 1
        when TokenKind::RParen
          depth -= 1
          return j if depth == 0
        end
        j += 1
      end
      -1
    end

    private def next_non_trivia_index(start_idx : Int32) : Int32
      idx = start_idx
      while idx < @tokens.size
        kind = @tokens[idx].kind
        if kind != TokenKind::Whitespace && kind != TokenKind::Newline && kind != TokenKind::CommentLine
          return idx
        end
        idx += 1
      end
      -1
    end

    private def token_text(token : Token) : String
      String.new(@bytes[token.start, token.length])
    end

    private def slice_between(start_pos : Int32, end_pos : Int32) : String
      return "" if end_pos <= start_pos
      String.new(@bytes[start_pos, end_pos - start_pos])
    end

    private def leading_indent(pos : Int32) : String
      i = pos - 1
      while i >= 0 && @bytes[i] != '\n'.ord
        i -= 1
      end
      start = i + 1
      slice = String.new(@bytes[start, pos - start])
      slice[/^\s*/].to_s
    end
  end
end

module Warp::Lang::Ruby::Annotations
  module ParamParser
    def self.parse_param_names(params_text : String) : Array(String)
      names = [] of String
      current = ""
      depth = 0
      params_text.each_char do |char|
        case char
        when '(', '[', '{'
          depth += 1
          current += char
        when ')', ']', '}'
          depth -= 1
          current += char
        when ','
          if depth == 0
            name = extract_name(current)
            names << name if !name.empty?
            current = ""
          else
            current += char
          end
        else
          current += char
        end
      end
      name = extract_name(current)
      names << name if !name.empty?
      names
    end

    private def self.extract_name(param : String) : String
      p = param.strip
      return "" if p.empty?
      p = p[1..-1] if p.starts_with?('&')
      p = p.split("=")[0].strip if p.includes?('=')
      p = p[0...-1] if p.ends_with?(':')
      p.strip
    end
  end
end
