module Warp::Lang::Crystal
  # Crystal CST builder (Phase 1 scaffold)
  class CSTBuilder
    def build_from_context(context : Warp::Lang::Ruby::TranspileContext) : CST::Document
      bytes = context.bytes
      tokens = context.tokens
      source = context.source

      nodes = [] of CST::GreenNode
      cursor = 0

      i = 0
      while i < tokens.size
        tok = tokens[i]
        if tok.kind == Warp::Lang::Ruby::TokenKind::Def
          def_start = tok.start
          if def_start > cursor
            nodes << CST::GreenNode.new(
              CST::NodeKind::RawText,
              [] of CST::GreenNode,
              String.new(bytes[cursor, def_start - cursor]),
            )
          end

          header_end = find_header_end(tokens, i, bytes.size)
          header_text = String.new(bytes[def_start, header_end - def_start])
          method_name, param_names, had_parens = parse_method_header(header_text)

          end_idx, end_end = find_method_end(tokens, i, bytes.size)
          body_text = header_end < end_end ? String.new(bytes[header_end, end_end - header_end]) : ""

          sig = method_name ? context.annotations.resolve(method_name) : nil
          param_infos = build_param_infos(param_names, sig)
          return_type = resolve_return_type(sig)

          payload = if method_name
                      CST::MethodDefPayload.new(method_name, param_infos, return_type, body_text, had_parens)
                    else
                      CST::MethodDefPayload.new("<anonymous>", param_infos, return_type, body_text, had_parens)
                    end

          nodes << CST::GreenNode.new(
            CST::NodeKind::MethodDef,
            [] of CST::GreenNode,
            nil,
            [] of Warp::Lang::Crystal::Token,
            payload,
          )

          cursor = end_end
          i = end_idx + 1
          next
        end

        i += 1
      end

      if cursor < bytes.size
        nodes << CST::GreenNode.new(
          CST::NodeKind::RawText,
          [] of CST::GreenNode,
          String.new(bytes[cursor, bytes.size - cursor]),
        )
      end

      root = CST::GreenNode.new(CST::NodeKind::Root, nodes)
      CST::Document.new(bytes, CST::RedNode.new(root))
    end

    private def find_header_end(tokens : Array(Warp::Lang::Ruby::Token), start_idx : Int32, size : Int32) : Int32
      i = start_idx
      while i < tokens.size
        tok = tokens[i]
        return tok.start + tok.length if tok.kind == Warp::Lang::Ruby::TokenKind::Newline
        i += 1
      end
      size
    end

    private def find_method_end(tokens : Array(Warp::Lang::Ruby::Token), start_idx : Int32, size : Int32) : {Int32, Int32}
      i = start_idx
      while i < tokens.size
        tok = tokens[i]
        if tok.kind == Warp::Lang::Ruby::TokenKind::End
          return {i, tok.start + tok.length}
        end
        i += 1
      end
      {tokens.size - 1, size}
    end

    private def parse_method_header(header : String) : {String?, Array(String), Bool}
      if (md = header.match(/^\s*def\s+((self\.)?([A-Za-z0-9_!?=]+))\s*(\(([^)]*)\))?/))
        name = md[2]? ? "self.#{md[3]}" : md[3]
        params = parse_param_names(md[5]?)
        had_parens = !md[4]?.nil?
        return {name, params, had_parens}
      end
      {nil, [] of String, false}
    end

    private def parse_param_names(params_str : String?) : Array(String)
      return [] of String if params_str.nil?
      params_str.split(',').map do |raw|
        name = raw.strip
        name = name.split("=", 2)[0].strip
        name = name.sub(/^\*\*?/, "")
        name = name.sub(/^&/, "")
        name = name.sub(/:$/, "")
        name
      end.reject(&.empty?)
    end

    private def build_param_infos(param_names : Array(String), sig : Warp::Lang::Ruby::Annotations::RbsMethodSignature?) : Array(CST::ParamInfo)
      params = [] of CST::ParamInfo
      param_names.each_with_index do |name, idx|
        type = sig ? (sig.params[name]? || sig.params["arg#{idx}"]?) : nil
        params << CST::ParamInfo.new(name, type ? convert_rbs_type_to_crystal(type) : nil)
      end
      params
    end

    private def resolve_return_type(sig : Warp::Lang::Ruby::Annotations::RbsMethodSignature?) : String?
      return nil unless sig
      return "Nil" if sig.is_void
      sig.return_type ? convert_rbs_type_to_crystal(sig.return_type.not_nil!) : nil
    end

    private def convert_rbs_type_to_crystal(type_str : String) : String
      t = type_str.strip
      if t.ends_with?("?")
        inner = t[0...-1]
        return "#{convert_rbs_type_to_crystal(inner)} | Nil"
      end

      if t.includes?("|")
        parts = t.split("|").map(&.strip)
        return parts.map { |p| convert_rbs_type_to_crystal(p) }.join(" | ")
      end

      if (md = t.match(/^Array\[(.+)\]$/))
        return "Array(#{convert_rbs_type_to_crystal(md[1])})"
      end

      if (md = t.match(/^Hash\[(.+),\s*(.+)\]$/))
        return "Hash(#{convert_rbs_type_to_crystal(md[1])}, #{convert_rbs_type_to_crystal(md[2])})"
      end

      case t
      when "Integer"
        "Int32"
      when "Float"
        "Float64"
      when "bool"
        "Bool"
      when "nil"
        "Nil"
      when "untyped"
        "Object"
      else
        t
      end
    end
  end
end
