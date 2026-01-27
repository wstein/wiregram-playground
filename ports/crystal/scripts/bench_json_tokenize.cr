require "../src/wiregram/languages/json"

path = ARGV[0]? || File.expand_path("../../../vendor/libucl/tests/rcl_test.json", __DIR__)
input = File.read(path)

start = Time.monotonic
count = 0
WireGram::Languages::Json.tokenize_stream(input) { |_t| count += 1 }

elapsed = Time.monotonic - start
puts "tokens=#{count} seconds=#{elapsed.total_seconds}"
