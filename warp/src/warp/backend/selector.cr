module Warp
  module Backend
    class Selector
      def self.select : Base
        # First check for environment variable override
        override = ENV["WARP_BACKEND"]? || ENV["SIMDJSON_BACKEND"]?
        if override
          chosen = override.downcase
          backend = build_override_backend(chosen)
          return backend if backend
        end

        # Auto-select based on architecture and capabilities
        {% if flag?(:aarch64) %}
          NeonBackend.new
        {% elsif flag?(:x86_64) %}
          # x86_64: Prefer AVX2 if available, fall back to SSE2, then scalar
          select_x86_backend
        {% else %}
          ScalarBackend.new
        {% end %}
      end

      private def self.select_x86_backend : Base
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
        ScalarBackend.new
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
        when "scalar"
          ScalarBackend.new
        when "neon"
          {% if flag?(:aarch64) %}
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
        else
          nil
        end
      end
    end

    @@current : Base? = nil
    @@logged : Bool = false

    def self.current : Base
      unless @@current
        @@current = Selector.select
        log_selection(@@current.not_nil!)
      end
      @@current.not_nil!
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
