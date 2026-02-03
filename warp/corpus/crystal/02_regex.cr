# Regular expressions in Crystal

# Regex literals
pattern1 = /hello/
pattern2 = /[0-9]+/
pattern3 = /(?<year>\d{4})-(?<month>\d{2})/

# Regex with flags
case_insensitive = /hello/i
multiline_regex = /^start/m
extended = /foo \s+ bar/x

# Percent regex
percent_regex = %r{/path/to/file}
percent_with_flags = %r{pattern}i

# Regex matching
if "hello123" =~ /\d+/
  puts "Contains digits"
end

# Named captures
date_pattern = /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/
"2024-01-15" =~ date_pattern
