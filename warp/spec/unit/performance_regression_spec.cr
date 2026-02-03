require "../spec_helper"

describe "SIMD Performance Regression Tests" do
  describe "String scanning performance" do
    it "maintains throughput for simple strings" do
      ruby_strings = "\"hello\", \"world\", \"test string\""
      ruby_code = ruby_strings.to_slice

      backend = Warp::Backend.current

      # Warm up
      5.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
          ruby_code,
          0_u32,
          34_u8, # "
          backend
        )
      end

      # Measure throughput
      start_time = Time.monotonic
      iterations = 100

      iterations.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
          ruby_code,
          0_u32,
          34_u8,
          backend
        )
      end

      elapsed = Time.monotonic - start_time
      throughput_mbps = (ruby_code.size * iterations) / elapsed.total_seconds / (1024 * 1024)

      # Throughput should be at least 100 MB/s on modern systems
      throughput_mbps.should be > 100.0
    end

    it "maintains throughput for long strings" do
      long_string = "\"" + ("x" * 10000) + "\""
      ruby_code = long_string.to_slice

      backend = Warp::Backend.current

      # Warm up
      2.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
          ruby_code,
          0_u32,
          34_u8,
          backend
        )
      end

      # Measure throughput
      start_time = Time.monotonic
      iterations = 20

      iterations.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_string_interior(
          ruby_code,
          0_u32,
          34_u8,
          backend
        )
      end

      elapsed = Time.monotonic - start_time
      throughput_mbps = (ruby_code.size * iterations) / elapsed.total_seconds / (1024 * 1024)

      # Throughput should be at least 50 MB/s for longer strings
      throughput_mbps.should be > 50.0
    end
  end

  describe "Regex scanning performance" do
    it "maintains throughput for regex patterns" do
      ruby_regex = "/pattern[0-9]+/i, /test/m, /regex/"
      ruby_code = ruby_regex.to_slice

      backend = Warp::Backend.current

      # Warm up
      5.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_regex_interior(
          ruby_code,
          0_u32,
          backend
        )
      end

      # Measure throughput
      start_time = Time.monotonic
      iterations = 100

      iterations.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_regex_interior(
          ruby_code,
          0_u32,
          backend
        )
      end

      elapsed = Time.monotonic - start_time
      throughput_mbps = (ruby_code.size * iterations) / elapsed.total_seconds / (1024 * 1024)

      # Throughput should be at least 100 MB/s
      throughput_mbps.should be > 100.0
    end
  end

  describe "Heredoc scanning performance" do
    it "maintains throughput for heredoc blocks" do
      ruby_heredoc = %{<<EOF
This is a heredoc
with multiple lines
and content
EOF}.to_slice

      backend = Warp::Backend.current

      # Warm up
      5.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_heredoc_content(
          ruby_heredoc,
          0_u32,
          "EOF",
          backend
        )
      end

      # Measure throughput
      start_time = Time.monotonic
      iterations = 50

      iterations.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_heredoc_content(
          ruby_heredoc,
          0_u32,
          "EOF",
          backend
        )
      end

      elapsed = Time.monotonic - start_time
      throughput_mbps = (ruby_heredoc.size * iterations) / elapsed.total_seconds / (1024 * 1024)

      # Throughput should be at least 50 MB/s
      throughput_mbps.should be > 50.0
    end
  end

  describe "Macro scanning performance (Crystal)" do
    it "maintains throughput for macro blocks" do
      crystal_macro = %{{% if flag?(:debug) %}
        def debug_method
          puts "Debug mode"
        end
      {% end %}}.to_slice

      backend = Warp::Backend.current

      # Warm up
      5.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_macro_interior(
          crystal_macro,
          0_u32,
          backend
        )
      end

      # Measure throughput
      start_time = Time.monotonic
      iterations = 50

      iterations.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_macro_interior(
          crystal_macro,
          0_u32,
          backend
        )
      end

      elapsed = Time.monotonic - start_time
      throughput_mbps = (crystal_macro.size * iterations) / elapsed.total_seconds / (1024 * 1024)

      # Throughput should be at least 50 MB/s
      throughput_mbps.should be > 50.0
    end
  end

  describe "Annotation scanning performance (Crystal)" do
    it "maintains throughput for annotation blocks" do
      crystal_annotation = %{@[JSON::Field(key: "user_id")]
@[Link("curl")]
@[Deprecated("Use new_method")]}.to_slice

      backend = Warp::Backend.current

      # Warm up
      5.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_annotation_interior(
          crystal_annotation,
          0_u32,
          backend
        )
      end

      # Measure throughput
      start_time = Time.monotonic
      iterations = 100

      iterations.times do
        Warp::Lang::Common::StateAwareSimdHelpers.scan_annotation_interior(
          crystal_annotation,
          0_u32,
          backend
        )
      end

      elapsed = Time.monotonic - start_time
      throughput_mbps = (crystal_annotation.size * iterations) / elapsed.total_seconds / (1024 * 1024)

      # Throughput should be at least 75 MB/s for annotations
      throughput_mbps.should be > 75.0
    end
  end
end
