# frozen_string_literal: true

require 'optparse'
require 'json'
require 'webrick'

# Pre-load all language modules
require 'wiregram/languages/expression'
require 'wiregram/languages/json'
require 'wiregram/languages/ucl'

module WireGram
  module CLI
    # Small helper to discover language modules
    class Languages
      LANG_MAP = {
        'expression' => WireGram::Languages::Expression,
        'json' => WireGram::Languages::Json,
        'ucl' => WireGram::Languages::Ucl
      }.freeze

      def self.available
        LANG_MAP.keys
      end

      def self.module_for(name)
        LANG_MAP[name]
      end

      def self.supports?(name, method)
        mod = module_for(name)
        mod&.respond_to?(method)
      end
    end

    # Runner implements commands and parsing
    class Runner
      def self.start(argv)
        new(argv).run
      end

      def initialize(argv)
        @argv = argv.dup
        @global = {
          format: 'text'
        }
      end

      def run
        command = @argv.shift

        case command
        when nil, 'help', '--help', '-h'
          print_help
        when 'list'
          list_languages
        when 'server'
          start_server
        when 'snapshot'
          handle_snapshot(@argv)
        else
          # treat as language command: <language> <action> [opts]
          if Languages.available.include?(command)
            language = command
            action = @argv.shift || 'help'
            handle_language(language, action, @argv)
          else
            warn "Unknown command: #{command}"
            print_help
            exit 1
          end
        end
      end

      def print_help
        puts <<~HELP
          WireGram umbrella CLI

          Usage:
            wiregram list                            # list available languages
            wiregram <language> help                 # show help for language
            wiregram <language> inspect [--pretty]   # run full pipeline and show JSON output
            wiregram <language> parse                # parse input (stdin or file)
            wiregram <language> tokenize             # show tokens
            wiregram server [--port 4567]            # start a JSON HTTP server for programmatic use
            wiregram snapshot --generate --language json

          Global options:
            --format json|text    Output format (default: text)

          Examples:
            echo '{ "a":1 }' | wiregram json inspect --pretty
            wiregram list

          For language-specific options: wiregram <language> help
        HELP
      end

      def list_languages
        puts 'Available languages:'
        Languages.available.each { |l| puts "  - #{l}" }
      end

      def start_server
        options = { port: 4567 }
        optp = OptionParser.new do |opts|
          opts.on('--port PORT', Integer) { |p| options[:port] = p }
        end
        optp.parse!(@argv)

        server = WEBrick::HTTPServer.new(Port: options[:port], AccessLog: [], Logger: WEBrick::Log.new(File::NULL))

        server.mount_proc '/v1/process' do |req, res|
          body = req.body || ''
          payload = JSON.parse(body)
          language = payload['language']
          input = payload['input'] || ''
          payload['mode'] || 'process'

          unless Languages.available.include?(language)
            res.status = 400
            res.body = { error: 'unsupported language' }.to_json
            next
          end

          mod = Languages.module_for(language)
          result = if mod.respond_to?('process')
                     if payload['pretty']
                       mod.process_pretty(input)
                     else
                       mod.process(input)
                     end
                   else
                     { error: 'process not available for language' }
                   end

          res['Content-Type'] = 'application/json'
          res.body = result.to_json
        rescue JSON::ParserError
          res.status = 400
          res.body = { error: 'invalid json body' }.to_json
        rescue StandardError => e
          res.status = 500
          res.body = { error: e.message }.to_json
        end

        trap('INT') do
          server.shutdown
        end
        puts "WireGram server running on http://localhost:#{options[:port]} (Ctrl-C to stop)"
        server.start
      end

      def handle_snapshot(argv)
        # Simple pass-through to rake tasks - lightweight integration
        opts = OptionParser.new do |o|
          o.on('--generate') do |_v|
            @generate = true
          end
          o.on('--language LANG') { |v| @lang = v }
        end
        begin
          opts.parse!(argv)
        rescue OptionParser::InvalidOption => e
          warn e.message
          exit 1
        end

        if @generate
          if @lang
            system('rake', 'snapshots:generate_for', @lang)
          else
            system('rake', 'snapshots:generate')
          end
        else
          warn 'Specify --generate and optionally --language <name>'
        end
      end

      def handle_language(language, action, argv)
        mod = Languages.module_for(language)
        unless mod
          warn "Unknown language: #{language}"
          exit 1
        end

        case action
        when 'help', '--help', '-h'
          print_language_help(language, mod)
        when 'inspect'
          input = read_input(argv)
          pretty = argv.include?('--pretty')
          result = if pretty && mod.respond_to?(:process_pretty)
                     mod.process_pretty(input)
                   else
                     mod.process(input)
                   end
          output_result(result)
        when 'tokenize'
          input = read_input(argv)
          if mod.respond_to?(:tokenize_stream)
            # Stream tokens one per line as JSON (efficient for large files)
            mod.tokenize_stream(input) do |token|
              puts JSON.generate(token)
            end
          elsif mod.respond_to?(:tokenize)
            result = mod.tokenize(input)
            output_result({ tokens: result })
          else
            warn "tokenize not supported for #{language}"
            exit 2
          end
        when 'parse'
          input = read_input(argv)
          if mod.respond_to?(:parse_stream)
            # Stream AST nodes as they are built; emit one JSON object per line
            mod.parse_stream(input) do |node|
              h = node&.to_h
              if @global[:format] == 'json' || ENV['WIREGRAM_FORMAT'] == 'json'
                puts JSON.generate(h)
              else
                puts JSON.pretty_generate(h)
              end
            end
          elsif mod.respond_to?(:parse)
            result = mod.parse(input)
            output_result({ ast: result })
          else
            warn "parse not supported for #{language}"
            exit 2
          end
        else
          warn "Unknown action: #{action}"
          print_language_help(language, mod)
          exit 1
        end
      end

      def print_language_help(language, mod)
        puts "#{language} commands:"
        puts '  inspect [--pretty]      Run full pipeline and show detailed result'
        puts '  tokenize                Show tokens (if supported)'
        puts '  parse                   Show AST (if supported)'
        puts 'Notes: Outputs are in plaintext by default. Use --format json to get JSON.'
        puts 'Detected capabilities:'
        %i[process process_pretty tokenize parse].each do |m|
          puts "  - #{m}: #{mod.respond_to?(m)}"
        end
      end

      def read_input(argv)
        # file path or STDIN
        if argv&.first && !argv.first.start_with?('--') && File.file?(argv.first)
          File.read(argv.shift)
        elsif $stdin.tty?
          # Avoid blocking when no stdin is provided (e.g., in tests)
          # If stdin is a TTY (interactive), treat as empty input
          ''
        else
          $stdin.read
        end
      end

      def output_result(result)
        ENV['WIREGRAM_AST_MAX_DEPTH']&.to_i || 3

        # Normalize UOM output: drop raw :uom objects and expose a JSON-friendly :uom value
        if result.is_a?(Hash)
          if result.key?(:uom_json)
            result[:uom] = result.delete(:uom_json)
          elsif result.key?(:uom)
            u = result[:uom]
            if u.respond_to?(:to_simple_json)
              result[:uom] = u.to_simple_json
            else
              # Drop raw UOM objects that aren't JSON-friendly
              result.delete(:uom)
            end
          end
        end

        if @global[:format] == 'json' || ENV['WIREGRAM_FORMAT'] == 'json'
          puts JSON.pretty_generate(deep_convert_nodes(result))
        elsif result.is_a?(Hash)
          # Nicely print parts, with special handling for AST Node objects
          result.each do |k, v|
            puts "== #{k} =="

            if v.is_a?(WireGram::Core::Node)
              # Print AST as full JSON so it matches snapshot format
              puts v.to_json
            elsif v.is_a?(Array) && v.all? { |el| el.is_a?(WireGram::Core::Node) }
              arr = v.map(&:to_h)
              puts JSON.pretty_generate(arr)
            elsif v.is_a?(Array) || v.is_a?(Hash)
              puts JSON.pretty_generate(deep_convert_nodes(v))
            elsif v.is_a?(String)
              s = v

              # If the string itself is JSON, pretty-print it
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

      # Convert objects containing Node instances to Hash/Array structures suitable for JSON
      def deep_convert_nodes(obj)
        case obj
        when WireGram::Core::Node
          obj.to_h
        when Hash
          obj.transform_values { |v| deep_convert_nodes(v) }
        when Array
          obj.map { |v| deep_convert_nodes(v) }
        when String
          obj
        else
          obj
        end
      end

      def try_print_as_json(str)
        # Try to parse and pretty-print as JSON
        parsed = JSON.parse(str)
        puts JSON.pretty_generate(deep_convert_nodes(parsed))
        true
      rescue JSON::ParserError
        # Try to unescape JSON-style escape sequences (e.g. " and \n)
        unescaped = JSON.parse("\"#{str.gsub('"', '\\\"')}\"")
        puts unescaped
        true
      rescue StandardError
        # Could not parse as JSON
        false
      end
    end
  end
end
