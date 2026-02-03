require "./src/warp"

# Read test files
ruby_bytes = File.read("tmp/simd_pattern_test.rb").to_slice
crystal_bytes = File.read("tmp/simd_pattern_test.cr").to_slice

puts "=" * 60
puts "RUBY SIMD PATTERN DETECTION"
puts "=" * 60

puts "\n🔍 Heredoc Boundaries:"
heredocs = Warp::Lang::Ruby.detect_heredoc_boundaries(ruby_bytes)
puts "Found #{heredocs.size} heredoc markers at offsets: #{heredocs.inspect}"

puts "\n🔍 Regex Delimiters:"
regexes = Warp::Lang::Ruby.detect_regex_delimiters(ruby_bytes)
puts "Found #{regexes.size} regex patterns at offsets: #{regexes.inspect}"

puts "\n🔍 String Interpolation:"
interpolations = Warp::Lang::Ruby.detect_string_interpolation(ruby_bytes)
puts "Found #{interpolations.size} interpolation markers at offsets: #{interpolations.inspect}"

puts "\n🔍 All Ruby Patterns:"
all_ruby = Warp::Lang::Ruby.detect_all_patterns(ruby_bytes)
all_ruby.each do |pattern_type, indices|
  puts "  #{pattern_type}: #{indices.size} occurrences"
end

puts "\n" + "=" * 60
puts "CRYSTAL SIMD PATTERN DETECTION"
puts "=" * 60

puts "\n🔍 Macro Boundaries:"
macros = Warp::Lang::Crystal.detect_macro_boundaries(crystal_bytes)
puts "Found #{macros.size} macro regions at offsets: #{macros.inspect}"

puts "\n🔍 Annotations:"
annotations = Warp::Lang::Crystal.detect_annotations(crystal_bytes)
puts "Found #{annotations.size} annotations at offsets: #{annotations.inspect}"

puts "\n🔍 Type Boundaries:"
types = Warp::Lang::Crystal.detect_type_boundaries(crystal_bytes)
puts "Found #{types.size} type markers at offsets: #{types.inspect}"

puts "\n🔍 All Crystal Patterns:"
all_crystal = Warp::Lang::Crystal.detect_all_patterns(crystal_bytes)
all_crystal.each do |pattern_type, indices|
  puts "  #{pattern_type}: #{indices.size} occurrences"
end

puts "\n" + "=" * 60
puts "SIMD DUMP VERIFICATION (All Languages)"
puts "=" * 60

# Test via CLI dumps
puts "\n📊 Ruby SIMD (showing structural chars + whitespace):"
system("crystal run bin/warp.cr -- dump simd --lang ruby tmp/simd_pattern_test.rb 2>&1 | head -15")

puts "\n📊 Crystal SIMD (showing structural chars + whitespace):"
system("crystal run bin/warp.cr -- dump simd --lang crystal tmp/simd_pattern_test.cr 2>&1 | head -15")

puts "\n✅ All tests completed!"
