require "../spec_helper"

describe "ARM/Pi JSON Parsing Integration" do
  describe "ARMv6 Backend parsing" do
    it "parses simple JSON objects with ARMv6 backend" do
      {% if flag?(:arm) %}
        backend = Warp::Backend::ARMv6Backend.new
        Warp::Backend.reset(backend)

        json = %({"name": "test", "value": 42})
        bytes = json.to_slice
        result = Warp::Lexer.index(bytes)
        result.error.should eq(Warp::ErrorCode::Success)
        Warp::Backend.reset
      {% end %}
    end

    it "parses arrays with ARMv6 backend" do
      {% if flag?(:arm) %}
        backend = Warp::Backend::ARMv6Backend.new
        Warp::Backend.reset(backend)

        json = %([1, 2, 3, "four", true, false, null])
        bytes = json.to_slice
        result = Warp::Lexer.index(bytes)
        result.error.should eq(Warp::ErrorCode::Success)
        Warp::Backend.reset
      {% end %}
    end

    it "parses nested structures with ARMv6 backend" do
      {% if flag?(:arm) %}
        backend = Warp::Backend::ARMv6Backend.new
        Warp::Backend.reset(backend)

        json = %({
          "users": [
            {"name": "Alice", "age": 30},
            {"name": "Bob", "age": 25}
          ]
        })
        bytes = json.to_slice
        result = Warp::Lexer.index(bytes)
        result.error.should eq(Warp::ErrorCode::Success)
        Warp::Backend.reset
      {% end %}
    end

    it "handles escaped strings with ARMv6 backend" do
      {% if flag?(:arm) %}
        backend = Warp::Backend::ARMv6Backend.new
        Warp::Backend.reset(backend)

        json = %({
          "text": "Hello\nWorld",
          "path": "C:\\\\Users\\\\test",
          "quote": "She said \\"Hello\\""
        })
        bytes = json.to_slice
        result = Warp::Lexer.index(bytes)
        result.error.should eq(Warp::ErrorCode::Success)
        Warp::Backend.reset
      {% end %}
    end

    it "handles numbers with ARMv6 backend" do
      {% if flag?(:arm) %}
        backend = Warp::Backend::ARMv6Backend.new
        Warp::Backend.reset(backend)

        json = %({
          "int": 42,
          "negative": -123,
          "float": 3.14,
          "scientific": 1.23e-4,
          "zero": 0
        })
        bytes = json.to_slice
        result = Warp::Lexer.index(bytes)
        result.error.should eq(Warp::ErrorCode::Success)
        Warp::Backend.reset
      {% end %}
    end

    it "handles whitespace variations with ARMv6 backend" do
      {% if flag?(:arm) %}
        backend = Warp::Backend::ARMv6Backend.new
        Warp::Backend.reset(backend)

        json = %({
          "spaced" : "values"  ,
          "tabs"	:	"too"
        })
        bytes = json.to_slice
        result = Warp::Lexer.index(bytes)
        result.error.should eq(Warp::ErrorCode::Success)
        Warp::Backend.reset
      {% end %}
    end
  end

  describe "NEON Backend parsing (ARMv7/v8)" do
    it "parses complex JSON with NEON backend" do
      {% if flag?(:aarch64) || flag?(:arm) %}
        arm_version = Warp::Parallel::CPUDetector.detect_arm_version

        case arm_version
        when Warp::Parallel::ARMVersion::ARMv7, Warp::Parallel::ARMVersion::ARMv8
          backend = Warp::Backend::NeonBackend.new
          Warp::Backend.reset(backend)

          json = %({"test": [1, 2, {"nested": true}]})
          bytes = json.to_slice
          result = Warp::Lexer.index(bytes)
          result.error.should eq(Warp::ErrorCode::Success)
          Warp::Backend.reset
        end
      {% end %}
    end
  end

  describe "CPU detector and backend selection integration" do
    it "selects appropriate backend based on ARM version" do
      {% if flag?(:arm) %}
        arm_version = Warp::Parallel::CPUDetector.detect_arm_version
        backend = Warp::Backend::Selector.select

        case arm_version
        when Warp::Parallel::ARMVersion::ARMv6
          backend.name.should eq("armv6")
        when Warp::Parallel::ARMVersion::ARMv7, Warp::Parallel::ARMVersion::ARMv8
          backend.name.should eq("neon")
        end
      {% end %}
    end

    it "maintains consistent SIMD capability detection" do
      {% if flag?(:arm) %}
        simd1 = Warp::Parallel::CPUDetector.detect_simd
        simd2 = Warp::Parallel::CPUDetector.detect_simd
        simd1.should eq(simd2)
      {% end %}
    end

    it "provides accurate CPU summary for ARM systems" do
      {% if flag?(:arm) %}
        summary = Warp::Parallel::CPUDetector.summary
        summary.should contain("cores")
        summary.should contain("ARM:")
        summary.should contain("SIMD:")
      {% end %}
    end
  end

  describe "Performance characteristics by Pi model" do
    it "reports memory bandwidth limit for Pi systems" do
      pi_model = Warp::Parallel::CPUDetector.detect_pi_model
      bandwidth_limited = Warp::Parallel::CPUDetector.memory_bandwidth_limited?

      case pi_model
      when Warp::Parallel::RaspberryPiModel::Pi1,
           Warp::Parallel::RaspberryPiModel::PiZero,
           Warp::Parallel::RaspberryPiModel::Pi2,
           Warp::Parallel::RaspberryPiModel::Pi3,
           Warp::Parallel::RaspberryPiModel::Pi3B,
           Warp::Parallel::RaspberryPiModel::Pi4,
           Warp::Parallel::RaspberryPiModel::Pi5
        bandwidth_limited.should be_true
      end
    end
  end

  describe "Backend fallback chain" do
    it "has valid fallback for all backends" do
      {% if flag?(:arm) %}
        # ARMv6 should fall back to scalar
        previous = ENV["WARP_BACKEND"]?
        begin
          ENV["WARP_BACKEND"] = "invalid_backend"
          backend = Warp::Backend::Selector.select
          backend.should_not be_nil
        ensure
          ENV.delete("WARP_BACKEND") if !previous
          ENV["WARP_BACKEND"] = previous if previous
        end
      {% end %}
    end
  end

  describe "Large JSON parsing" do
    it "parses larger JSON documents with ARMv6" do
      {% if flag?(:arm) %}
        backend = Warp::Backend::ARMv6Backend.new
        Warp::Backend.reset(backend)

        # Build a larger JSON document
        json = %({"items": [)
        100.times do |i|
          json += %({" + "id": #{i}, "value": #{i * 2})
          json += "," if i < 99
        end
        json += %(]})

        bytes = json.to_slice
        result = Warp::Lexer.index(bytes)
        result.error.should eq(Warp::ErrorCode::Success)
        Warp::Backend.reset
      {% end %}
    end
  end

  describe "Special character handling" do
    it "handles unicode escape sequences" do
      {% if flag?(:arm) %}
        backend = Warp::Backend::ARMv6Backend.new
        Warp::Backend.reset(backend)

        json = %({
          "emoji": "\\u1F600",
          "chinese": "\\u4E2D\\u6587"
        })
        bytes = json.to_slice
        result = Warp::Lexer.index(bytes)
        result.error.should eq(Warp::ErrorCode::Success)
        Warp::Backend.reset
      {% end %}
    end

    it "handles all escape sequences" do
      {% if flag?(:arm) %}
        backend = Warp::Backend::ARMv6Backend.new
        Warp::Backend.reset(backend)

        json = %({
          "backslash": "\\\\",
          "quote": "\\"",
          "slash": "\\/",
          "backspace": "\\b",
          "formfeed": "\\f",
          "newline": "\\n",
          "carriage": "\\r",
          "tab": "\\t"
        })
        bytes = json.to_slice
        result = Warp::Lexer.index(bytes)
        result.error.should eq(Warp::ErrorCode::Success)
        Warp::Backend.reset
      {% end %}
    end
  end

  describe "Environment variable override behavior" do
    it "respects WARP_BACKEND environment variable" do
      {% if flag?(:arm) %}
        previous = ENV["WARP_BACKEND"]?
        ENV["WARP_BACKEND"] = "scalar"
        backend = Warp::Backend::Selector.select
        backend.name.should eq("scalar")

        if previous
          ENV["WARP_BACKEND"] = previous
        else
          ENV.delete("WARP_BACKEND")
        end
      {% end %}
    end
  end

  describe "Concurrent parsing with multiple backends" do
    it "handles sequential backend switching" do
      {% if flag?(:arm) %}
        json = %({"test": "value"})

        # Parse with ARMv6
        backend1 = Warp::Backend::ARMv6Backend.new
        Warp::Backend.reset(backend1)
        bytes = json.to_slice
        result1 = Warp::Lexer.index(bytes)
        result1.error.should eq(Warp::ErrorCode::Success)

        # Parse with Scalar
        backend2 = Warp::Backend::ScalarBackend.new
        Warp::Backend.reset(backend2)
        result2 = Warp::Lexer.index(bytes)
        result2.error.should eq(Warp::ErrorCode::Success)

        # Results should be consistent
        result1.error.should eq(result2.error)
        Warp::Backend.reset
      {% end %}
    end
  end
end
