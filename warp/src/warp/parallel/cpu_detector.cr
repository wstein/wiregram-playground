module Warp::Parallel
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

    private def detect_x86_simd : SIMDCapability
      # Strategy: Check for highest capability first, fall back to lower
      # Prioritize AVX2 as default for modern systems
      {% if flag?(:linux) %}
        if File.exists?("/proc/cpuinfo")
          cpuinfo = File.read("/proc/cpuinfo").downcase

          # Check for AVX-512 (implies AVX2)
          return SIMDCapability::AVX512 if cpuinfo.includes?("avx512")

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

          # Check for AVX-512
          return SIMDCapability::AVX512 if flags.includes?("avx512")

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
        io << "Model: #{cpu_model}, "
        io << "SIMD: #{detect_simd}, "
        io << "P-core: #{is_performance_core?}"
      end
    end
  end
end
