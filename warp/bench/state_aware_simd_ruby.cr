#!/usr/bin/env crystal

require "../src/warp"

# Benchmark state-aware SIMD helpers on Ruby code samples
# Measures scanning performance for strings, heredocs, regex, and interpolation

module SimdBenchmarks
  extend self

  # Ruby code samples with various string and regex patterns
  RUBY_STRING_SAMPLE = %{
"Simple string"
"String with \\"escaped quotes\\""
"String with #{interpolation} here"
"Multiline
 string here"
%w[array of words]
%q{quoted string}
%Q{quoted with #{interpolation}}
}.to_slice

  RUBY_REGEX_SAMPLE = %{
/simple pattern/
/pattern with [character] class/
/pattern with (groups)/
/pattern with \\d+ escapes/
%r{regex with delimiter}
}.to_slice

  RUBY_HEREDOC_SAMPLE = %{
<<EOF
This is a heredoc
with multiple lines
EOF

<<-'INDENTED'
Indented heredoc
with content
INDENTED
}.to_slice

  RUBY_COMPLEX_SAMPLE = %{
class User
  def initialize(name)
    @name = name
    @email = "user@example.com"
  end

  def greet
    puts "Hello #{@name}!"
    /pattern/.match?(@name)
  end

  def multiline
    <<~TEXT
      Indented heredoc
      with interpolation: #{Time.now}
    TEXT
  end
end
}.to_slice

  def benchmark_string_scanning(backend : Warp::Backend::Base, iterations : Int32 = 1000)
    start_time = Time.monotonic

    iterations.times do
      Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
        RUBY_STRING_SAMPLE,
        0_u32,
        34_u8,  # double quote
        backend
      )
    end

    elapsed = Time.monotonic - start_time
    rate_mbps = (RUBY_STRING_SAMPLE.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)

    {
      name: "String scanning",
      backend: backend.class.name,
      iterations: iterations,
      elapsed: elapsed,
      rate_mbps: rate_mbps
    }
  end

  def benchmark_regex_scanning(backend : Warp::Backend::Base, iterations : Int32 = 1000)
    start_time = Time.monotonic

    iterations.times do
      Warp::Lang::Common::StateAwareSimdHelpers.scan_regex_interior(
        RUBY_REGEX_SAMPLE,
        0_u32,
        backend
      )
    end

    elapsed = Time.monotonic - start_time
    rate_mbps = (RUBY_REGEX_SAMPLE.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)

    {
      name: "Regex scanning",
      backend: backend.class.name,
      iterations: iterations,
      elapsed: elapsed,
      rate_mbps: rate_mbps
    }
  end

  def benchmark_heredoc_scanning(backend : Warp::Backend::Base, iterations : Int32 = 1000)
    start_time = Time.monotonic

    iterations.times do
      Warp::Lang::Common::StateAwareSimdHelpers.scan_heredoc_content(
        RUBY_HEREDOC_SAMPLE,
        0_u32,
        "EOF",
        backend
      )
    end

    elapsed = Time.monotonic - start_time
    rate_mbps = (RUBY_HEREDOC_SAMPLE.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)

    {
      name: "Heredoc scanning",
      backend: backend.class.name,
      iterations: iterations,
      elapsed: elapsed,
      rate_mbps: rate_mbps
    }
  end

  def benchmark_complex_code(backend : Warp::Backend::Base, iterations : Int32 = 100)
    start_time = Time.monotonic

    iterations.times do
      # Scan for strings
      Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
        RUBY_COMPLEX_SAMPLE,
        0_u32,
        34_u8,
        backend
      )

      # Scan for regexes
      Warp::Lang::Common::StateAwareSimdHelpers.scan_regex_interior(
        RUBY_COMPLEX_SAMPLE,
        0_u32,
        backend
      )
    end

    elapsed = Time.monotonic - start_time
    rate_mbps = (RUBY_COMPLEX_SAMPLE.size.to_f * iterations * 2) / elapsed.total_seconds / (1024 * 1024)

    {
      name: "Complex code (strings + regex)",
      backend: backend.class.name,
      iterations: iterations,
      elapsed: elapsed,
      rate_mbps: rate_mbps
    }
  end

  def format_result(result : Hash) : String
    "#{result[:name]:30} | Backend: #{result[:backend]:15} | Rate: #{result[:rate_mbps]:10.2f} MB/s | Time: #{result[:elapsed].total_milliseconds:8.2f} ms"
  end

  def run
    puts "=" * 120
    puts "State-Aware SIMD Helpers - Ruby Scanning Benchmarks"
    puts "=" * 120
    puts

    backend = Warp::Backend.current

    benchmarks = [
      benchmark_string_scanning(backend, 2000),
      benchmark_regex_scanning(backend, 2000),
      benchmark_heredoc_scanning(backend, 1000),
      benchmark_complex_code(backend, 500),
    ]

    puts "RESULTS:"
    puts "-" * 120
    benchmarks.each { |result| puts format_result(result) }
    puts "-" * 120
    puts

    # Compute aggregate stats
    total_time = benchmarks.map { |r| r[:elapsed] }.sum
    avg_rate = benchmarks.map { |r| r[:rate_mbps] }.sum / benchmarks.size

    puts "Summary:"
    puts "  Total time: #{total_time.total_milliseconds.to_i} ms"
    puts "  Average throughput: #{avg_rate.to_i} MB/s"
    puts "  Backend: #{backend.class.name}"
    puts "=" * 120
  end
end

SimdBenchmarks.run
