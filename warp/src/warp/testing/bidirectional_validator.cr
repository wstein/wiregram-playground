module Warp
  module Testing
    class BidirectionalValidator
      struct RoundTripResult
        getter success : Bool
        getter source : String
        getter intermediate : String
        getter output : String
        getter diagnostics : Array(String)
        getter formatting_delta : Int32

        def initialize(
          @success : Bool,
          @source : String,
          @intermediate : String,
          @output : String,
          @diagnostics : Array(String) = [] of String,
          @formatting_delta : Int32 = 0,
        )
        end
      end

      def self.ruby_to_crystal_to_ruby(source : String) : RoundTripResult
        r2c = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(source.to_slice)
        unless r2c.error == Warp::Core::ErrorCode::Success
          return RoundTripResult.new(false, source, "", "", r2c.diagnostics, 0)
        end

        crystal = r2c.output
        c2r = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(crystal.to_slice)
        unless c2r.error == Warp::Core::ErrorCode::Success
          return RoundTripResult.new(false, source, crystal, "", c2r.diagnostics, 0)
        end

        output = c2r.output
        delta = formatting_delta(normalize(source), normalize(output))
        RoundTripResult.new(true, source, crystal, output, r2c.diagnostics + c2r.diagnostics, delta)
      end

      def self.crystal_to_ruby_to_crystal(source : String) : RoundTripResult
        c2r = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(source.to_slice)
        unless c2r.error == Warp::Core::ErrorCode::Success
          return RoundTripResult.new(false, source, "", "", c2r.diagnostics, 0)
        end

        ruby = c2r.output
        r2c = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(ruby.to_slice)
        unless r2c.error == Warp::Core::ErrorCode::Success
          return RoundTripResult.new(false, source, ruby, "", r2c.diagnostics, 0)
        end

        output = r2c.output
        delta = formatting_delta(normalize(source), normalize(output))
        RoundTripResult.new(true, source, ruby, output, c2r.diagnostics + r2c.diagnostics, delta)
      end

      private def self.normalize(text : String) : String
        text.lines.map(&.rstrip).join("\n").strip
      end

      private def self.formatting_delta(a : String, b : String) : Int32
        max = {a.size, b.size}.max
        diff = 0
        i = 0
        while i < max
          ca = i < a.size ? a[i] : nil
          cb = i < b.size ? b[i] : nil
          diff += 1 if ca != cb
          i += 1
        end
        diff
      end
    end
  end
end
