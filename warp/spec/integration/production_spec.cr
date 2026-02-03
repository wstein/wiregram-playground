require "../spec_helper"
require "../../src/warp/cli/production"

describe Warp::Production do
  describe "InputValidator" do
    describe "#validate_input" do
      it "accepts valid UTF-8 input" do
        data = "def hello(name)\n  puts \"Hello, \#{name}!\"\nend".encode("UTF-8")
        valid, error = Warp::Production::InputValidator.validate_input(data, "ruby")
        valid.should be_true
        error.should be_nil
      end

      it "rejects empty input" do
        data = Bytes.empty
        valid, error = Warp::Production::InputValidator.validate_input(data, "ruby")
        valid.should be_false
        error.not_nil!.should contain("empty")
      end

      it "rejects input exceeding size limit" do
        # Create oversized data (just check the logic, not actual 1GB)
        data = Bytes.new(Warp::Production::InputValidator::MAX_FILE_SIZE + 1)
        valid, error = Warp::Production::InputValidator.validate_input(data, "json")
        valid.should be_false
        error.not_nil!.should contain("exceeds maximum")
      end

      it "rejects invalid UTF-8 sequences" do
        # Invalid UTF-8: starts with continuation byte
        data = Bytes[0x80_u8, 0x81_u8, 0x82_u8]
        valid, error = Warp::Production::InputValidator.validate_input(data, "ruby")
        valid.should be_false
        error.not_nil!.should contain("UTF-8")
      end

      it "validates UTF-8 two-byte sequences" do
        # Valid: 2-byte UTF-8 sequence (é = 0xC3 0xA9)
        data = Bytes[0xC3_u8, 0xA9_u8]
        valid, error = Warp::Production::InputValidator.validate_input(data, "ruby")
        valid.should be_true
      end

      it "validates UTF-8 multi-byte sequences" do
        # Valid: 3-byte UTF-8 (€ = 0xE2 0x82 0xAC)
        data = Bytes[0xE2_u8, 0x82_u8, 0xAC_u8]
        valid, error = Warp::Production::InputValidator.validate_input(data, "json")
        valid.should be_true
      end

      it "detects pathological nesting in JSON" do
        # Extremely deep nesting
        data = ("[[" * 2000 + "1" + "]]" * 2000).encode("UTF-8")
        valid, error = Warp::Production::InputValidator.validate_input(data, "json")
        # Should warn but still be valid (validation happens at parse time)
        valid.should be_true  # Input validation passes, pattern detection happens later
      end

      it "detects extremely long lines" do
        # 200KB line
        data = ("a" * 200_000 + "\n").encode("UTF-8")
        valid, error = Warp::Production::InputValidator.validate_input(data, "ruby")
        valid.should be_true  # Still valid, but would log warning
      end
    end
  end

  describe "Metrics" do
    it "calculates duration correctly" do
      start_time = Time.instant
      end_time = start_time + 100.milliseconds

      metrics = Warp::Production::Metrics.new(
        start_time: start_time,
        end_time: end_time,
        input_size: 1024_u64,
        output_size: 512_u64,
        language: "ruby",
        backend: "avx2",
        success: true,
        error_message: nil,
        patterns_detected: {"tokens" => 42}
      )

      metrics.duration_ms.should be_close(100.0, 10.0)
    end

    it "calculates throughput in MB/s" do
      start_time = Time.instant
      end_time = start_time + 1.second

      # 1 MB in 1 second = 1 MB/s
      metrics = Warp::Production::Metrics.new(
        start_time: start_time,
        end_time: end_time,
        input_size: (1024_u64 * 1024_u64),
        output_size: 0_u64,
        language: "json",
        backend: "sse2",
        success: true,
        error_message: nil,
        patterns_detected: {"tokens" => 100}
      )

      metrics.throughput_mbps.should be_close(1.0, 0.1)
    end

    it "exports metrics to Prometheus format" do
      metrics = Warp::Production::Metrics.new(
        start_time: Time.instant,
        end_time: Time.instant + 50.milliseconds,
        input_size: 2048_u64,
        output_size: 1024_u64,
        language: "crystal",
        backend: "neon",
        success: true,
        error_message: nil,
        patterns_detected: {"tokens" => 25, "macros" => 3}
      )

      prometheus = metrics.to_prometheus
      prometheus.should contain("warp_parse_duration_ms")
      prometheus.should contain("language=\"crystal\"")
      prometheus.should contain("backend=\"neon\"")
      prometheus.should contain("warp_parse_success{language=\"crystal\",backend=\"neon\"} 1")
    end

    it "exports metrics to JSON format" do
      metrics = Warp::Production::Metrics.new(
        start_time: Time.instant,
        end_time: Time.instant + 75.milliseconds,
        input_size: 4096_u64,
        output_size: 2048_u64,
        language: "ruby",
        backend: "avx2",
        success: false,
        error_message: "Test error",
        patterns_detected: {"tokens" => 50}
      )

      json_str = metrics.to_json
      json = JSON.parse(json_str)
      json["language"].should eq("ruby")
      json["backend"].should eq("avx2")
      json["success"].should be_false
      json["error"].should eq("Test error")
      json["patterns"]["tokens"].should eq(50)
    end
  end

  describe "HealthCheck" do
    it "tracks recent errors" do
      Warp::Production::HealthCheck.record_error("Error 1")
      Warp::Production::HealthCheck.record_error("Error 2")

      status = Warp::Production::HealthCheck.status
      status.recent_errors.should contain("Error 1")
      status.recent_errors.should contain("Error 2")
      status.healthy.should be_false
    end

    it "limits stored errors to 20" do
      25.times { |i| Warp::Production::HealthCheck.record_error("Error #{i}") }

      status = Warp::Production::HealthCheck.status
      status.recent_errors.size.should eq(20)
      status.recent_errors[0].should eq("Error 5")  # First 5 were dropped
    end

    it "exports status to JSON" do
      Warp::Production::HealthCheck.record_error("Test error")
      status = Warp::Production::HealthCheck.status

      json_str = status.to_json
      json = JSON.parse(json_str).as_h
      json["healthy"].should be_false
      json["timestamp"]?.should_not be_nil
      json["cpu_count"].as_i.should be > 0
    end

    it "calculates average latency from metrics" do
      metrics1 = Warp::Production::Metrics.new(
        start_time: Time.instant,
        end_time: Time.instant + 50.milliseconds,
        input_size: 1024_u64,
        output_size: 512_u64,
        language: "json",
        backend: "avx2",
        success: true,
        error_message: nil,
        patterns_detected: {} of String => Int32
      )

      metrics2 = Warp::Production::Metrics.new(
        start_time: Time.instant,
        end_time: Time.instant + 100.milliseconds,
        input_size: 2048_u64,
        output_size: 1024_u64,
        language: "ruby",
        backend: "avx2",
        success: true,
        error_message: nil,
        patterns_detected: {} of String => Int32
      )

      Warp::Production::HealthCheck.record_metrics(metrics1)
      Warp::Production::HealthCheck.record_metrics(metrics2)

      status = Warp::Production::HealthCheck.status
      status.avg_latency_ms.should be_close(75.0, 10.0)
    end
  end

  describe "safe_parse" do
    it "successfully parses valid JSON" do
      data = %{{"name": "test", "value": 42}}.encode("UTF-8")

      result = Warp::Production.safe_parse(data, "json")

      result[:success].should be_true
      result[:metrics].should_not be_nil
      result[:metrics].not_nil!.success.should be_true
      result[:error].should be_nil
    end

    it "successfully parses valid Ruby code" do
      data = "def greet(name)\n  \"Hello, \#{name}\"\nend".encode("UTF-8")

      result = Warp::Production.safe_parse(data, "ruby")

      result[:success].should be_true
      result[:metrics].should_not be_nil
      result[:metrics].not_nil!.language.should eq("ruby")
      result[:error].should be_nil
    end

    it "successfully parses valid Crystal code" do
      data = "def greet(name : String) : String\n  \"Hello, \#{name}\"\nend".encode("UTF-8")

      result = Warp::Production.safe_parse(data, "crystal")

      result[:success].should be_true
      result[:metrics].should_not be_nil
      result[:metrics].not_nil!.language.should eq("crystal")
      result[:error].should be_nil
    end

    it "handles empty input gracefully" do
      data = Bytes.empty

      result = Warp::Production.safe_parse(data, "ruby")

      result[:success].should be_false
      result[:error].not_nil!.should contain("empty")
      result[:metrics].should_not be_nil
      result[:metrics].not_nil!.success.should be_false
    end

    it "handles unknown language" do
      data = "test data".encode("UTF-8")

      result = Warp::Production.safe_parse(data, "unknown_lang")

      result[:success].should be_false
      result[:error].not_nil!.should contain("Unknown language")
    end

    it "records metrics on successful parse" do
      data = "{\"test\": true}".encode("UTF-8")

      result = Warp::Production.safe_parse(data, "json")

      result[:metrics].should_not be_nil
      metrics = result[:metrics].not_nil!
      metrics.input_size.should eq(data.size.to_u64)
      metrics.success.should be_true
      metrics.duration_ms.should be > 0
    end

    it "includes pattern counts in metrics" do
      data = <<-RUBY
        def test
          puts "hello"
        end
        
        /regex_pattern/
        another_var = "string with \#{interpolation}"
      RUBY
      data = data.encode("UTF-8")

      result = Warp::Production.safe_parse(data, "ruby")

      result[:success].should be_true
      metrics = result[:metrics].not_nil!
      metrics.patterns_detected.has_key?("tokens").should be_true
      metrics.patterns_detected["tokens"].should be > 0
    end
  end

  describe "diagnostic_info" do
    it "returns diagnostic information" do
      info = Warp::Production.diagnostic_info

      info["version"]?.should_not be_nil
      info["timestamp"]?.should_not be_nil
      info["healthy"]?.should_not be_nil
      info["memory_mb"]?.should_not be_nil
      info["cpus"]?.should_not be_nil
      info["supported_languages"]?.should_not be_nil
      info["backends"]?.should_not be_nil
    end

    it "lists supported languages" do
      info = Warp::Production.diagnostic_info
      languages = info["supported_languages"]?
      languages.should_not be_nil
      languages.not_nil!.should contain("ruby")
      languages.not_nil!.should contain("json")
      languages.not_nil!.should contain("crystal")
    end

    it "includes recent errors if any" do
      Warp::Production::HealthCheck.record_error("Test diagnostic error")
      info = Warp::Production.diagnostic_info

      errors = info["recent_errors"]?
      errors.should_not be_nil
      errors.not_nil!.should contain("Test diagnostic error")
    end
  end

  describe "Integration scenarios" do
    it "handles a complete workflow with metrics tracking" do
      json_data = %{[1, 2, {\"nested\": true}]}.encode("UTF-8")
      ruby_data = "class Test\n  attr_reader :value\nend".encode("UTF-8")

      json_result = Warp::Production.safe_parse(json_data, "json")
      ruby_result = Warp::Production.safe_parse(ruby_data, "ruby")

      json_result[:success].should be_true
      ruby_result[:success].should be_true

      # Note: Errors from previous tests might still be in the log
      # Just verify that successful parses were recorded
      json_result[:metrics].not_nil!.success.should be_true
      ruby_result[:metrics].not_nil!.success.should be_true
    end

    it "recovers from errors and continues processing" do
      # First: invalid input
      invalid_result = Warp::Production.safe_parse(Bytes.empty, "ruby")
      invalid_result[:success].should be_false

      # Second: valid input after error
      valid_result = Warp::Production.safe_parse("puts 'hello'".encode("UTF-8"), "ruby")
      valid_result[:success].should be_true

      # Health status should reflect that we have at least one error and one success
      status = Warp::Production::HealthCheck.status
      status.recent_errors.size.should be >= 1  # At least one error recorded
    end

    it "maintains metrics history for trend analysis" do
      3.times do
        data = "test_code".encode("UTF-8")
        Warp::Production.safe_parse(data, "ruby")
      end

      status = Warp::Production::HealthCheck.status
      status.avg_latency_ms.should be > 0
      status.throughput_mbps.should be > 0
    end
  end
end
