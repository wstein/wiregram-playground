require "../spec_helper"

describe Warp::Backend::Selector do
  it "selects scalar backend when override is set" do
    previous = ENV["WARP_BACKEND"]?
    begin
      ENV["WARP_BACKEND"] = "ScAlAr"
      backend = Warp::Backend::Selector.select
      backend.should be_a(Warp::Backend::ScalarBackend)
    ensure
      if previous
        ENV["WARP_BACKEND"] = previous
      else
        ENV.delete("WARP_BACKEND")
      end
    end
  end

  it "resolves backend by name via the public API" do
    backend = Warp::Backend.select_by_name("scalar")
    backend.should be_a(Warp::Backend::ScalarBackend)
  end

  it "falls back to the default backend for unknown overrides" do
    previous = ENV["WARP_BACKEND"]?
    begin
      ENV["WARP_BACKEND"] = "unknown"
      backend = Warp::Backend::Selector.select
      backend.should_not be_nil
      backend.should_not be_a(Warp::Backend::ScalarBackend)
    ensure
      if previous
        ENV["WARP_BACKEND"] = previous
      else
        ENV.delete("WARP_BACKEND")
      end
    end
  end

  {% if flag?(:aarch64) %}
    it "selects neon backend when explicitly requested" do
      previous = ENV["WARP_BACKEND"]?
      begin
        ENV["WARP_BACKEND"] = "neon"
        backend = Warp::Backend::Selector.select
        backend.should be_a(Warp::Backend::NeonBackend)
      ensure
        if previous
          ENV["WARP_BACKEND"] = previous
        else
          ENV.delete("WARP_BACKEND")
        end
      end
    end
  {% end %}

  describe "ARM backend selection" do
    it "detects ARM architecture automatically" do
      {% if flag?(:aarch64) || flag?(:arm) %}
        backend = Warp::Backend::Selector.select
        # Should auto-select appropriate ARM backend
        backend.should_not be_nil
      {% end %}
    end

    it "routes ARMv6 to ARMv6Backend" do
      {% if flag?(:arm) %}
        arm_version = Warp::Parallel::CPUDetector.detect_arm_version
        if arm_version == Warp::Parallel::ARMVersion::ARMv6
          backend = Warp::Backend::Selector.select
          backend.should be_a(Warp::Backend::ARMv6Backend)
        end
      {% end %}
    end

    it "routes ARMv7 to NEON backend" do
      {% if flag?(:arm) %}
        arm_version = Warp::Parallel::CPUDetector.detect_arm_version
        if arm_version == Warp::Parallel::ARMVersion::ARMv7
          backend = Warp::Backend::Selector.select
          backend.should be_a(Warp::Backend::NeonBackend)
        end
      {% end %}
    end

    it "routes ARMv8 to NEON backend" do
      {% if flag?(:aarch64) %}
        arm_version = Warp::Parallel::CPUDetector.detect_arm_version
        arm_version.should eq(Warp::Parallel::ARMVersion::ARMv8)

        backend = Warp::Backend::Selector.select
        backend.should be_a(Warp::Backend::NeonBackend)
      {% end %}
    end

    it "allows explicit armv6 backend override" do
      {% if flag?(:arm) %}
        previous = ENV["WARP_BACKEND"]?
        begin
          ENV["WARP_BACKEND"] = "armv6"
          backend = Warp::Backend::Selector.select
          backend.should be_a(Warp::Backend::ARMv6Backend)
        ensure
          if previous
            ENV["WARP_BACKEND"] = previous
          else
            ENV.delete("WARP_BACKEND")
          end
        end
      {% end %}
    end
  end

  describe "Raspberry Pi detection integration" do
    it "detects Pi model correctly" do
      pi_model = Warp::Parallel::CPUDetector.detect_pi_model
      pi_model.should be_a(Warp::Parallel::RaspberryPiModel)
    end

    it "reports memory bandwidth for detected Pi" do
      pi_model = Warp::Parallel::CPUDetector.detect_pi_model
      bandwidth_limited = Warp::Parallel::CPUDetector.memory_bandwidth_limited?

      if pi_model != Warp::Parallel::RaspberryPiModel::Unknown
        bandwidth_limited.should be_true
      end
    end

    it "includes Pi info in CPU summary" do
      summary = Warp::Parallel::CPUDetector.summary
      pi_model = Warp::Parallel::CPUDetector.detect_pi_model

      if pi_model != Warp::Parallel::RaspberryPiModel::Unknown
        summary.should contain("Pi:")
      end
    end
  end

  {% if flag?(:x86_64) %}
    describe "x86 AVX selection (table-driven)" do
      cases = [
        {vendor: Warp::Parallel::CPUVendor::AMD, micro: Warp::Parallel::Microarchitecture::Zen4, avx512: true, avx2: true, expected: Warp::Backend::Avx2Backend},
        {vendor: Warp::Parallel::CPUVendor::AMD, micro: Warp::Parallel::Microarchitecture::Zen5, avx512: true, avx2: true, expected: Warp::Backend::Avx512Backend},
        {vendor: Warp::Parallel::CPUVendor::Intel, micro: Warp::Parallel::Microarchitecture::IceLake, avx512: true, avx2: true, expected: Warp::Backend::Avx512Backend},
        {vendor: Warp::Parallel::CPUVendor::Unknown, micro: Warp::Parallel::Microarchitecture::Unknown, avx512: true, avx2: true, expected: Warp::Backend::Avx512Backend},
      ]

      cases.each do |c|
        it "selects the expected backend for vendor=#{c[:vendor].to_s} micro=#{c[:micro].to_s}" do
          with_stubbed_cpu(c[:vendor], c[:micro], c[:avx512], c[:avx2]) do
            backend = Warp::Backend::Selector.select
            backend.should be_a(c[:expected])
          end
        end
      end
    end
  {% end %}
end
