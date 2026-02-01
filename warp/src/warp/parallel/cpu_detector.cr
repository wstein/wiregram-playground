module Warp::Parallel
  # Core information: index, type, and capabilities
  struct CoreInfo
    property core_id : Int32
    property is_performance_core : Bool
    property simd_level : SIMDCapability

    def initialize(@core_id, @is_performance_core = true, @simd_level = SIMDCapability::None)
    end

    def core_type : String
      is_performance_core ? "P-core" : "E-core"
    end

    def to_s(io : IO)
      io << "Core #{core_id} (#{core_type}, #{simd_level})"
    end
  end

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

    # Check if this architecture has double-pumped AVX-512 (AMD Zen 2/3/4)
    def has_double_pumped_avx512? : Bool
      case self
      when Zen2, Zen3, Zen4
        true
      else
        false
      end
    end

    # Check if this architecture implements a full 512-bit AVX-512 datapath
    # (e.g., AMD Zen5 and Intel IceLake). Architectures with a full datapath
    # can execute 512-bit instructions in a single cycle, offering higher
    # throughput for 512-bit floating-point workloads.
    def has_full_avx512? : Bool
      case self
      when Zen5, IceLake
        true
      else
        false
      end
    end
  end

  # ARM architecture version detection
  enum ARMVersion
    ARMv6      # ARM v6 (Pi 1/Zero)
    ARMv7      # ARM v7 (Pi 2, Pi 3 32-bit mode)
    ARMv8      # ARM v8 (Pi 3/4/5 64-bit)
    Unknown    # Unknown ARM version

    def to_s(io : IO)
      io << case self
      when ARMv6   then "armv6"
      when ARMv7   then "armv7"
      when ARMv8   then "armv8"
      when Unknown then "unknown"
      else              "unknown"
      end
    end
  end

  # Raspberry Pi model detection
  enum RaspberryPiModel
    Pi1        # Raspberry Pi 1 (ARMv6)
    PiZero     # Raspberry Pi Zero (ARMv6)
    PiZeroW    # Raspberry Pi Zero W (ARMv6)
    Pi2        # Raspberry Pi 2 (ARMv7)
    Pi3        # Raspberry Pi 3 (ARMv8 32-bit capable)
    Pi3B       # Raspberry Pi 3B+
    Pi4        # Raspberry Pi 4 (ARMv8 64-bit)
    Pi5        # Raspberry Pi 5 (ARMv8 64-bit)
    Unknown    # Not a Raspberry Pi

    def to_s(io : IO)
      io << case self
      when Pi1       then "pi1"
      when PiZero    then "pi-zero"
      when PiZeroW   then "pi-zero-w"
      when Pi2       then "pi2"
      when Pi3       then "pi3"
      when Pi3B      then "pi3b+"
      when Pi4       then "pi4"
      when Pi5       then "pi5"
      when Unknown   then "unknown"
      else                "unknown"
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
    @@arm_version : ARMVersion?
    @@pi_model : RaspberryPiModel?
    @@memory_bandwidth_limited : Bool?

    def detect_simd : SIMDCapability
      return @@capability.not_nil! if @@capability

      {% if flag?(:aarch64) || flag?(:arm) %}
        # ARM architecture - detect NEON based on version
        arm_arch = detect_arm_version

        case arm_arch
        when ARMVersion::ARMv6
          # ARMv6 (Pi 1/Zero) - no NEON support, use scalar
          @@capability = SIMDCapability::None
        when ARMVersion::ARMv7, ARMVersion::ARMv8
          # ARMv7/v8 have NEON support
          @@capability = SIMDCapability::NEON
        else
          # Conservative fallback
          @@capability = SIMDCapability::None
        end
      {% elsif flag?(:x86_64) || flag?(:i686) %}
        # x86/x64 architecture - detect via runtime inspection
        @@capability = detect_x86_simd
      {% else %}
        @@capability = SIMDCapability::None
      {% end %}

      @@capability.not_nil!
    end

    # Detect ARM CPU architecture version
    def detect_arm_version : ARMVersion
      return @@arm_version.not_nil! if @@arm_version

      {% if flag?(:aarch64) %}
        # 64-bit ARM is definitely ARMv8+
        @@arm_version = ARMVersion::ARMv8
      {% elsif flag?(:arm) %}
        # 32-bit ARM - need to detect exact version
        @@arm_version = detect_arm_version_from_cpu
      {% else %}
        @@arm_version = ARMVersion::Unknown
      {% end %}

      @@arm_version.not_nil!
    end

    # Detect Raspberry Pi model
    def detect_pi_model : RaspberryPiModel
      return @@pi_model.not_nil! if @@pi_model

      {% if flag?(:linux) %}
        # Try to detect Raspberry Pi using /proc/device-tree/model
        if File.exists?("/proc/device-tree/model")
          begin
            model_info = File.read("/proc/device-tree/model").strip.downcase

            # Match Raspberry Pi models
            case model_info
            when .includes?("raspberry pi 5")
              @@pi_model = RaspberryPiModel::Pi5
            when .includes?("raspberry pi 4")
              @@pi_model = RaspberryPiModel::Pi4
            when .includes?("raspberry pi 3 model b+")
              @@pi_model = RaspberryPiModel::Pi3B
            when .includes?("raspberry pi 3")
              @@pi_model = RaspberryPiModel::Pi3
            when .includes?("raspberry pi 2")
              @@pi_model = RaspberryPiModel::Pi2
            when .includes?("raspberry pi zero w")
              @@pi_model = RaspberryPiModel::PiZeroW
            when .includes?("raspberry pi zero")
              @@pi_model = RaspberryPiModel::PiZero
            when .includes?("raspberry pi 1") || .includes?("raspberry pi model")
              @@pi_model = RaspberryPiModel::Pi1
            else
              @@pi_model = RaspberryPiModel::Unknown
            end
            return @@pi_model.not_nil! if @@pi_model != RaspberryPiModel::Unknown
          rescue
          end
        end

        # Fallback: check /proc/cpuinfo for BCM2xxx markers
        if File.exists?("/proc/cpuinfo")
          File.each_line("/proc/cpuinfo") do |line|
            if line.starts_with?("Hardware")
              hardware = line.split(":", 2)[1].strip.downcase rescue ""

              case hardware
              when .includes?("bcm2835")
                @@pi_model = RaspberryPiModel::Pi1
              when .includes?("bcm2836")
                @@pi_model = RaspberryPiModel::Pi2
              when .includes?("bcm2837")
                @@pi_model = RaspberryPiModel::Pi3
              when .includes?("bcm2711")
                @@pi_model = RaspberryPiModel::Pi4
              when .includes?("bcm2712")
                @@pi_model = RaspberryPiModel::Pi5
              else
                next
              end

              return @@pi_model.not_nil!
            end
          end
        end
      {% end %}

      @@pi_model = RaspberryPiModel::Unknown
      @@pi_model.not_nil!
    end

    # Check if system has limited memory bandwidth (Pi systems, embedded)
    def memory_bandwidth_limited? : Bool
      return @@memory_bandwidth_limited.not_nil! if @@memory_bandwidth_limited

      pi_model = detect_pi_model

      # Raspberry Pi systems have limited memory bandwidth
      case pi_model
      when RaspberryPiModel::Pi1, RaspberryPiModel::PiZero, RaspberryPiModel::PiZeroW
        @@memory_bandwidth_limited = true  # ~450 MB/s
      when RaspberryPiModel::Pi2
        @@memory_bandwidth_limited = true  # ~800 MB/s
      when RaspberryPiModel::Pi3, RaspberryPiModel::Pi3B
        @@memory_bandwidth_limited = true  # ~1400 MB/s
      when RaspberryPiModel::Pi4
        @@memory_bandwidth_limited = true  # ~3500 MB/s (still limited vs modern x86)
      when RaspberryPiModel::Pi5
        @@memory_bandwidth_limited = true  # ~5000 MB/s
      else
        @@memory_bandwidth_limited = false
      end

      @@memory_bandwidth_limited.not_nil!
    end

    # Check if this is a Raspberry Pi system
    def is_raspberry_pi? : Bool
      detect_pi_model != RaspberryPiModel::Unknown
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

    private def detect_arm_version_from_cpu : ARMVersion
      {% if flag?(:linux) %}
        if File.exists?("/proc/cpuinfo")
          File.each_line("/proc/cpuinfo") do |line|
            if line.starts_with?("CPU part")
              # Parse CPU part: typical values are 0xc07 (ARMv7), 0xd03 (ARMv8), etc.
              cpu_part = line.split(":", 2)[1].strip.downcase rescue ""

              # ARMv8 identifiers (0xd0x range)
              return ARMVersion::ARMv8 if cpu_part.includes?("0xd0") || cpu_part.includes?("0xd1") || cpu_part.includes?("0xd2")

              # ARMv7 identifiers (0xc0x range)
              return ARMVersion::ARMv7 if cpu_part.includes?("0xc0") || cpu_part.includes?("0xc1")

              # ARMv6 identifiers (0xb76)
              return ARMVersion::ARMv6 if cpu_part.includes?("0xb76") || cpu_part.includes?("0xb47")
            end

            # Also check CPU implementer and architecture
            if line.starts_with?("CPU architecture")
              arch_str = line.split(":", 2)[1].strip rescue ""

              # Architecture field format: "ARMv8" or numeric like "8"
              return ARMVersion::ARMv8 if arch_str.includes?("ARMv8") || arch_str.includes?(" 8")
              return ARMVersion::ARMv7 if arch_str.includes?("ARMv7") || arch_str.includes?(" 7")
              return ARMVersion::ARMv6 if arch_str.includes?("ARMv6") || arch_str.includes?(" 6")
            end
          end
        end
      {% elsif flag?(:darwin) %}
        # On macOS ARM (Apple Silicon), it's definitely ARMv8+
        return ARMVersion::ARMv8
      {% end %}

      # Default fallback based on compile-time flags
      {% if flag?(:aarch64) %}
        ARMVersion::ARMv8
      {% elsif flag?(:arm) %}
        # Conservative fallback for 32-bit ARM
        ARMVersion::ARMv7
      {% else %}
        ARMVersion::Unknown
      {% end %}
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

        {% if flag?(:aarch64) || flag?(:arm) %}
          io << "ARM: #{detect_arm_version}, "
          if is_raspberry_pi?
            io << "Pi: #{detect_pi_model}, "
            io << "Bandwidth: #{"limited" if memory_bandwidth_limited?}, "
          end
        {% else %}
          io << "Vendor: #{detect_vendor}, "
          io << "Microarch: #{detect_microarchitecture}, "
        {% end %}

        io << "Model: #{cpu_model}, "
        io << "SIMD: #{detect_simd}, "
        io << "P-core: #{is_performance_core?}"
      end
    end

    # Get detailed SIMD capabilities as a hash
    def simd_capabilities : Hash(String, Bool)
      capabilities = {} of String => Bool

      {% if flag?(:aarch64) || flag?(:arm) %}
        capabilities["NEON"] = true
        arm_v = detect_arm_version
        capabilities["NEON"] = (arm_v == ARMVersion::ARMv8 || arm_v == ARMVersion::ARMv7)
      {% else %}
        simd = detect_simd
        capabilities["SSE2"] = true # Baseline for x86_64
        capabilities["SSE4.1"] = (simd == SIMDCapability::SSE42 || simd == SIMDCapability::AVX || simd == SIMDCapability::AVX2 || simd == SIMDCapability::AVX512)
        capabilities["AVX"] = (simd == SIMDCapability::AVX || simd == SIMDCapability::AVX2 || simd == SIMDCapability::AVX512)
        capabilities["AVX2"] = (simd == SIMDCapability::AVX2 || simd == SIMDCapability::AVX512)
        capabilities["AVX-512"] = (simd == SIMDCapability::AVX512)
      {% end %}

      capabilities
    end

    # Allocate worker IDs to cores based on CPU capability
    # Prioritizes P-cores on heterogeneous systems (Intel Alder Lake+, etc.)
    def allocate_workers_to_cores(num_workers : Int32) : Array(CoreInfo)
      cores = build_core_list

      # Sort by performance (P-cores first), then by core ID
      # P-cores should come before E-cores in the result
      cores.sort! do |a, b|
        if a.is_performance_core != b.is_performance_core
          # Put P-cores (true) before E-cores (false)
          a.is_performance_core ? -1 : 1
        else
          a.core_id <=> b.core_id
        end
      end

      # Take only the requested number of workers, all on most capable cores
      cores[0, num_workers].map_with_index do |core, idx|
        CoreInfo.new(core.core_id, core.is_performance_core, core.simd_level)
      end
    end

    # Build a list of all available cores with their properties
    private def build_core_list : Array(CoreInfo)
      cores = [] of CoreInfo
      total_cores = cpu_count

      {% if flag?(:aarch64) %}
        # Apple Silicon (M1, M2, M3, M4, etc.) - Query sysctl for P/E core count
        p_core_count = query_apple_p_core_count
        simd = detect_simd

        total_cores.times do |i|
          is_p_core = i < p_core_count
          cores << CoreInfo.new(i, is_p_core, simd)
        end
      {% elsif flag?(:arm) %}
        # Other ARM systems (Raspberry Pi, etc.) - typically uniform
        simd = detect_simd
        total_cores.times do |i|
          cores << CoreInfo.new(i, true, simd)
        end
      {% else %}
        # x86_64: Determine P/E core distribution
        vendor = detect_vendor
        microarch = detect_microarchitecture
        simd = detect_simd

        # Alder Lake and newer have heterogeneous cores
        has_heterogeneous_cores = (vendor == CPUVendor::Intel &&
          (microarch == Microarchitecture::AlderLake ||
           microarch == Microarchitecture::RaptorLake))

        if has_heterogeneous_cores
          # Typical distribution: 8 P-cores + 8 E-cores on Alder Lake
          # For now, assume first half are P-cores (this is approximate)
          p_core_count = (total_cores / 2).to_i32
          total_cores.times do |i|
            is_p_core = i < p_core_count
            cores << CoreInfo.new(i, is_p_core, simd)
          end
        else
          # Homogeneous cores (all performance)
          total_cores.times do |i|
            cores << CoreInfo.new(i, true, simd)
          end
        end
      {% end %}

      cores
    end

    # Query Apple Silicon P-core count using sysctl
    private def query_apple_p_core_count : Int32
      {% if flag?(:aarch64) %}
        # Try to read hw.perflevel0.physicalcpu (P-core count on Apple Silicon)
        p_core_str = `sysctl -n hw.perflevel0.physicalcpu 2>/dev/null`.strip rescue ""
        if p_core = p_core_str.to_i?
          return p_core.to_i32
        end
      {% end %}
      # Fallback: conservative estimate (half of total cores)
      (cpu_count / 2).to_i32
    end
  end
end
