module Warp::Lang::Ruby
  # CST-to-CST transpiler (Phase 1 core)
  # Ruby Green/Red CST -> TranspileContext -> Crystal Green/Red CST -> emit
  class CSTToCSTTranspiler
    struct Result
      property output : String
      property error : Warp::Core::ErrorCode
      property diagnostics : Array(String)
      property crystal_doc : Warp::Lang::Crystal::CST::Document?
      property tokens : Array(Token)?

      def initialize(@output, @error, @diagnostics = [] of String, @crystal_doc = nil, @tokens = nil)
      end
    end

    def self.transpile(bytes : Bytes, annotations : Annotations::AnnotationStore? = nil, path : String? = nil, config : TranspilerConfig? = nil) : Result
      # Step 1: Lex Ruby
      tokens, lex_error, lex_pos = Lexer.scan(bytes)
      if lex_error != Warp::Core::ErrorCode::Success
        diag = Warp::Diagnostics.lex_error("lex error", bytes, lex_pos, path)
        return Result.new("", lex_error, [diag.to_s], nil, tokens)
      end

      # Step 2: Parse Ruby CST
      ruby_root, parse_error = CST::Parser.parse(bytes, tokens)
      return Result.new("", parse_error, ["parse error"], nil) unless parse_error == Warp::Core::ErrorCode::Success
      return Result.new("", Warp::Core::ErrorCode::UnexpectedError, ["nil CST root"], nil) if ruby_root.nil?

      # Step 3: Semantic analysis (Ruby Red traversal)
      analyzer = SemanticAnalyzer.new(bytes, tokens, ruby_root, annotations || Annotations::AnnotationStore.new)
      context = analyzer.analyze

      # Step 4: Build Crystal CST (Green/Red)
      builder = Warp::Lang::Crystal::CSTBuilder.new
      crystal_doc = builder.build_from_context(context)

      # Step 5: Emit Crystal source
      output = Warp::Lang::Crystal::Serializer.emit(crystal_doc)

      # Step 6: Apply language-specific transformations (Ruby -> Crystal mappings)
      output = apply_ruby_to_crystal_mappings(output, config || TranspilerConfig.new)

      Result.new(output, Warp::Core::ErrorCode::Success, context.diagnostics, crystal_doc)
    end

    private struct Edit
      getter start : Int32
      getter end_pos : Int32
      getter text : String

      def initialize(@start : Int32, @end_pos : Int32, @text : String)
      end
    end

    private def self.transform_path_with_reverse_mappings(path : String, mappings : Hash(String, String)) : String
      return path if mappings.empty?

      # Parse the path into parts - reverse mappings (dst -> src)
      path_obj = Path.new(path)
      parts = path_obj.parts.dup

      # Try each mapping in reverse
      mappings.each do |src_dir, dst_dir|
        # Remove trailing slash for comparison if present
        src_name = src_dir.rstrip('/')
        dst_name = dst_dir.rstrip('/')

        # Find and replace the first occurrence of the destination directory name back to source
        parts.each_with_index do |part, idx|
          if part == dst_name
            parts[idx] = src_name
            # Only replace the first occurrence per mapping
            break
          end
        end
      end

      # Reconstruct path from parts
      if parts.empty?
        return path
      end

      # Preserve leading "./" or "../" patterns
      if path.starts_with?("../")
        # Count leading ../
        leading_ups = 0
        temp = path
        while temp.starts_with?("../")
          leading_ups += 1
          temp = temp[3..-1]
        end
        # Rebuild with leading ../
        result = "../" * leading_ups
        result += parts[leading_ups..-1].join("/") if leading_ups < parts.size
        return result
      elsif path.starts_with?("./")
        return "./" + parts[1..-1].join("/")
      else
        return parts.join("/")
      end
    end

    private def self.apply_ruby_to_crystal_mappings(source : String, config : TranspilerConfig) : String
      bytes = source.to_slice
      tokens, error, _ = Warp::Lang::Crystal::Lexer.scan(bytes)
      return source unless error == Warp::Core::ErrorCode::Success

      edits = [] of Edit
      folder_mappings = config.get_folder_mappings

      i = 0
      while i < tokens.size
        tok = tokens[i]
        if tok.kind == Warp::Lang::Crystal::TokenKind::Identifier
          text = String.new(bytes[tok.start, tok.length])
          if text == "require_relative"
            edits << Edit.new(tok.start, tok.start + tok.length, "require")

            # Also transform folder mappings when reverting to require using Path library
            # Look for the string token that follows
            j = i + 1
            while j < tokens.size && tokens[j].kind == Warp::Lang::Crystal::TokenKind::Newline
              j += 1
            end
            if j < tokens.size && tokens[j].kind == Warp::Lang::Crystal::TokenKind::String
              raw = String.new(bytes[tokens[j].start, tokens[j].length])

              # Transform path using reverse mappings (lib/ → src/)
              quote = raw[0]
              content = raw[1...-1] # Remove quotes
              new_content = transform_path_with_reverse_mappings(content, folder_mappings)

              # If path was changed, create an edit
              if new_content != content
                new_raw = "#{quote}#{new_content}#{quote}"
                edits << Edit.new(tokens[j].start, tokens[j].start + tokens[j].length, new_raw)
              end
            end
          end
        end

        if tok.kind == Warp::Lang::Crystal::TokenKind::LBrace
          if i + 6 < tokens.size &&
             tokens[i + 1].kind == Warp::Lang::Crystal::TokenKind::Pipe &&
             tokens[i + 2].kind == Warp::Lang::Crystal::TokenKind::Identifier &&
             tokens[i + 3].kind == Warp::Lang::Crystal::TokenKind::Pipe &&
             tokens[i + 4].kind == Warp::Lang::Crystal::TokenKind::Identifier &&
             tokens[i + 5].kind == Warp::Lang::Crystal::TokenKind::Dot &&
             tokens[i + 6].kind == Warp::Lang::Crystal::TokenKind::Identifier
            param_name = String.new(bytes[tokens[i + 2].start, tokens[i + 2].length])
            recv_name = String.new(bytes[tokens[i + 4].start, tokens[i + 4].length])
            if param_name == recv_name
              method_name = String.new(bytes[tokens[i + 6].start, tokens[i + 6].length])
              # find closing }
              j = i + 7
              while j < tokens.size && tokens[j].kind != Warp::Lang::Crystal::TokenKind::RBrace
                j += 1
              end
              if j < tokens.size
                edits << Edit.new(tokens[i].start, tokens[j].start + tokens[j].length, "&.#{method_name}")
              end
            end
          end
        end

        # Handle symbol-to-proc conversion: &:method_name → &.method_name (Ruby → Crystal)
        if tok.kind == Warp::Lang::Crystal::TokenKind::Ampersand && i + 2 < tokens.size
          if tokens[i + 1].kind == Warp::Lang::Crystal::TokenKind::Colon &&
             tokens[i + 2].kind == Warp::Lang::Crystal::TokenKind::Identifier
            method_name = String.new(bytes[tokens[i + 2].start, tokens[i + 2].length])
            # Convert &:method to &.method for Crystal
            replacement = "&.#{method_name}"
            start_pos = tok.start
            end_pos = tokens[i + 2].start + tokens[i + 2].length
            edits << Edit.new(start_pos, end_pos, replacement)
          end
        end

        i += 1
      end

      apply_edits(bytes, edits)
    end

    private def self.apply_edits(bytes : Bytes, edits : Array(Edit)) : String
      return String.new(bytes) if edits.empty?
      sorted = edits.sort_by(&.start)
      output = String::Builder.new
      pos = 0
      sorted.each do |edit|
        if edit.start > pos
          output.write(bytes[pos...edit.start])
        end
        output << edit.text
        pos = edit.end_pos
      end
      if pos < bytes.size
        output.write(bytes[pos..-1])
      end
      output.to_s
    end
  end
end
