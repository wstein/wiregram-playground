module Warp
  module Lang
    module Common
      # Unified diagnostic and error reporting for all language parsers (Crystal, Ruby, JSON, etc)
      # Provides consistent API for tracking parse errors, fallbacks, and debug information
      #
      # Features:
      # - Consistent error message formatting across languages
      # - Support for different diagnostic levels (errors, warnings, debug)
      # - Optional stdout reporting (disabled by default for cleaner output)
      # - Collection of all diagnostics for batch processing
      # - Per-language context variants (CrystalDiagnosticContext, RubyDiagnosticContext)
      #
      # Example usage:
      #   ctx = CrystalDiagnosticContext.new(verbose: false, report_to_stdout: false)
      #   ctx.report_fallback("unparsed content", position: 42, context: "before def")
      #   ctx.report_parse_error("unexpected token", position: 50, context: "in method body")
      #   puts ctx.diagnostics_summary
      #   puts ctx.diagnostic_counts
      abstract class DiagnosticContext
        property verbose : Bool
        property diagnostics : Array(String)
        property report_to_stdout : Bool

        def initialize(
          @verbose : Bool = false,
          @report_to_stdout : Bool = false,
        )
          @diagnostics = [] of String
        end

        # Report a parse error that prevents successful parsing
        def report_parse_error(message : String, language : String = "unknown", position : Int32 = -1, context : String = "")
          msg = build_error_message("PARSE_ERROR", language, message, position, context)
          @diagnostics << msg
          puts msg if @report_to_stdout
          on_error(msg)
        end

        # Report a graceful fallback (e.g., RawText node)
        def report_fallback(reason : String, language : String = "unknown", position : Int32 = -1, context : String = "")
          msg = build_diagnostic_message("FALLBACK", language, reason, position, context)
          @diagnostics << msg
          puts msg if @report_to_stdout && @verbose
          on_fallback(msg)
        end

        # Report a lexer error
        def report_lexer_error(message : String, language : String = "unknown", position : Int32 = -1)
          msg = build_error_message("LEXER_ERROR", language, message, position)
          @diagnostics << msg
          puts msg if @report_to_stdout
          on_error(msg)
        end

        # Report verbose/debug information
        def report_debug(message : String, language : String = "unknown")
          msg = "[#{language.upcase}:DEBUG] #{message}"
          @diagnostics << msg
          puts msg if @report_to_stdout && @verbose
        end

        # Get all collected diagnostics as a single string
        def diagnostics_summary : String
          @diagnostics.join("\n")
        end

        # Clear all collected diagnostics
        def clear_diagnostics
          @diagnostics.clear
        end

        # Check if there are any errors in the diagnostics
        def has_errors? : Bool
          @diagnostics.any? { |d| d.includes?("ERROR") }
        end

        # Get count of each diagnostic type
        def diagnostic_counts : Hash(String, Int32)
          counts = Hash(String, Int32).new(0)
          @diagnostics.each do |d|
            if d.includes?("PARSE_ERROR")
              counts["parse_errors"] += 1
            elsif d.includes?("LEXER_ERROR")
              counts["lexer_errors"] += 1
            elsif d.includes?("FALLBACK")
              counts["fallbacks"] += 1
            end
          end
          counts
        end

        # Helper to build consistent error messages
        private def build_error_message(kind : String, language : String, message : String, position : Int32 = -1, context : String = "") : String
          msg = "[#{language.upcase}:#{kind}] #{message}"
          msg += " at position #{position}" if position > -1
          msg += " (#{context})" if !context.empty?
          msg
        end

        # Helper to build consistent diagnostic messages
        private def build_diagnostic_message(kind : String, language : String, message : String, position : Int32 = -1, context : String = "") : String
          msg = "[#{language.upcase}:#{kind}] #{message}"
          msg += " at position #{position}" if position > -1
          msg += " (#{context})" if !context.empty?
          msg
        end

        # Subclasses can override these to handle errors differently
        protected def on_error(message : String)
          # Default: no special handling
        end

        protected def on_fallback(message : String)
          # Default: no special handling
        end
      end

      # Crystal-specific diagnostic context extending common context
      class CrystalDiagnosticContext < DiagnosticContext
        def initialize(verbose : Bool = false, report_to_stdout : Bool = false)
          super(verbose, report_to_stdout)
        end

        def report_parse_error(message : String, position : Int32 = -1, context : String = "")
          super(message, "crystal", position, context)
        end

        def report_fallback(reason : String, position : Int32 = -1, context : String = "")
          super(reason, "crystal", position, context)
        end

        def report_lexer_error(message : String, position : Int32 = -1)
          super(message, "crystal", position)
        end

        def report_debug(message : String)
          super(message, "crystal")
        end
      end

      # Ruby-specific diagnostic context extending common context
      class RubyDiagnosticContext < DiagnosticContext
        def initialize(verbose : Bool = false, report_to_stdout : Bool = false)
          super(verbose, report_to_stdout)
        end

        def report_parse_error(message : String, position : Int32 = -1, context : String = "")
          super(message, "ruby", position, context)
        end

        def report_fallback(reason : String, position : Int32 = -1, context : String = "")
          super(reason, "ruby", position, context)
        end

        def report_lexer_error(message : String, position : Int32 = -1)
          super(message, "ruby", position)
        end

        def report_debug(message : String)
          super(message, "ruby")
        end
      end
    end
  end
end
