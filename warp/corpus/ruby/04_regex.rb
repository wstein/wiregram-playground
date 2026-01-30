# Regular expressions
pattern1 = /\d+/
pattern2 = %r{/path/to/file}
pattern3 = /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/

def match_test(string)
  if string =~ /[0-9]+/
    puts "Contains digits"
  end
end

def gsub_example(text)
  text.gsub(/\s+/, '_')
end
