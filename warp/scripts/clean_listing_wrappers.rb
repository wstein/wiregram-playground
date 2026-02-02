#!/usr/bin/env ruby
require 'find'

Find.find('papers') do |path|
  next unless path.end_with?('.adoc')
  text = File.read(path)
  lines = text.lines
  changed = false
  i = 0
  out = []
  while i < lines.size
    line = lines[i]
    if line.strip == '----'
      # find prev non-empty line
      prev = nil
      j = i-1
      while j >= 0
        break if lines[j].strip != ''
        j -= 1
      end
      prev = lines[j] if j >= 0

      # find next non-empty line
      k = i+1
      while k < lines.size && lines[k].strip == ''
        k += 1
      end
      nxt = lines[k] if k < lines.size

      # If the next non-empty line is a heading or table start, remove this '----'
      if (nxt && nxt =~ /^={1,}\s+/) || (nxt && nxt.strip.start_with?('[cols')) || (nxt && nxt.strip.start_with?('|===')) || (prev && prev.strip.start_with?('|==='))
        changed = true
        # skip this line (remove)
        i += 1
        next
      end
    end
    out << line
    i += 1
  end

  if changed
    File.write(path, out.join)
    puts "Cleaned listing wrappers in #{path}"
  end
end
puts 'Done.'
