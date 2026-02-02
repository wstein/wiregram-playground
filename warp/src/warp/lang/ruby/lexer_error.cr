module Warp::Lang::Ruby
  # Enhanced lexer error reporting with source context
  class LexerError
    getter error_code : Warp::Core::ErrorCode
    getter message : String
    getter source : Bytes
    getter position : Int32
    getter line : Int32
    getter column : Int32
    getter line_content : String
    getter context : String

    def initialize(
      @error_code : Warp::Core::ErrorCode,
      @message : String,
      @source : Bytes,
      @position : Int32,
    )
      @line, @column, @line_content, @context = extract_context(@source, @position)
    end

    def to_s : String
      String.build do |io|
        io << "LexError"
        io << " at #{@line}:#{@column}"
        io << ": #{@message}\n\n"
        io << @context
      end
    end

    private def extract_context(bytes : Bytes, position : Int32) : {Int32, Int32, String, String}
      return {1, 1, "", ""} if bytes.empty? || position < 0 || position > bytes.size

      # Calculate line and column
      line = 1
      column = 1
      line_start = 0

      bytes.each_with_index do |byte, idx|
        break if idx >= position
        if byte == '\n'.ord
          line += 1
          column = 1
          line_start = idx + 1
        else
          column += 1
        end
      end

      # Extract the line content
      line_end = line_start
      while line_end < bytes.size && bytes[line_end] != '\n'.ord && bytes[line_end] != '\r'.ord
        line_end += 1
      end
      line_content = String.new(bytes[line_start, line_end - line_start])

      # Build context with surrounding lines
      all_lines = String.new(bytes).lines
      context = build_context_snippet(all_lines, line, column)

      {line, column, line_content, context}
    end

    private def build_context_snippet(lines : Array(String), line_num : Int32, column_num : Int32) : String
      return "" if lines.empty? || line_num < 1

      context_before = 2
      context_after = 2

      start_line = Math.max(1, line_num - context_before)
      end_line = Math.min(lines.size, line_num + context_after)

      String.build do |io|
        (start_line..end_line).each do |num|
          line_content = lines[num - 1]? || ""

          if num == line_num
            io << " → "
          else
            io << "   "
          end

          io << sprintf("%4d | %s\n", num, line_content)

          # Add error pointer on problematic line
          if num == line_num
            io << "       "
            (0...column_num - 1).each { io << " " }
            io << "^\n"
          end
        end
      end
    end
  end
end
