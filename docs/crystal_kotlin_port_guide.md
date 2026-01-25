# Crystal Port Guide for WireGram CLI

This guide shows how to port the WireGram umbrella CLI to Crystal with minimal effort.

## Approach: Shell Out + JSON Parsing (Recommended for fast adoption)

The simplest and fastest path is to implement a thin Crystal CLI that:
1. Parses CLI arguments using Crystal's `OptionParser` (very similar to Ruby)
2. Shells out to the Ruby CLI: `bin/wiregram <language> <action> [args]`
3. Parses the JSON output and formats it for the user

This avoids reimplementing the parsers/transformers and lets Crystal adopt immediately.

## Crystal Example: `src/cli/runner.cr`

```crystal
require "option_parser"
require "json"
require "process"

module WireGram
  module CLI
    class Runner
      LANGUAGES = ["expression", "json", "ucl"]
      RUBY_CLI = Path["bin/wiregram"].expand

      def self.start(args : Array(String))
        new.run(args)
      end

      def initialize
        @format = "text"
      end

      def run(args : Array(String))
        command = args.shift?

        case command
        when nil, "help", "--help", "-h"
          print_help
        when "list"
          list_languages
        when "server"
          start_server(args)
        when "snapshot"
          handle_snapshot(args)
        else
          # Treat as language command
          if LANGUAGES.includes?(command)
            language = command
            action = args.shift? || "help"
            handle_language(language, action, args)
          else
            STDERR.puts "Unknown command: #{command}"
            print_help
            exit 1
          end
        end
      end

      private def print_help
        puts <<~HELP
          WireGram Crystal CLI

          Usage:
            wiregram list                            # list available languages
            wiregram <language> help                 # show help for language
            wiregram <language> inspect [--pretty]   # run full pipeline and show output
            wiregram <language> tokenize             # show tokens
            wiregram <language> parse                # show AST
            wiregram server [--port 4567]            # start JSON HTTP server
            wiregram snapshot --generate [--language <lang>]

          Global options:
            --format json|text    Output format (default: text)

          Examples:
            echo '{ "a":1 }' | wiregram json inspect --pretty
            wiregram list

          For language-specific options: wiregram <language> help
        HELP
      end

      private def list_languages
        puts "Available languages:"
        LANGUAGES.each { |l| puts "  - #{l}" }
      end

      private def handle_language(language : String, action : String, argv : Array(String))
        # Build command for Ruby CLI
        cmd = [RUBY_CLI.to_s, language, action] + argv
        
        # Capture output
        output = IO::Memory.new
        error = IO::Memory.new
        process = Process.new(cmd[0], cmd[1..], output: output, error: error)
        status = process.wait

        result_text = output.to_s
        error_text = error.to_s

        if status.success?
          # Streaming commands (tokenize/parse) may emit NDJSON (one JSON object per line).
          # Handle both single-document JSON (inspect) and NDJSON streaming.
          # Note: WireGram lexers have been optimized for large inputs (StringScanner, pre-compiled patterns, fast unescape) and streaming mode avoids keeping the entire token array in memory. Prefer streaming (`tokenize`/`parse`) plus line-by-line parsing in clients for lowest memory usage and latency.
          if result_text.lines.size > 1 && result_text.lines.all? { |l| l.strip.start_with?("{") || l.strip.start_with?("[") }
            # NDJSON: parse each line individually
            result_text.lines.each do |line|
              begin
                obj = JSON.parse(line)
                puts @format == "json" ? JSON.generate(obj) : JSON.pretty_generate(obj)
              rescue
                puts line
              end
            end
          elsif result_text.strip.start_with?('{') || result_text.strip.start_with?('[')
            if @format == "json"
              puts result_text
            else
              # Pretty-print the JSON in text form
              begin
                json = JSON.parse(result_text)
                pretty_print_json(json)
              rescue
                puts result_text
              end
            end
          else
            puts result_text
          end
        else
          STDERR.puts error_text
          exit status.exit_code
        end
      end

      private def handle_snapshot(args : Array(String))
        # Simple pass-through to Ruby CLI
        Process.run(RUBY_CLI, ["snapshot"] + args)
      end

      private def start_server(args : Array(String))
        # Shell out to Ruby server
        Process.run(RUBY_CLI, ["server"] + args)
      end

      private def pretty_print_json(json : JSON::Any, indent : Int32 = 0)
        case json
        when JSON::Any::Type::Object
          json.as_h.each do |k, v|
            puts "#{"  " * indent}#{k}:"
            pretty_print_json(v, indent + 1)
          end
        when JSON::Any::Type::Array
          json.as_a.each do |item|
            pretty_print_json(item, indent)
          end
        else
          puts "#{"  " * indent}#{json}"
        end
      end
    end
  end
end

WireGram::CLI::Runner.start(ARGV)
```

## Build & Run

```bash
# Create Crystal project
crystal new wiregram_cli --lib

# Copy the runner.cr into src/

# Build
crystal build src/wiregram_cli.cr -o bin/wiregram_crystal

# Run
echo '{"a":1}' | ./bin/wiregram_crystal json inspect --pretty
```

## Advantages

✅ Minimal porting effort (< 200 lines)
✅ No parser reimplementation  
✅ Immediate feature parity with Ruby
✅ Easy to maintain (just CLI/UX layer)
✅ Can run on systems with both Ruby and Crystal

## Disadvantages

❌ Depends on Ruby/bin/wiregram being installed  
❌ Subprocess overhead for each call  
❌ Not suitable for high-throughput scenarios

## Next Phase: Server Mode (Optional)

Once the CLI wrapper is working, you can transition to server mode:

```crystal
require "http/client"

client = HTTP::Client.new("localhost", 4567)

response = client.post(
  "/v1/process",
  headers: HTTP::Headers{"Content-Type" => "application/json"},
  body: {
    language: "json",
    input: %{{"a":1}},
    pretty: true
  }.to_json
)

puts response.body
```

This eliminates subprocess overhead and is suitable for production use.

## Migration Path

1. **Phase 1 (Now)**: Shell-out CLI wrapper in Crystal. Fast adoption. ✅
2. **Phase 2 (Later)**: HTTP client library that talks to `wiregram server`. Production-ready. 
3. **Phase 3 (Optional)**: Native Crystal ports of specific language parsers if needed.

---

## Kotlin Port (Similar approach)

The Kotlin approach follows the same pattern:

1. Use `java.lang.ProcessBuilder` to shell out to `bin/wiregram`
2. Parse JSON output using Jackson or kotlinx.serialization
3. Build a thin CLI wrapper with `picocli` or `kotlinx-cli`

Example Kotlin snippet:

```kotlin
val process = ProcessBuilder("bin/wiregram", "json", "inspect")
  .redirectInput(ProcessBuilder.Redirect.PIPE)
  .redirectOutput(ProcessBuilder.Redirect.PIPE)
  .start()

process.outputStream.write(input.toByteArray())
process.outputStream.close()

val output = process.inputStream.bufferedReader().readText()
val json = objectMapper.readValue(output, Map::class.java)
println(json)
```

---

## Recommendations

For **Crystal**:
- Start with shell-out wrapper (this guide)
- Move to HTTP client library when throughput matters
- Optional: port specific parsers if they're hot paths

For **Kotlin**:
- Same approach as Crystal: shell-out + JSON parsing
- Ideal for JVM ecosystem where you may already have HTTP libraries available
- Can eventually embed Ruby via JRuby for native performance if needed

Rate: **9/10** for both approaches. Simple, effective, and maintainable.
