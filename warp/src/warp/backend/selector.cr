module Warp
  module Backend
    class Selector
      def self.select : Base
        # First check for environment variable override
        override = ENV["WARP_BACKEND"]?
        if override
          chosen = override.downcase
          backend = build_override_backend(chosen)
          return backend if backend
        end

        # Auto-select based on architecture and capabilities
        {% if flag?(:aarch64) %}
          select_arm_backend
        {% elsif flag?(:arm) %}
          select_arm_backend
        {% elsif flag?(:x86_64) %}
          # x86_64: Prefer AVX2 if available, fall back to SSE2, then scalar
          select_x86_backend
        {% else %}
          raise "SIMD backend not available for this architecture"
        {% end %}
      end

      private def self.select_arm_backend : Base
        # ARM backend selection with Raspberry Pi optimization
        arm_version = Warp::Parallel::CPUDetector.detect_arm_version

        case arm_version
        when Warp::Parallel::ARMVersion::ARMv6
          # ARMv6 (Raspberry Pi 1/Zero) - no NEON support
          # Use the ARMv6-optimized backend to provide better performance than generic scalar
          return ARMv6Backend.new
        when Warp::Parallel::ARMVersion::ARMv7
          # ARMv7 (Raspberry Pi 2) - has NEON but with limitations
          # Use NEON for better performance
          return NeonBackend.new
        when Warp::Parallel::ARMVersion::ARMv8
          # ARMv8 (Raspberry Pi 3/4/5, Apple Silicon) - full NEON/SIMD support
          return NeonBackend.new
        else
          # Unknown ARM - use NEON as safe default
          return NeonBackend.new
        end
      end

      private def self.select_x86_backend : Base
        # Special handling for AMD with double-pumped AVX-512 (Zen2/Zen3)
        vendor = Warp::Parallel::CPUDetector.detect_vendor
        microarch = Warp::Parallel::CPUDetector.detect_microarchitecture

        # Skip AVX-512 for AMD microarchitectures that are double-pumped
        # (Zen2/Zen3/Zen4) because AVX2 will be faster in those cases.
        if vendor == Warp::Parallel::CPUVendor::AMD && microarch.has_double_pumped_avx512?
          # For AMD double-pumped microarchitectures, skip AVX-512 and go straight to AVX2
          if can_use_avx2?
            return Avx2Backend.new
          end
          if can_use_avx?
            return AvxBackend.new
          end
          if can_use_sse2?
            return Sse2Backend.new
          end
          return ScalarBackend.new
        end

        # For other systems (Intel, AMD Zen4/5+), use standard priority
        # Try AVX-512 first
        if can_use_avx512?
          return Avx512Backend.new
        end

        # Try AVX2 (most common on modern x86_64)
        if can_use_avx2?
          return Avx2Backend.new
        end

        # Try AVX (older but still good)
        if can_use_avx?
          return AvxBackend.new
        end

        # Fall back to SSE2 (baseline for x86_64)
        if can_use_sse2?
          return Sse2Backend.new
        end

        # Last resort: scalar
        return ScalarBackend.new
      end

      private def self.can_use_avx512? : Bool
        {% if flag?(:x86_64) && flag?(:avx512bw) %}
          # At compile time, AVX-512 is available
          # At runtime, check CPU support
          cpu_supports_avx512?
        {% else %}
          false
        {% end %}
      end

      private def self.can_use_avx2? : Bool
        {% if flag?(:x86_64) && flag?(:avx2) %}
          cpu_supports_avx2?
        {% else %}
          false
        {% end %}
      end

      private def self.can_use_avx? : Bool
        {% if flag?(:x86_64) %}
          cpu_supports_avx?
        {% else %}
          false
        {% end %}
      end

      private def self.can_use_sse2? : Bool
        {% if flag?(:x86_64) && flag?(:sse2) %}
          true # SSE2 is baseline for x86_64
        {% else %}
          false
        {% end %}
      end

      # Runtime CPU capability detection
      private def self.cpu_supports_avx512? : Bool
        capability = Warp::Parallel::CPUDetector.detect_simd
        capability == Warp::Parallel::SIMDCapability::AVX512
      end

      private def self.cpu_supports_avx2? : Bool
        capability = Warp::Parallel::CPUDetector.detect_simd
        capability == Warp::Parallel::SIMDCapability::AVX2 || capability == Warp::Parallel::SIMDCapability::AVX512
      end

      private def self.cpu_supports_avx? : Bool
        capability = Warp::Parallel::CPUDetector.detect_simd
        capability != Warp::Parallel::SIMDCapability::None && capability != Warp::Parallel::SIMDCapability::NEON
      end

      def self.select_by_name(name : String) : Base?
        build_override_backend(name.downcase)
      end

      private def self.build_override_backend(name : String) : Base?
        case name
        when "neon"
          {% if flag?(:aarch64) || flag?(:arm) %}
            NeonBackend.new
          {% else %}
            nil
          {% end %}
        when "sse2"
          {% if flag?(:x86_64) && flag?(:sse2) %}
            if can_use_sse2?
              Sse2Backend.new
            else
              nil
            end
          {% else %}
            nil
          {% end %}
        when "avx"
          {% if flag?(:x86_64) %}
            if can_use_avx?
              AvxBackend.new
            else
              nil
            end
          {% else %}
            nil
          {% end %}
        when "avx2"
          {% if flag?(:x86_64) && flag?(:avx2) %}
            if can_use_avx2?
              Avx2Backend.new
            else
              nil
            end
          {% else %}
            nil
          {% end %}
        when "avx512"
          {% if flag?(:x86_64) && flag?(:avx512bw) %}
            if can_use_avx512?
              Avx512Backend.new
            else
              nil
            end
          {% else %}
            nil
          {% end %}
        when "armv6"
          {% if flag?(:arm) %}
            ARMv6Backend.new
          {% else %}
            nil
          {% end %}
        when "scalar"
          # Scalar backend is always available as a fallback
          ScalarBackend.new
        else
          nil
        end
      end
    end

    @@current : Base? = nil
    @@logged : Bool = false
    @@no_simd_logged : Bool = false

    def self.current : Base
      unless @@current
        @@current = Selector.select
        log_selection(@@current.not_nil!)
        report_no_simd_if_needed(@@current.not_nil!)
      end
      @@current.not_nil!
    end

    private def self.report_no_simd_if_needed(backend : Base) : Nil
      return if @@no_simd_logged
      @@no_simd_logged = true
      # Only print if we selected Scalar and CPU reports no SIMD capability
      begin
        capability = Warp::Parallel::CPUDetector.detect_simd
        if backend.is_a?(ScalarBackend) && capability == Warp::Parallel::SIMDCapability::None
          STDERR.puts "warp backend=scalar (no SIMD instructions detected on this CPU)"
        end
      rescue ex
        # Be conservative: don't crash if CPU detection fails
        STDERR.puts "warp backend=scalar (no SIMD instructions detected or CPU detection failed)"
      end
    end

    def self.reset(backend : Base? = nil)
      @@current = backend
      @@logged = false
    end

    def self.select_by_name(name : String) : Base?
      Selector.select_by_name(name)
    end

    def self.log_selection(backend : Base) : Nil
      return if @@logged
      return unless ENV["WARP_BACKEND_LOG"]? || ENV["WARP_BACKEND_TELEMETRY"]?
      @@logged = true
      STDERR.puts "warp backend=#{backend.name}"
    end
  end
end
