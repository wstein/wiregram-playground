#!/usr/bin/env ruby

require 'find'

Find.find('papers') do |path|
  next unless path.end_with?('.adoc')
  text = File.read(path)
  changed = false

  # Replace opening fenced block ```lang or ``` with AsciiDoc source block
  text2 = text.gsub(/^([ \t]*)(```)([a-zA-Z0-9_-]+)\s*$/) do
    indent = $1
    lang = $3
    changed = true
    "#{indent}[source,#{lang}]\n#{indent}----"
  end

  # Replace closing fences
  text2 = text2.gsub(/^([ \t]*)(```)\s*$/) do
    indent = $1
    changed = true
    "#{indent}----"
  end

  if changed
    File.write(path, text2)
    puts "Updated fenced blocks in: #{path}"
  end
end
