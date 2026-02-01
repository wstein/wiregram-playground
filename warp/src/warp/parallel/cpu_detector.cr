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

    def detect_simd : SIMDCapability
      return @@capability.not_nil! if @@capability

      {% if flag?(:aarch64) || flag?(:arm) %}
        # ARM architecture - assume NEON support
        @@capability = SIMDCapability::NEON
      {% elsif flag?(:x86_64) || flag?(:i686) %}
        # x86/x64 architecture - detect via cpuid
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
        # On Intel 12th gen+, P-cores have AVX support, E-cores may not
        # This is a rough heuristic - ideally we'd use sched_getaffinity
        capability = detect_simd
        @@is_performance_core = capability != SIMDCapability::None
      {% else %}
        # On ARM, assume all cores have NEON
        @@is_performance_core = true
      {% end %}

      @@is_performance_core.not_nil!
    end

    private def detect_x86_simd : SIMDCapability
      # Crystal doesn't have built-in CPUID access
      # Use /proc/cpuinfo on Linux or system commands
      {% if flag?(:linux) %}
        if File.exists?("/proc/cpuinfo")
          cpuinfo = File.read("/proc/cpuinfo")

          # Check for AVX-512
          return SIMDCapability::AVX512 if cpuinfo.includes?("avx512")

          # Check for AVX2
          return SIMDCapability::AVX2 if cpuinfo.includes?("avx2")

          # Check for SSE2
          return SIMDCapability::SSE2 if cpuinfo.includes?("sse2")
        end
      {% elsif flag?(:darwin) %}
        # On macOS, use sysctl
        output = `sysctl -a 2>/dev/null | grep machdep.cpu.features`

        return SIMDCapability::AVX512 if output.includes?("AVX512")
        return SIMDCapability::AVX2 if output.includes?("AVX2")
        return SIMDCapability::SSE2 if output.includes?("SSE2")
      {% end %}

      SIMDCapability::None
    end

    def cpu_count : Int32
      System.cpu_count.to_i32
    end

    def summary : String
      String.build do |io|
        io << "CPU: #{cpu_count} cores, "
        io << "SIMD: #{detect_simd}, "
        io << "P-core: #{is_performance_core?}"
      end
    end
  end
end
