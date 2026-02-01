require "../spec_helper"

describe Warp::Parallel::CPUDetector do
  describe "ARM version detection" do
    it "detects ARMv8 architecture" do
      # ARMv8 should always be detected on aarch64
      {% if flag?(:aarch64) %}
        arm_version = Warp::Parallel::CPUDetector.detect_arm_version
        arm_version.should eq(Warp::Parallel::ARMVersion::ARMv8)
      {% end %}
    end

    it "caches ARM version detection" do
      {% if flag?(:aarch64) || flag?(:arm) %}
        version1 = Warp::Parallel::CPUDetector.detect_arm_version
        version2 = Warp::Parallel::CPUDetector.detect_arm_version
        # Should return same instance due to caching
        version1.should eq(version2)
      {% end %}
    end
  end

  describe "Raspberry Pi model detection" do
    it "detects Pi model" do
      pi_model = Warp::Parallel::CPUDetector.detect_pi_model
      # Should return some model (possibly Unknown on non-Pi systems)
      pi_model.should be_a(Warp::Parallel::RaspberryPiModel)
    end

    it "caches Pi model detection" do
      model1 = Warp::Parallel::CPUDetector.detect_pi_model
      model2 = Warp::Parallel::CPUDetector.detect_pi_model
      # Should return same instance due to caching
      model1.should eq(model2)
    end

    it "provides is_raspberry_pi? convenience method" do
      is_pi = Warp::Parallel::CPUDetector.is_raspberry_pi?
      is_pi.should be_a(Bool)
    end
  end

  describe "memory bandwidth detection" do
    it "reports memory bandwidth limits" do
      bandwidth_limited = Warp::Parallel::CPUDetector.memory_bandwidth_limited?
      bandwidth_limited.should be_a(Bool)
    end

    it "reports Pi systems as bandwidth limited" do
      pi_model = Warp::Parallel::CPUDetector.detect_pi_model
      if pi_model != Warp::Parallel::RaspberryPiModel::Unknown
        bandwidth_limited = Warp::Parallel::CPUDetector.memory_bandwidth_limited?
        bandwidth_limited.should be_true
      end
    end

    it "caches memory bandwidth detection" do
      bw1 = Warp::Parallel::CPUDetector.memory_bandwidth_limited?
      bw2 = Warp::Parallel::CPUDetector.memory_bandwidth_limited?
      bw1.should eq(bw2)
    end
  end

  describe "SIMD capability detection" do
    it "detects SIMD capability" do
      simd = Warp::Parallel::CPUDetector.detect_simd
      simd.should be_a(Warp::Parallel::SIMDCapability)
    end

    it "returns None for ARMv6" do
      {% if flag?(:aarch64) || flag?(:arm) %}
        arm_version = Warp::Parallel::CPUDetector.detect_arm_version
        simd = Warp::Parallel::CPUDetector.detect_simd

        if arm_version == Warp::Parallel::ARMVersion::ARMv6
          simd.should eq(Warp::Parallel::SIMDCapability::None)
        end
      {% end %}
    end

    it "returns NEON for ARMv7/v8" do
      {% if flag?(:aarch64) || flag?(:arm) %}
        arm_version = Warp::Parallel::CPUDetector.detect_arm_version
        simd = Warp::Parallel::CPUDetector.detect_simd

        case arm_version
        when Warp::Parallel::ARMVersion::ARMv7, Warp::Parallel::ARMVersion::ARMv8
          simd.should eq(Warp::Parallel::SIMDCapability::NEON)
        end
      {% end %}
    end

    it "caches SIMD capability detection" do
      simd1 = Warp::Parallel::CPUDetector.detect_simd
      simd2 = Warp::Parallel::CPUDetector.detect_simd
      simd1.should eq(simd2)
    end
  end

  describe "CPU model detection" do
    it "detects CPU model name" do
      model = Warp::Parallel::CPUDetector.cpu_model
      model.should be_a(String)
      model.size.should be >= 0
    end

    it "caches CPU model detection" do
      model1 = Warp::Parallel::CPUDetector.cpu_model
      model2 = Warp::Parallel::CPUDetector.cpu_model
      model1.should eq(model2)
    end
  end

  describe "CPU vendor detection" do
    it "detects CPU vendor" do
      {% if flag?(:x86_64) %}
        vendor = Warp::Parallel::CPUDetector.detect_vendor
        vendor.should be_a(Warp::Parallel::CPUVendor)
      {% elsif flag?(:aarch64) || flag?(:arm) %}
        vendor = Warp::Parallel::CPUDetector.detect_vendor
        vendor.should eq(Warp::Parallel::CPUVendor::ARM)
      {% end %}
    end

    it "caches vendor detection" do
      vendor1 = Warp::Parallel::CPUDetector.detect_vendor
      vendor2 = Warp::Parallel::CPUDetector.detect_vendor
      vendor1.should eq(vendor2)
    end
  end

  describe "microarchitecture detection" do
    it "detects microarchitecture" do
      microarch = Warp::Parallel::CPUDetector.detect_microarchitecture
      microarch.should be_a(Warp::Parallel::Microarchitecture)
    end

    it "caches microarchitecture detection" do
      microarch1 = Warp::Parallel::CPUDetector.detect_microarchitecture
      microarch2 = Warp::Parallel::CPUDetector.detect_microarchitecture
      microarch1.should eq(microarch2)
    end
  end

  describe "performance core detection" do
    it "detects if CPU has performance cores" do
      is_perf = Warp::Parallel::CPUDetector.is_performance_core?
      is_perf.should be_a(Bool)
    end

    it "caches performance core detection" do
      perf1 = Warp::Parallel::CPUDetector.is_performance_core?
      perf2 = Warp::Parallel::CPUDetector.is_performance_core?
      perf1.should eq(perf2)
    end
  end

  describe "CPU count" do
    it "reports CPU count" do
      count = Warp::Parallel::CPUDetector.cpu_count
      count.should be > 0
    end
  end

  describe "summary generation" do
    it "generates summary string" do
      summary = Warp::Parallel::CPUDetector.summary
      summary.should be_a(String)
      summary.size.should be > 0
    end

    it "includes CPU core count in summary" do
      summary = Warp::Parallel::CPUDetector.summary
      summary.should contain("cores")
    end

    it "includes ARM info for ARM systems" do
      {% if flag?(:aarch64) || flag?(:arm) %}
        summary = Warp::Parallel::CPUDetector.summary
        summary.should contain("ARM:")
      {% end %}
    end

    it "includes x86 vendor info for x86 systems" do
      {% if flag?(:x86_64) %}
        summary = Warp::Parallel::CPUDetector.summary
        summary.should contain("Vendor:")
      {% end %}
    end

    it "includes SIMD capability in summary" do
      summary = Warp::Parallel::CPUDetector.summary
      summary.should contain("SIMD:")
    end
  end

  describe "ARM version enum conversion" do
    it "converts ARMv6 to string" do
      Warp::Parallel::ARMVersion::ARMv6.to_s.should eq("ARMv6")
    end

    it "converts ARMv7 to string" do
      Warp::Parallel::ARMVersion::ARMv7.to_s.should eq("ARMv7")
    end

    it "converts ARMv8 to string" do
      Warp::Parallel::ARMVersion::ARMv8.to_s.should eq("ARMv8")
    end

    it "converts Unknown to string" do
      Warp::Parallel::ARMVersion::Unknown.to_s.should eq("Unknown")
    end
  end

  describe "Raspberry Pi model enum conversion" do
    it "converts Pi models to strings" do
      Warp::Parallel::RaspberryPiModel::Pi1.to_s.should eq("Pi1")
      Warp::Parallel::RaspberryPiModel::PiZero.to_s.should eq("PiZero")
      Warp::Parallel::RaspberryPiModel::Pi2.to_s.should eq("Pi2")
      Warp::Parallel::RaspberryPiModel::Pi3.to_s.should eq("Pi3")
      Warp::Parallel::RaspberryPiModel::Pi4.to_s.should eq("Pi4")
      Warp::Parallel::RaspberryPiModel::Pi5.to_s.should eq("Pi5")
    end
  end

  describe "CPU vendor enum conversion" do
    it "converts vendors to strings" do
      Warp::Parallel::CPUVendor::Intel.to_s.should eq("Intel")
      Warp::Parallel::CPUVendor::AMD.to_s.should eq("AMD")
      Warp::Parallel::CPUVendor::ARM.to_s.should eq("ARM")
      Warp::Parallel::CPUVendor::Unknown.to_s.should eq("Unknown")
    end
  end

  describe "SIMD capability enum conversion" do
    it "converts SIMD capabilities to strings" do
      Warp::Parallel::SIMDCapability::None.to_s.should eq("None")
      Warp::Parallel::SIMDCapability::SSE2.to_s.should eq("SSE2")
      Warp::Parallel::SIMDCapability::AVX2.to_s.should eq("AVX2")
      Warp::Parallel::SIMDCapability::AVX512.to_s.should eq("AVX512")
      Warp::Parallel::SIMDCapability::NEON.to_s.should eq("NEON")
    end
  end

  describe "microarchitecture enum properties" do
    it "identifies double-pumped AVX-512 microarchitectures" do
      Warp::Parallel::Microarchitecture::Zen.has_double_pumped_avx512?.should be_false
      Warp::Parallel::Microarchitecture::Zen2.has_double_pumped_avx512?.should be_true
      Warp::Parallel::Microarchitecture::Zen3.has_double_pumped_avx512?.should be_true
      Warp::Parallel::Microarchitecture::Zen4.has_double_pumped_avx512?.should be_true
      Warp::Parallel::Microarchitecture::Zen5.has_double_pumped_avx512?.should be_false
      Warp::Parallel::Microarchitecture::IceLake.has_double_pumped_avx512?.should be_false
    end

    it "identifies full 512-bit AVX-512 microarchitectures" do
      Warp::Parallel::Microarchitecture::Zen5.has_full_avx512?.should be_true
      Warp::Parallel::Microarchitecture::IceLake.has_full_avx512?.should be_true
      Warp::Parallel::Microarchitecture::Zen4.has_full_avx512?.should be_false
      Warp::Parallel::Microarchitecture::Zen3.has_full_avx512?.should be_false
    end
  end
end
