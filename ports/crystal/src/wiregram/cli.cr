# frozen_string_literal: true

require "json"
require "http/server"
require "option_parser"

# Pre-load all language modules
require "./languages/expression"
require "./languages/json"
require "./languages/ucl"

module WireGram
  module CLI
    # Small helper to discover language modules
    class Languages
      LANG_MAP = {
        "expression" => WireGram::Languages::Expression,
        "json" => WireGram::Languages::Json,
        "ucl" => WireGram::Languages::Ucl
      }

      def self.available : Array(String)
        LANG_MAP.keys
      end

      def self.module_for(name : String)
        LANG_MAP[name]?
      end

      def self.supports?(name : String, method : Symbol) : Bool
        case name
        when "expression", "json", "ucl"
          case method
          when :process, :process_pretty, :tokenize, :tokenize_stream, :parse, :parse_stream
            true
          else
            false
          end
        else
          false
        end
      end
    end

    # Runner implements commands and parsing
    class Runner
      def self.start(argv : Array(String))
        new(argv).run
      end

      @simd = false
      @symbolic_utf8 = false
      @upfront_rules = false
      @branchless = false
      @brzozowski = false
      @gpu = false
      @verbose = false

      def initialize(argv : Array(String))
        @argv = argv.dup
        @global = {"format" => "text"} of String => String
      end

      def run
        consume_global_options
        command = @argv.shift?

        case command
        when nil, "help", "--help", "-h"
          print_help
        when "list"
          list_languages
        when "server"
          start_server
        when "snapshot"
          handle_snapshot(@argv)
        else
          # treat as language command: <language> <action> [opts]
          if command && Languages.available.includes?(command)
            language = command
            action = @argv.shift? || "help"

            # Parse language-specific flags BEFORE handling the language
            @argv = parse_common_flags(@argv)

            if action == "benchmark"
              handle_benchmark(language, @argv)
            else
              handle_language(language, action, @argv)
            end
          else
            STDERR.puts "Unknown command: #{command}"
            print_help
            exit 1
          end
        end
      end

      private def parse_common_flags(argv)
        remaining = [] of String
        OptionParser.parse(argv) do |opts|
          opts.on("--simd", "Enable SIMD acceleration") { @simd = true }
          opts.on("--symbolic-utf8", "Enable symbolic UTF-8 processing") { @symbolic_utf8 = true }
          opts.on("--upfront-rules", "Enable upfront lexing rules (Stage 1)") { @upfront_rules = true }
          opts.on("--branchless", "Enable branchless Stage 2 dispatch") { @branchless = true }
          opts.on("--brzozowski", "Enable Brzozowski Derivatives engine") { @brzozowski = true }
          opts.on("--gpu", "Enable M4 GPU acceleration (Metal)") { @gpu = true }
          opts.on("--unquoted-simd", "Enable SIMD for unquoted string scanning (UCL only)") { @simd = true }
          opts.on("--full-opt", "Enable all optimizations (simd, symbolic-utf8, upfront-rules, branchless)") do
            @simd = true
            @symbolic_utf8 = true
            @upfront_rules = true
            @branchless = true
          end
          opts.on("--verbose", "Show internal logs") { @verbose = true }
          opts.unknown_args do |args|
            remaining = args
          end
        end
        remaining
      end

      def print_help
        puts <<-HELP
          WireGram umbrella CLI

          Usage:
            wiregram list                            # list available languages
            wiregram <language> help                 # show help for language
            wiregram <language> inspect [opts]       # run full pipeline and show JSON output
            wiregram <language> parse [opts]         # parse input (stdin or file)
            wiregram <language> tokenize [opts]      # show tokens
            wiregram <language> benchmark <type> <file> # benchmark performance
            wiregram server [--port 4567]            # start a JSON HTTP server for programmatic use
            wiregram snapshot --generate --language json

          Global options:
            --format json|text    Output format (default: text)

          Optimization flags (can be used with inspect, parse, tokenize):
            --simd                Enable NEON SIMD acceleration (M4)
            --symbolic-utf8       Enable symbolic UTF-8 processing
            --upfront-rules       Enable upfront lexing rules (Stage 1)
            --branchless          Enable branchless Stage 2 dispatch
            --brzozowski          Enable Brzozowski Derivatives engine
            --gpu                 Enable M4 GPU acceleration (Metal)
            --unquoted-simd       Enable SIMD for unquoted string scanning (UCL only)
            --full-opt            Enable all optimizations at once

          Examples:
            echo '{ "a":1 }' | wiregram json inspect --pretty --simd
            wiregram list

          For language-specific options: wiregram <language> help
        HELP
      end

      def list_languages
        puts "Available languages:"
        Languages.available.each { |lang| puts "  - #{lang}" }
      end

      def start_server
        options = {"port" => 4567} of String => Int32
        parser = OptionParser.new do |opts|
          opts.on("--port PORT", "HTTP port (default: 4567)") do |port|
            options["port"] = port.to_i
          end
        end
        parser.parse(@argv)

        server = HTTP::Server.new do |context|
          if context.request.path == "/v1/process"
            if context.request.method != "POST"
              context.response.status = HTTP::Status::METHOD_NOT_ALLOWED
              next
            end

            body = context.request.body.try(&.gets_to_end) || ""
            payload = JSON.parse(body)

            language = payload["language"]?.try(&.as_s)
            input = payload["input"]?.try(&.as_s) || ""
            pretty = payload["pretty"]?.try(&.as_bool) || false

            unless language && Languages.available.includes?(language)
              context.response.status = HTTP::Status::BAD_REQUEST
              context.response.content_type = "application/json"
              context.response.print(json_compact({ error: "unsupported language" }))
              next
            end

            result = process_language(language, input, pretty)

            context.response.content_type = "application/json"
            context.response.print(json_compact(deep_convert_nodes(result)))
          else
            context.response.status = HTTP::Status::NOT_FOUND
          end
        rescue JSON::ParseException
          context.response.status = HTTP::Status::BAD_REQUEST
          context.response.content_type = "application/json"
          context.response.print(json_compact({ error: "invalid json body" }))
        rescue ex
          context.response.status = HTTP::Status::INTERNAL_SERVER_ERROR
          context.response.content_type = "application/json"
          context.response.print(json_compact({ error: ex.message }))
        end

        Signal::INT.trap do
          server.close
        end

        puts "WireGram server running on http://localhost:#{options["port"]} (Ctrl-C to stop)"
        server.bind_tcp(options["port"])
        server.listen
      end

      def handle_snapshot(argv : Array(String))
        generate = false
        lang = nil

        opts = OptionParser.new do |o|
          o.on("--generate", "Generate snapshots") { generate = true }
          o.on("--language LANG", "Limit to language") { |v| lang = v }
        end

        begin
          opts.parse(argv)
        rescue ex : OptionParser::InvalidOption
          STDERR.puts ex.message
          exit 1
        end

        if generate
          if lang
            system("rake", ["snapshots:generate_for", lang.not_nil!])
          else
            system("rake", ["snapshots:generate"])
          end
        else
          STDERR.puts "Specify --generate and optionally --language <name>"
        end
      end

      def handle_benchmark(language : String, argv : Array(String))
        bench_type = argv.shift?
        file_path = argv.shift?

        unless bench_type && file_path && File.file?(file_path)
          STDERR.puts "Usage: wiregram <language> benchmark <tokenize|parse|process> <file>"
          exit 1
        end

        # Preload to RAM
        input = File.read(file_path)
        size_mb = input.bytesize.to_f / (1024 * 1024)

        STDERR.puts "Benchmarking #{language} #{bench_type} on #{file_path} (#{size_mb.round(2)} MB)..."

        start_time = Time.instant

        case bench_type
        when "tokenize"
          tokenize_stream(language, input) do |_token|
            # discard
          end
        when "parse"
          parse_stream(language, input) do |_node|
            # discard
          end
        when "process"
          process_language(language, input, false)
        else
          STDERR.puts "Unknown benchmark type: #{bench_type}"
          exit 1
        end

        end_time = Time.instant
        duration = end_time - start_time
        ms = duration.to_f * 1000
        throughput = size_mb / duration.to_f

        puts "--- Benchmark Results ---"
        puts "File: #{file_path} (#{size_mb.round(2)} MB)"
        puts "Type: #{bench_type}"
        puts "Duration: #{ms.round(2)} ms"
        puts "Throughput: #{throughput.round(2)} MB/s"
      end

      def handle_language(language : String, action : String, argv : Array(String))
        unless Languages.available.includes?(language)
          STDERR.puts "Unknown language: #{language}"
          exit 1
        end

        case action
        when "help", "--help", "-h"
          print_language_help(language)
        when "inspect"
          input = read_input(argv)
          pretty = argv.includes?("--pretty")
          result = process_language(language, input, pretty)
          output_result(result)
        when "tokenize"
          input = read_input(argv)
          tokenize_stream(language, input) do |token|
            puts json_compact(token_to_hash(token))
          end
        when "parse"
          input = read_input(argv)
          parse_stream(language, input) do |node|
            h = node ? node.to_h : nil
            if @global["format"] == "json" || ENV["WIREGRAM_FORMAT"]? == "json"
              puts json_compact(h)
            else
              puts json_pretty(h)
            end
          end
        else
          STDERR.puts "Unknown action: #{action}"
          print_language_help(language)
          exit 1
        end
      end

      def print_language_help(language : String)
        puts "#{language} commands:"
        puts "  inspect [--pretty]              Run full pipeline and show detailed result"
        puts "  tokenize                        Show tokens (if supported)"
        puts "  parse                           Show AST (if supported)"
        puts "  benchmark <type> <file>         Benchmark performance (type: tokenize|parse|process)"
        puts "Notes: Outputs are in plaintext by default. Use --format json to get JSON."
        puts "Detected capabilities:"
        %i[process process_pretty tokenize parse].each do |m|
          puts "  - #{m}: #{Languages.supports?(language, m)}"
        end
      end

      def read_input(argv : Array(String))
        # file path or STDIN
        if argv.first? && !argv.first.starts_with?("--") && File.file?(argv.first)
          File.read(argv.shift)
        elsif STDIN.tty?
          # Avoid blocking when no stdin is provided (e.g., in tests)
          # If stdin is a TTY (interactive), treat as empty input
          ""
        else
          STDIN.gets_to_end
        end
      end

      def output_result(result)
        ENV["WIREGRAM_AST_MAX_DEPTH"]? ? ENV["WIREGRAM_AST_MAX_DEPTH"].to_s.to_i : 3

        if @global["format"] == "json" || ENV["WIREGRAM_FORMAT"]? == "json"
          puts json_pretty(deep_convert_nodes(result))
        elsif result.is_a?(Hash)
          # Nicely print parts, with special handling for AST Node objects
          result.each do |k, v|
            puts "== #{k} =="

            if v.is_a?(WireGram::Core::Node)
              # Print AST as full JSON so it matches snapshot format
              puts v.to_json
            elsif v.is_a?(WireGram::Languages::Expression::UOM)
              root = v.root
              puts json_pretty(root ? JSON.parse(root.not_nil!.to_json) : nil)
            # elsif v.is_a?(WireGram::Languages::Json::Uom)
            #   result = "null"
            #   if v.root
            #     result = v.root.not_nil!.to_json_string
            #   end
            #   puts json_pretty(result)
            elsif v.is_a?(WireGram::Languages::Ucl::UOM)
              puts json_pretty(v.to_simple_json)
            elsif v.is_a?(Array) || v.is_a?(Hash)
              puts json_pretty(deep_convert_nodes(v))
            elsif v.is_a?(String)
              s = v
              printed = try_print_as_json(s)
              puts s unless printed
            else
              puts v.inspect
            end

            puts
          end
        else
          puts result
        end
      end

      # Convert objects containing Node instances to JSON::Any for pretty output.
      def deep_convert_nodes(obj) : JSON::Any
        case obj
        when WireGram::Core::Node
          json_any_from(obj.to_h)
        when WireGram::Languages::Expression::UOM
          root = obj.root
          json_any_from(root ? JSON.parse(root.not_nil!.to_json) : nil)
        when WireGram::Languages::Json::UOM
          root = obj.root
          json_any_from(root ? JSON.parse(root.not_nil!.to_json_string) : nil)
        when WireGram::Languages::Ucl::UOM
          json_any_from(obj.to_simple_json)
        else
          json_any_from(obj)
        end
      end

      private def json_any_from(value) : JSON::Any
        case value
        when JSON::Any
          value
        when Hash
          mapped = {} of String => JSON::Any
          value.each do |k, v|
            mapped[k.to_s] = json_any_from(v)
          end
          JSON::Any.new(mapped)
        when Array
          mapped_arr = [] of JSON::Any
          value.each do |v|
            mapped_arr << json_any_from(v)
          end
          JSON::Any.new(mapped_arr)
        when WireGram::Core::Token
          json_any_from(value.to_h)
        when WireGram::Core::Node
          json_any_from(value.to_h)
        when WireGram::Languages::Json::UOM
          root = value.root
          json_any_from(root ? JSON.parse(root.not_nil!.to_json_string) : nil)
        when WireGram::Languages::Expression::UOM
          root = value.root
          json_any_from(root ? JSON.parse(root.not_nil!.to_json) : nil)
        when WireGram::Languages::Ucl::UOM
          json_any_from(value.to_simple_json)
        when WireGram::Languages::Ucl::UOM::RawNumber
          JSON::Any.new(value.raw)
        when WireGram::Core::TokenType, Symbol
          JSON::Any.new(value.to_s)
        when Int32
          JSON::Any.new(value.to_i64)
        when Int64, Float64, String, Bool, Nil
          JSON::Any.new(value)
        else
          JSON::Any.new(value.to_s)
        end
      end

      def try_print_as_json(str : String)
        parsed = JSON.parse(str)
        puts json_pretty(deep_convert_nodes(parsed))
        true
      rescue JSON::ParseException
        false
      rescue ex : Exception
        false
      end

      private def consume_global_options
        index = @argv.index("--format")
        if index && (value = @argv[index + 1]?)
          @global["format"] = value
          @argv.delete_at(index + 1)
          @argv.delete_at(index)
        end
      end

      private def process_language(language : String, input : String, pretty : Bool)
        case language
        when "expression"
          # pretty ? WireGram::Languages::Expression.process_pretty(input) : WireGram::Languages::Expression.process(input)
          # For expression, we'll keep it simple for now as it's less performance critical
          WireGram::Languages::Expression.process(input, verbose: @verbose)
        when "json"
          pretty ? WireGram::Languages::Json.process_pretty(input, use_simd: @simd, use_symbolic_utf8: @symbolic_utf8, use_upfront_rules: @upfront_rules, use_branchless: @branchless, use_brzozowski: @brzozowski, use_gpu: @gpu, verbose: @verbose) :
                   WireGram::Languages::Json.process(input, use_simd: @simd, use_symbolic_utf8: @symbolic_utf8, use_upfront_rules: @upfront_rules, use_branchless: @branchless, use_brzozowski: @brzozowski, use_gpu: @gpu, verbose: @verbose)
        when "ucl"
          # UCL's process handles internal defaults and can be extended if needed
          WireGram::Languages::Ucl.process(input, use_simd: @simd, use_symbolic_utf8: @symbolic_utf8, use_upfront_rules: @upfront_rules, use_branchless: @branchless, use_brzozowski: @brzozowski, use_gpu: @gpu, verbose: @verbose)
        else
          raise "Unknown language: #{language}"
        end
      end

      private def tokenize_stream(language : String, input : String, &block : WireGram::Core::Token ->)
        case language
        when "expression"
          WireGram::Languages::Expression.tokenize_stream(input, verbose: @verbose) { |token| yield token }
        when "json"
          WireGram::Languages::Json.tokenize_stream(input, use_simd: @simd, use_symbolic_utf8: @symbolic_utf8, use_upfront_rules: @upfront_rules, use_branchless: @branchless, use_brzozowski: @brzozowski, use_gpu: @gpu, verbose: @verbose) { |token| yield token }
        when "ucl"
          WireGram::Languages::Ucl.tokenize_stream(input, use_simd: @simd, use_symbolic_utf8: @symbolic_utf8, use_upfront_rules: @upfront_rules, use_branchless: @branchless, use_brzozowski: @brzozowski, use_gpu: @gpu, verbose: @verbose) { |token| yield token }
        else
          raise "Unknown language: #{language}"
        end
      end

      private def parse_stream(language : String, input : String, &block : WireGram::Core::Node? ->)
        case language
        when "expression"
          WireGram::Languages::Expression.parse_stream(input, verbose: @verbose) { |node| yield node }
        when "json"
          WireGram::Languages::Json.parse_stream(input, use_simd: @simd, use_symbolic_utf8: @symbolic_utf8, use_upfront_rules: @upfront_rules, use_branchless: @branchless, use_brzozowski: @brzozowski, use_gpu: @gpu, verbose: @verbose) { |node| yield node }
        when "ucl"
          WireGram::Languages::Ucl.parse_stream(input, use_simd: @simd, use_symbolic_utf8: @symbolic_utf8, use_upfront_rules: @upfront_rules, use_branchless: @branchless, use_brzozowski: @brzozowski, use_gpu: @gpu, verbose: @verbose) { |node| yield node }
        else
          raise "Unknown language: #{language}"
        end
      end

      private def token_to_hash(token : WireGram::Core::Token)
        json_any_from(token.to_h)
      end

      private def json_pretty(obj)
        JSON.build(indent: "  ") do |json|
          obj.to_json(json)
        end
      end

      private def json_compact(obj)
        JSON.build do |json|
          obj.to_json(json)
        end
      end
    end
  end
end

WireGram::CLI::Runner.start(ARGV)
