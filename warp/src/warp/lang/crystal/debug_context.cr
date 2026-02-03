module Warp
  module Lang
    module Crystal
      # Debug context for tracking parsing and transpilation issues
      class DebugContext
        property parser_errors : Bool
        property lexer_errors : Bool
        property allow_cst_fallback : Bool
        property verbose_tokens : Bool
        property show_cst_tree : Bool

        # Collected diagnostics during parsing
        property diagnostics : Array(String)

        def initialize(config : Warp::Lang::Ruby::TranspilerConfig? = nil)
          @parser_errors = config.try(&.debug_parser_errors?) || false
          @lexer_errors = config.try(&.debug_lexer_errors?) || false
          @allow_cst_fallback = config.try(&.debug_cst_fallback?) || true
          @verbose_tokens = config.try(&.debug_verbose_tokens?) || false
          @show_cst_tree = config.try(&.debug_show_cst_tree?) || false
          @diagnostics = [] of String
        end

        def self.from_config(config : Warp::Lang::Ruby::TranspilerConfig?) : DebugContext
          DebugContext.new(config)
        end

        def report_parser_error(message : String, line : Int32 = -1, col : Int32 = -1)
          if @parser_errors
            msg = "PARSER ERROR: #{message}"
            msg += " (line #{line}, col #{col})" if line > -1 && col > -1
            @diagnostics << msg
            puts msg
          end
        end

        def report_lexer_error(message : String, position : Int32 = -1)
          if @lexer_errors
            msg = "LEXER ERROR: #{message}"
            msg += " (pos #{position})" if position > -1
            @diagnostics << msg
            puts msg
          end
        end

        def report_raw_text_fallback(context : String, position : Int32 = -1, token_kind : String = "unknown")
          unless @allow_cst_fallback
            msg = "PARSING FAILED: Falling back to RawText for #{context}"
            msg += " at position #{position}" if position > -1
            msg += " (token: #{token_kind})" unless token_kind == "unknown"
            @diagnostics << msg
            puts msg
          end
        end

        def report_verbose(message : String)
          if @verbose_tokens
            puts "DEBUG: #{message}"
            @diagnostics << message
          end
        end

        def debug_enabled? : Bool
          @parser_errors || @lexer_errors || !@allow_cst_fallback || @verbose_tokens || @show_cst_tree
        end

        def strict_mode? : Bool
          !@allow_cst_fallback
        end
      end
    end
  end
end
