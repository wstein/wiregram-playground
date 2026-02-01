module Warp::Parallel
  # CPU vendor classification
  enum CPUVendor
    Unknown # Unknown or no vendor detected
    Intel   # Intel processors
    AMD     # AMD processors (Zen family)
    ARM     # ARM processors

    def to_s(io : IO)
      io << case self
      when Intel   then "intel"
      when AMD     then "amd"
      when ARM     then "arm"
      when Unknown then "unknown"
      else              "unknown"
      end
    end
  end

  # Microarchitecture detection for vendor-specific optimization
  enum Microarchitecture
    Unknown # Unknown architecture
    # Intel architectures
    Haswell    # Intel 4th gen (2013)
    Broadwell  # Intel 5th gen (2014)
    Skylake    # Intel 6th gen (2015)
    KabyLake   # Intel 7th gen (2016)
    CoffeeLake # Intel 8th/9th gen (2017-2019)
    IceLake    # Intel 10th gen (2019) - Full AVX-512
    TigerLake  # Intel 11th gen (2020)
    RocketLake # Intel 11th gen refresh (2021)
    AlderLake  # Intel 12th gen (2021) - P+E cores
    RaptorLake # Intel 13th gen (2022)
    # AMD architectures
    Zen  # AMD Zen (2017)
    Zen2 # AMD Zen 2 (2019) - Double-pumped AVX-512
    Zen3 # AMD Zen 3 (2020) - Double-pumped AVX-512
    Zen4 # AMD Zen 4 (2022) - Some double-pumped AVX-512
    Zen5 # AMD Zen 5 (2024+) - True AVX-512

    def to_s(io : IO)
      io << case self
      when Haswell    then "haswell"
      when Broadwell  then "broadwell"
      when Skylake    then "skylake"
      when KabyLake   then "kaby-lake"
      when CoffeeLake then "coffee-lake"
      when IceLake    then "ice-lake"
      when TigerLake  then "tiger-lake"
      when RocketLake then "rocket-lake"
      when AlderLake  then "alder-lake"
      when RaptorLake then "raptor-lake"
      when Zen        then "zen"
      when Zen2       then "zen2"
      when Zen3       then "zen3"
      when Zen4       then "zen4"
      when Zen5       then "zen5"
      when Unknown    then "unknown"
      else                 "unknown"
      end
    end

    # Check if this architecture has double-pumped AVX-512 (AMD Zen 2/3)
    def has_double_pumped_avx512? : Bool
      case self
      when Zen2, Zen3
        true
      else
        false
      end
    end
  end

  # SIMD capability detection and classification
  enum SIMDCapability
    None   # No SIMD support
    SSE2   # x86 SSE2
    AVX2   # x86 AVX2
    AVX512 # x86 AVX-512
    NEON   # ARM NEON

    def to_s(io : IO)
      io << case self
      when None   then "none"
      when SSE2   then "sse2"
      when AVX2   then "avx2"
      when AVX512 then "avx-512"
      when NEON   then "neon"
      else             "unknown"
      end
    end
  end

  # Detect available SIMD capabilities on the current CPU
  module CPUDetector
    extend self

    @@capability : SIMDCapability?
    @@is_performance_core : Bool?
    @@cpu_model : String?
    @@cpu_vendor : CPUVendor?
    @@microarch : Microarchitecture?

    def detect_simd : SIMDCapability
      return @@capability.not_nil! if @@capability

      {% if flag?(:aarch64) || flag?(:arm) %}
        # ARM architecture - assume NEON support
        @@capability = SIMDCapability::NEON
      {% elsif flag?(:x86_64) || flag?(:i686) %}
        # x86/x64 architecture - detect via runtime inspection
        @@capability = detect_x86_simd
      {% else %}
        @@capability = SIMDCapability::None
      {% end %}

      @@capability.not_nil!
    end

    # Detect CPU vendor (Intel, AMD, ARM)
    def detect_vendor : CPUVendor
      return @@cpu_vendor.not_nil! if @@cpu_vendor

      {% if flag?(:aarch64) || flag?(:arm) %}
        @@cpu_vendor = CPUVendor::ARM
      {% elsif flag?(:x86_64) %}
        @@cpu_vendor = detect_x86_vendor
      {% else %}
        @@cpu_vendor = CPUVendor::Unknown
      {% end %}

      @@cpu_vendor.not_nil!
    end

    # Detect CPU microarchitecture
    def detect_microarchitecture : Microarchitecture
      return @@microarch.not_nil! if @@microarch

      {% if flag?(:x86_64) %}
        @@microarch = detect_x86_microarchitecture
      {% else %}
        @@microarch = Microarchitecture::Unknown
      {% end %}

      @@microarch.not_nil!
    end

    # Detect performance cores (Intel P-cores vs E-cores)
    # This is a heuristic - true P-core detection requires OS APIs
    def is_performance_core? : Bool
      return @@is_performance_core.not_nil! if @@is_performance_core

      {% if flag?(:x86_64) %}
        # On Intel 12th gen+, P-cores typically have AVX2+
        # E-cores may have limited SIMD support
        capability = detect_simd
        @@is_performance_core = (capability == SIMDCapability::AVX2 || capability == SIMDCapability::AVX512)
      {% else %}
        # On ARM, assume all cores have NEON
        @@is_performance_core = true
      {% end %}

      @@is_performance_core.not_nil!
    end

    # Get CPU model information
    def cpu_model : String
      return @@cpu_model.not_nil! if @@cpu_model

      @@cpu_model = detect_cpu_model
      @@cpu_model.not_nil!
    end

    private def detect_cpu_model : String
      {% if flag?(:linux) %}
        if File.exists?("/proc/cpuinfo")
          File.each_line("/proc/cpuinfo") do |line|
            if line.starts_with?("model name")
              return line.split(":", 2)[1].strip rescue "Unknown"
            end
          end
        end
      {% elsif flag?(:darwin) %}
        output = `sysctl -n machdep.cpu.brand_string 2>/dev/null`.strip rescue ""
        return output unless output.empty?
      {% end %}

      "Unknown"
    end

    private def detect_x86_vendor : CPUVendor
      {% if flag?(:linux) %}
        if File.exists?("/proc/cpuinfo")
          File.each_line("/proc/cpuinfo") do |line|
            if line.starts_with?("vendor_id")
              vendor = line.split(":", 2)[1].strip.downcase rescue ""
              return CPUVendor::Intel if vendor.includes?("intel") || vendor.includes?("genuineintel")
              return CPUVendor::AMD if vendor.includes?("amd") || vendor.includes?("authenticamd")
            end
          end
        end
      {% elsif flag?(:darwin) %}
        begin
          vendor = `sysctl -n machdep.cpu.vendor 2>/dev/null`.strip.downcase rescue ""
          return CPUVendor::Intel if vendor.includes?("intel") || vendor.includes?("genuine")
          return CPUVendor::AMD if vendor.includes?("amd")
        rescue
        end
      {% end %}

      CPUVendor::Unknown
    end

    private def detect_x86_microarchitecture : Microarchitecture
      vendor = detect_vendor
      cpu_model_name = cpu_model.downcase

      case vendor
      when CPUVendor::Intel
        # Detect Intel microarchitecture from model name
        if cpu_model_name.includes?("haswell")
          Microarchitecture::Haswell
        elsif cpu_model_name.includes?("broadwell")
          Microarchitecture::Broadwell
        elsif cpu_model_name.includes?("skylake")
          Microarchitecture::Skylake
        elsif cpu_model_name.includes?("kaby lake") || cpu_model_name.includes?("kabylake")
          Microarchitecture::KabyLake
        elsif cpu_model_name.includes?("coffee lake") || cpu_model_name.includes?("coffelake")
          Microarchitecture::CoffeeLake
        elsif cpu_model_name.includes?("ice lake") || cpu_model_name.includes?("icelake")
          Microarchitecture::IceLake
        elsif cpu_model_name.includes?("tiger lake") || cpu_model_name.includes?("tigerlake")
          Microarchitecture::TigerLake
        elsif cpu_model_name.includes?("rocket lake") || cpu_model_name.includes?("rocketlake")
          Microarchitecture::RocketLake
        elsif cpu_model_name.includes?("alder lake") || cpu_model_name.includes?("alderlake")
          Microarchitecture::AlderLake
        elsif cpu_model_name.includes?("raptor lake") || cpu_model_name.includes?("raptolake")
          Microarchitecture::RaptorLake
        else
          Microarchitecture::Unknown
        end
      when CPUVendor::AMD
        # Detect AMD microarchitecture from model name
        if cpu_model_name.includes?("zen") && !cpu_model_name.includes?("zen 2") && !cpu_model_name.includes?("zen2") &&
           !cpu_model_name.includes?("zen 3") && !cpu_model_name.includes?("zen3") &&
           !cpu_model_name.includes?("zen 4") && !cpu_model_name.includes?("zen4")
          Microarchitecture::Zen
        elsif cpu_model_name.includes?("zen 2") || cpu_model_name.includes?("zen2")
          Microarchitecture::Zen2
        elsif cpu_model_name.includes?("zen 3") || cpu_model_name.includes?("zen3")
          Microarchitecture::Zen3
        elsif cpu_model_name.includes?("zen 4") || cpu_model_name.includes?("zen4")
          Microarchitecture::Zen4
        elsif cpu_model_name.includes?("zen 5") || cpu_model_name.includes?("zen5")
          Microarchitecture::Zen5
        else
          Microarchitecture::Unknown
        end
      else
        Microarchitecture::Unknown
      end
    end

    private def detect_x86_simd : SIMDCapability
      # Strategy: Check for highest capability first, fall back to lower
      # Special handling for AMD: avoid double-pumped AVX-512
      {% if flag?(:linux) %}
        if File.exists?("/proc/cpuinfo")
          cpuinfo = File.read("/proc/cpuinfo").downcase

          # Check for AVX-512, but handle AMD double-pumping
          if cpuinfo.includes?("avx512")
            # Detect if this is AMD with double-pumped AVX-512
            vendor = detect_vendor
            microarch = detect_microarchitecture

            # AMD Zen2/Zen3 have double-pumped AVX-512 - prefer AVX2
            if vendor == CPUVendor::AMD && microarch.has_double_pumped_avx512?
              # Check for AVX2
              return SIMDCapability::AVX2 if cpuinfo.includes?("avx2")
              # Fallback
              return SIMDCapability::AVX2 if cpuinfo.includes?("avx")
              return SIMDCapability::SSE2 if cpuinfo.includes?("sse2")
            else
              # Intel or AMD Zen5+ with true AVX-512
              return SIMDCapability::AVX512
            end
          end

          # Check for AVX2 (most modern x86_64)
          return SIMDCapability::AVX2 if cpuinfo.includes?("avx2")

          # Fallback to AVX
          return SIMDCapability::AVX2 if cpuinfo.includes?("avx")

          # Fallback to SSE2 (baseline for x86_64)
          return SIMDCapability::SSE2 if cpuinfo.includes?("sse2")
        end
      {% elsif flag?(:darwin) %}
        # On macOS, use sysctl for CPU feature detection
        begin
          features = `sysctl machdep.cpu.features 2>/dev/null`.downcase
          flags = `sysctl machdep.cpu.leaf7_features 2>/dev/null`.downcase rescue ""

          # Check for AVX-512, with AMD double-pumping consideration
          if flags.includes?("avx512")
            vendor = detect_vendor
            microarch = detect_microarchitecture

            # Avoid double-pumped AVX-512 on AMD
            if vendor == CPUVendor::AMD && microarch.has_double_pumped_avx512?
              return SIMDCapability::AVX2 if features.includes?("avx2")
              return SIMDCapability::AVX2 if features.includes?("avx")
              return SIMDCapability::SSE2
            else
              return SIMDCapability::AVX512
            end
          end

          # Check for AVX2
          return SIMDCapability::AVX2 if features.includes?("avx2")

          # Fallback to AVX
          return SIMDCapability::AVX2 if features.includes?("avx")

          # SSE2 is assumed on all modern macOS x86_64
          return SIMDCapability::SSE2
        rescue
          # If sysctl fails, assume SSE2 baseline
          return SIMDCapability::SSE2
        end
      {% end %}

      SIMDCapability::SSE2 # Conservative fallback for x86_64
    end

    def cpu_count : Int32
      System.cpu_count.to_i32
    end

    def summary : String
      String.build do |io|
        io << "CPU: #{cpu_count} cores, "
        io << "Vendor: #{detect_vendor}, "
        io << "Microarch: #{detect_microarchitecture}, "
        io << "Model: #{cpu_model}, "
        io << "SIMD: #{detect_simd}, "
        io << "P-core: #{is_performance_core?}"
      end
    end
  end
end
