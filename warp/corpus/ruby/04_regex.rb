# typed: strict
# Regular expressions
pattern1 = T.let(/\d+/, Regexp)
pattern2 = T.let(%r{/path/to/file}, Regexp)
pattern3 = T.let(/(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/, Regexp)

def match_test(string)
  if string =~ /[0-9]+/
    puts "Contains digits"
  end
end

def gsub_example(text)
  text.gsub(/\s+/, '_')
end

# Ruby 3.4: Byte-based MatchData
match = "foo".match(/o/)
match.bytebegin(0) #=> 1
