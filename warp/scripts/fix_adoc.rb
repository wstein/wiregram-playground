#!/usr/bin/env ruby
require 'find'

def process_file(path)
  text = File.read(path)
  lines = text.lines

  # Track whether we're inside a source/listing block (----) or a table ([cols], |===) or a literal block.
  in_listing = false
  in_table = false
  first_title_seen = false
  changed = false

  out = []
  lines.each_with_index do |line, idx|
    stripped = line.rstrip

    # Toggle listing blocks (----) - handle start and end
    if stripped =~ /^\s*----\s*$/
      in_listing = !in_listing
      out << line
      next
    end

    # Toggle table blocks
    if stripped =~ /^\s*\|===\s*$/
      in_table = !in_table
      out << line
      next
    end

    if in_listing || in_table
      out << line
      next
    end

    # Normalize extra document titles: keep first top-level '=' as is, demote others
    if stripped =~ /^=\s+/ && !first_title_seen
      first_title_seen = true
      out << line
      next
    elsif stripped =~ /^=+\s+/ && first_title_seen
      # Replace any leading =+ with '== '
      new_line = line.sub(/^=+\s+/, '== ')
      out << new_line
      changed = true if new_line != line
      next
    end

    # Normalize numbered lists to '1.' to avoid index warnings
    if stripped =~ /^\s*\d+\.\s+/ && !(stripped =~ /^\s*\d+\.\s+\#/) # avoid special formats
      new_line = line.sub(/^\s*\d+\./, '1.')
      out << new_line
      changed = true if new_line != line
      next
    end

    out << line
  end

  # Now ensure listing blocks are balanced
  text2 = out.join
  listing_count = text2.scan(/^\s*----\s*$/).size
  if listing_count.odd?
    text2 += "\n----\n"
    changed = true
  end

  table_count = text2.scan(/^\s*\|===\s*$/).size
  if table_count.odd?
    text2 += "\n|===\n"
    changed = true
  end

  # Write back if changed
  if changed
    File.write(path, text2)
    puts "Patched #{path}"
  end
end

Find.find('papers') do |path|
  next unless path.end_with?('.adoc')
  process_file(path)
end
puts 'Done.'
