module Warp::Lang::Ruby::Annotations
  class InlineRbsInjector
    def self.inject(source : String, sigs : Array(SigInfo)) : String
      return source if sigs.empty?
      lines = source.lines
      # map def_start to line index
      inserts = [] of {Int32, String}
      sigs.each do |sig|
        line_idx = line_index_for(source, sig.def_start)
        inserts << {line_idx, RbsGenerator.inline_comment(sig)} if line_idx >= 0
      end

      inserts.sort_by! { |i| i[0] }
      offset = 0
      inserts.each do |idx, text|
        insert_at = idx + offset
        lines.insert(insert_at, text)
        offset += 1
      end

      lines.join("\n")
    end

    private def self.line_index_for(source : String, pos : Int32) : Int32
      return -1 if pos < 0
      count = 0
      i = 0
      while i < source.size && i < pos
        if source[i] == '\n'
          count += 1
        end
        i += 1
      end
      count
    end
  end
end
