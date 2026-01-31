module Warp::Lang::Ruby
  # Rewriter applies minimal edits to source code while preserving all formatting and trivia.
  # Based on byte positions from tokens, it can remove, replace, or insert spans.
  #
  # Example:
  #   rewriter = Rewriter.new(source_bytes, tokens)
  #   rewriter.remove(10, 20)  # Remove bytes 10-20
  #   rewriter.replace(30, 40, "new text")  # Replace bytes 30-40
  #   output = rewriter.emit  # Generate modified source
  class Rewriter
    # Represents a single edit operation
    private enum Op
      Remove
      Replace
      Insert
    end

    private struct Edit
      property op : Op
      property start : Int32
      property end_pos : Int32
      property text : String

      def initialize(@op, @start, @end_pos, @text = "")
      end

      def <=>(other : Edit)
        # Sort by start position, then by operation type
        cmp = @start <=> other.start
        return cmp if cmp != 0
        @op.value <=> other.op.value
      end
    end

    @bytes : Bytes
    @tokens : Array(Token)
    @edits : Array(Edit)

    def initialize(@bytes, @tokens)
      @edits = [] of Edit
    end

    # Remove bytes from start (inclusive) to end_pos (exclusive)
    def remove(start : Int32, end_pos : Int32)
      @edits << Edit.new(Op::Remove, start, end_pos)
      self
    end

    # Replace bytes from start (inclusive) to end_pos (exclusive) with text
    def replace(start : Int32, end_pos : Int32, text : String)
      @edits << Edit.new(Op::Replace, start, end_pos, text)
      self
    end

    # Insert text at position (before the byte at position)
    def insert(pos : Int32, text : String)
      @edits << Edit.new(Op::Insert, pos, pos, text)
      self
    end

    # Emit the rewritten source code
    def emit : String
      # Sort edits by position
      sorted_edits = @edits.sort

      # Build output
      output = String::Builder.new
      pos = 0

      sorted_edits.each do |edit|
        # Copy bytes before this edit
        if edit.start > pos
          output.write(@bytes[pos...edit.start])
        end

        # Apply the edit
        case edit.op
        when Op::Remove
          # Skip the removed bytes
          pos = edit.end_pos
        when Op::Replace
          # Skip the replaced bytes and insert new text
          output << edit.text
          pos = edit.end_pos
        when Op::Insert
          # Insert text without advancing past current position
          output << edit.text
          pos = edit.start
        end
      end

      # Copy remaining bytes
      if pos < @bytes.size
        output.write(@bytes[pos..-1])
      end

      output.to_s
    end
  end
end
