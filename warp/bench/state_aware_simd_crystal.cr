#!/usr/bin/env crystal

require "../src/warp"

# Benchmark state-aware SIMD helpers on Crystal code samples
# Measures scanning performance for strings, regex, and Crystal-specific patterns

module SimdBenchmarks
  extend self

  # Crystal code samples with various string and regex patterns
  CRYSTAL_STRING_SAMPLE = %{
"Simple string"
"String with \\"escaped quotes\\""
"String with #{interpolation} here"
"Multiline
 string here"
%w[array of words]
%q{quoted string}
%Q{quoted with #{interpolation}}
}.to_slice

  CRYSTAL_REGEX_SAMPLE = %{
/simple pattern/
/pattern with [character] class/
/pattern with (groups)/
/pattern with \\d+ escapes/
%r{regex with delimiter}
}.to_slice

  CRYSTAL_MACRO_SAMPLE = %{
{% if flag?(:x86_64) %}
  puts "x86_64"
{% end %}

macro helper(x)
  "Value: #{x}"
end

{% for i in 0...10 %}
  def method_{{i}}
    "Method {{i}}"
  end
{% end %}
}.to_slice

  CRYSTAL_ANNOTATION_SAMPLE = %{
@[JSON::Field(key: "user_id")]
property user_id : Int32

@[Link("m")]
lib LibM
  fun sqrt(x : Float64) : Float64
end

@[Deprecated("Use new_method instead")]
def old_method
  new_method
end
}.to_slice

  CRYSTAL_COMPLEX_SAMPLE = %{
class Server
  @[Link("curl")]
  lib LibCurl
    fun easy_init : Void*
  end

  def initialize(@host : String)
    @port = 8080
    @url = "http://#{@host}:#{@port}"
  end

  {% if flag?(:release) %}
    def process
      /pattern/.match?(@url)
    end
  {% end %}

  def render_template
    "Server at #{@url}"
  end
end
}.to_slice

  def benchmark_string_scanning(backend : Warp::Backend::Base, iterations : Int32 = 1000)
    start_time = Time.monotonic

    iterations.times do
      Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
        CRYSTAL_STRING_SAMPLE,
        0_u32,
        34_u8,  # double quote
        backend
      )
    end

    elapsed = Time.monotonic - start_time
    rate_mbps = (CRYSTAL_STRING_SAMPLE.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)

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
        CRYSTAL_REGEX_SAMPLE,
        0_u32,
        backend
      )
    end

    elapsed = Time.monotonic - start_time
    rate_mbps = (CRYSTAL_REGEX_SAMPLE.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)

    {
      name: "Regex scanning",
      backend: backend.class.name,
      iterations: iterations,
      elapsed: elapsed,
      rate_mbps: rate_mbps
    }
  end

  def benchmark_macro_scanning(backend : Warp::Backend::Base, iterations : Int32 = 1000)
    start_time = Time.monotonic

    iterations.times do
      Warp::Lang::Common::StateAwareSimdHelpers.scan_macro_interior(
        CRYSTAL_MACRO_SAMPLE,
        0_u32,
        backend
      )
    end

    elapsed = Time.monotonic - start_time
    rate_mbps = (CRYSTAL_MACRO_SAMPLE.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)

    {
      name: "Macro scanning",
      backend: backend.class.name,
      iterations: iterations,
      elapsed: elapsed,
      rate_mbps: rate_mbps
    }
  end

  def benchmark_annotation_scanning(backend : Warp::Backend::Base, iterations : Int32 = 1000)
    start_time = Time.monotonic

    iterations.times do
      Warp::Lang::Common::StateAwareSimdHelpers.scan_annotation_interior(
        CRYSTAL_ANNOTATION_SAMPLE,
        0_u32,
        backend
      )
    end

    elapsed = Time.monotonic - start_time
    rate_mbps = (CRYSTAL_ANNOTATION_SAMPLE.size.to_f * iterations) / elapsed.total_seconds / (1024 * 1024)

    {
      name: "Annotation scanning",
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
        CRYSTAL_COMPLEX_SAMPLE,
        0_u32,
        34_u8,
        backend
      )

      # Scan for regexes
      Warp::Lang::Common::StateAwareSimdHelpers.scan_regex_interior(
        CRYSTAL_COMPLEX_SAMPLE,
        0_u32,
        backend
      )

      # Scan for macros
      Warp::Lang::Common::StateAwareSimdHelpers.scan_macro_interior(
        CRYSTAL_COMPLEX_SAMPLE,
        0_u32,
        backend
      )
    end

    elapsed = Time.monotonic - start_time
    rate_mbps = (CRYSTAL_COMPLEX_SAMPLE.size.to_f * iterations * 3) / elapsed.total_seconds / (1024 * 1024)

    {
      name: "Complex code (strings + regex + macros)",
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
    puts "State-Aware SIMD Helpers - Crystal Scanning Benchmarks"
    puts "=" * 120
    puts

    backend = Warp::Backend.current

    benchmarks = [
      benchmark_string_scanning(backend, 2000),
      benchmark_regex_scanning(backend, 2000),
      benchmark_macro_scanning(backend, 1000),
      benchmark_annotation_scanning(backend, 1000),
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
