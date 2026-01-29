module Warp
  module Backend
    class Selector
      def self.select : Base
        override = ENV["WARP_BACKEND"]? || ENV["SIMDJSON_BACKEND"]?
        if override
          chosen = override.downcase
          backend = build_override_backend(chosen)
          return backend if backend
        end

        {% if flag?(:aarch64) %}
          NeonBackend.new
        {% else %}
          ScalarBackend.new
        {% end %}
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
            Sse2Backend.new
          {% else %}
            nil
          {% end %}
        when "avx"
          {% if flag?(:x86_64) %}
            AvxBackend.new
          {% else %}
            nil
          {% end %}
        when "avx2"
          {% if flag?(:x86_64) && flag?(:avx2) %}
            Avx2Backend.new
          {% else %}
            nil
          {% end %}
        when "avx512"
          {% if flag?(:x86_64) && flag?(:avx512bw) %}
            Avx512Backend.new
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
