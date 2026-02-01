module Warp
  # Enhanced error reporting with source context
  class DiagnosticError < Exception
    getter file_path : String?
    getter line : Int32?
    getter column : Int32?
    getter source_snippet : String?
    getter error_type : String

    def initialize(
      message : String,
      @file_path : String? = nil,
      @line : Int32? = nil,
      @column : Int32? = nil,
      @source_snippet : String? = nil,
      @error_type : String = "Error",
    )
      super(message)
    end

    # Create a diagnostic error from source bytes and position
    def self.from_source(
      message : String,
      source : Bytes,
      position : Int32,
      file_path : String? = nil,
      error_type : String = "Error",
    ) : self
      line, column, snippet = extract_context(source, position)
      new(message, file_path, line, column, snippet, error_type)
    end

    # Format the error with rich context
    def to_s(io : IO)
      if path = @file_path
        io << "#{@error_type} in #{path}"
        io << ":#{@line}:#{@column}" if @line && @column
        io << "\n"
      else
        io << "#{@error_type}: "
      end

      io << message

      if snippet = @source_snippet
        io << "\n\n"
        io << snippet
      end
    end

    private def self.extract_context(source : Bytes, position : Int32) : {Int32, Int32, String}
      return {1, 1, ""} if source.empty? || position < 0

      # Find line and column
      line_num = 1
      column_num = 1
      line_start = 0

      source.each_with_index do |byte, idx|
        break if idx >= position

        if byte == '\n'.ord
          line_num += 1
          column_num = 1
          line_start = idx + 1
        else
          column_num += 1
        end
      end

      # Extract the problematic line and surrounding context
      lines = String.new(source).lines
      snippet = build_snippet(lines, line_num, column_num)

      {line_num, column_num, snippet}
    end

    private def self.build_snippet(lines : Array(String), line_num : Int32, column_num : Int32) : String
      return "" if lines.empty?

      # Show 2 lines before and after
      context_before = 2
      context_after = 2

      start_line = Math.max(1, line_num - context_before)
      end_line = Math.min(lines.size, line_num + context_after)

      snippet = String.build do |io|
        (start_line..end_line).each do |num|
          line_content = lines[num - 1]? || ""
          line_prefix = num == line_num ? " → " : "   "
          io << sprintf("%s%4d | %s\n", line_prefix, num, line_content)

          # Add error pointer on the problematic line
          if num == line_num
            pointer_offset = column_num - 1
            io << "        " << (" " * pointer_offset) << "^\n"
          end
        end
      end

      snippet
    end
  end

  # Helper to create diagnostic errors
  module Diagnostics
    extend self

    def lex_error(message : String, source : Bytes, position : Int32, file_path : String? = nil) : DiagnosticError
      DiagnosticError.from_source("Lexical error: #{message}", source, position, file_path, "LexError")
    end

    def parse_error(message : String, source : Bytes, position : Int32, file_path : String? = nil) : DiagnosticError
      DiagnosticError.from_source("Parse error: #{message}", source, position, file_path, "ParseError")
    end

    def transpile_error(message : String, source : Bytes, position : Int32, file_path : String? = nil) : DiagnosticError
      DiagnosticError.from_source("Transpile error: #{message}", source, position, file_path, "TranspileError")
    end

    def type_error(message : String, file_path : String? = nil, line : Int32? = nil) : DiagnosticError
      DiagnosticError.new("Type error: #{message}", file_path, line, nil, nil, "TypeError")
    end
  end
end
