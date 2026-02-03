require "option_parser"
require "file_utils"
require "json"
require "../parallel/cpu_detector"
require "../parallel/file_processor"
require "./benchmark_json"

module Warp::CLI
  enum TranspileTarget
    Crystal
    Ruby
    Rbs
    Rbi
    InjectRbs
    RoundTrip
  end

  enum DumpFormat
    Pretty
    Json
  end

  enum DumpLanguage
    Json
    Ruby
    Crystal
  end

  class Runner
    def self.run(args : Array(String)) : Int32
      return run_init(args[1..]) if args.first? == "init"
      return run_transpile(args[1..]) if args.first? == "transpile"
      return run_dump(args[1..]) if args.first? == "dump"
      return run_detect(args[1..]) if args.first? == "detect"
      return BenchmarkJson.run(args[1..]) if args.first? == "bench-json"
      if args.first? == "version" || args.first? == "-v" || args.first? == "--version"
        puts Warp.version_string
        return 0
      end
      if args.first? == "help" || args.first? == "-h" || args.first? == "--help"
        puts usage
        return 0
      end
      puts usage
      1
    end

    private def self.usage : String
      <<-TXT
Usage:
  warp init
  warp transpile [target] [options]
  warp dump <simd|tokens|tape|soa|cst|dom|ast|full> [options] <file>
  warp detect patterns [options] <file>
  warp bench-json [options]
  warp version

Targets:
  crystal       Ruby -> Crystal (default)
  ruby          Crystal -> Ruby
  rbs           Generate .rbs files from Sorbet sigs
  rbi           Generate .rbi files from Sorbet sigs
  inject-rbs    Inject inline # @rbs comments into Ruby source
  round-trip    Validate round-trip (Ruby <-> Crystal)

Commands:
  init          Create a default .warp.yaml configuration
  transpile     Transpile between Ruby and Crystal
  dump          Inspect pipeline stages for a file
  detect        Detect language-specific patterns
  bench-json    Generate structured JSON benchmarks
  version       Show version information
  help          Show this help message
TXT
    end

    private def self.dump_usage : String
      <<-TXT
Usage:
  warp dump <simd|tokens|tape|soa|cst|dom|ast|full> [options] <file>

Options:
  -l, --lang=LANG        Language: auto|json|jsonc|ruby|crystal (default: auto)
  -f, --format=FORMAT    Output format: pretty|json (default: pretty)
  --jsonc                Enable JSONC parsing (JSON only)
  --perf                 Report SIMD timing/throughput
  --backend=NAME         Backend override: scalar|sse2|avx|avx2|avx512|neon|armv6
  -h, --help             Show this help message

Examples:
  warp dump simd --lang json data.json
  warp dump tokens --lang auto spec/fixtures/cli/rb_simple.rb
  warp dump tape --lang ruby spec/fixtures/cli/rb_simple.rb
  warp dump soa --lang json data.json
  warp dump cst -l json -f json spec/fixtures/rcl_test.json
  warp dump dom -l json spec/fixtures/rcl_test.json
  warp dump ast spec/fixtures/rcl_test.json
  warp dump full spec/fixtures/cli/rb_simple.rb
TXT
    end

    private def self.dump_stage_usage(stage : String) : String
      <<-TXT
Usage:
  warp dump #{stage} [options] <file>

Options:
  -l, --lang=LANG        Language: auto|json|jsonc|ruby|crystal (default: auto)
  -f, --format=FORMAT    Output format: pretty|json (default: pretty)
  --jsonc                Enable JSONC parsing (JSON only)
  --perf                 Report SIMD timing/throughput
  --backend=NAME         Backend override: scalar|sse2|avx|avx2|avx512|neon|armv6
  -h, --help             Show this help message
TXT
    end

    private def self.transpile_usage : String
      <<-TXT
Usage:
  warp transpile [crystal|ruby|rbs|rbi|inject-rbs|round-trip] [options]

Options:
  -h, --help              Show this help message
  -s, --source=PATH       Source file or directory
  -c, --config=PATH       Config file (default .warp.yaml or warp.yaml)
  -o, --out=DIR           Output directory
  -f, --format=FORMAT     Inspect output format: pretty|json (default: pretty)
  --rbs=PATH              RBS file to load (repeatable)
  --rbi=PATH              RBI file to load (repeatable)
  --inline-rbs=BOOL       Parse inline # @rbs comments (default true)
  --generate-rbs=BOOL     Generate .rbs signature files (default false)
  --generate-rbi=BOOL     Generate .rbi annotation files (default false)
  --inspect               Show pipeline internals (source CST, target CST, transformations)
  --parallel=N            Use N parallel workers (default: CPU cores)
  --dry-run               Parse/validate without writing output files
  --stdout                Write output to stdout
  -v, --verbose           Print detailed system and worker information
  --backend=NAME          Backend override: scalar|sse2|avx|avx2|avx512|neon|armv6
TXT
    end

    private def self.run_init(args : Array(String)) : Int32
      config_path = ".warp.yaml"
      template = <<-YAML
# Warp Transpiler Configuration
version: 1.0

# Target languages and their configurations
targets:
  crystal:
    description: "Transpile Ruby (Sorbet) to Crystal"
    target_path: "ports/crystal/"
    include_files:
      - "src/**/*.rb"
      - "bin/*.rb"

  ruby:
    description: "Transpile Sorbet annotations to RBS"
    target_path: "ports/ruby/"
    include_files:
      - "src/**/*.rb"

# Global settings
settings:
  preserve_comments: true
  preserve_formatting: true
  preserve_whitespace: true
  minimal_changes: true

# Operational section (Legacy compatibility)
transpiler:
  include:
    - "**/*.rb"
    - "**/*.cr"
  exclude:
    - "spec/**"
    - "vendor/**"

output:
  directory: "ports"
  crystal_directory: "ports/crystal"
  ruby_directory: "ports/ruby"
  generate_rbs: true
  generate_rbi: false
  folder_mappings:
    "src/": "lib/"
    "bin/": "exe/"

annotations:
  rbs_paths: []
  rbi_paths: []
  inline_rbs: true
YAML
      if File.exists?(config_path)
        puts "Config already exists: #{config_path}"
        return 1
      end
      File.write(config_path, template)
      puts "Created #{config_path}"
      0
    end

    private def self.run_transpile(args : Array(String)) : Int32
      args = args || [] of String
      target_name = "crystal"
      if args.size > 0 && !args[0].starts_with?("-")
        target_name = args[0]
        args = args[1..]
      end

      target = case target_name
               when "crystal", "cr"    then TranspileTarget::Crystal
               when "ruby", "rb"       then TranspileTarget::Ruby
               when "rbs"              then TranspileTarget::Rbs
               when "rbi"              then TranspileTarget::Rbi
               when "inject-rbs"       then TranspileTarget::InjectRbs
               when "round-trip", "rt" then TranspileTarget::RoundTrip
               else
                 puts "Unknown transpile target: #{target_name}"
                 puts transpile_usage
                 return 1
               end

      source_path = "."
      config_path : String? = nil
      out_dir : String? = nil
      extra_rbs = [] of String
      extra_rbi = [] of String
      inline_rbs = true
      generate_rbs = false
      generate_rbi = false
      stdout = false
      parallel_workers : Int32? = nil
      verbose = false
      dry_run = false
      backend_override : String? = nil
      inspect = false
      inspect_format : String = "pretty"

      parser = OptionParser.new do |p|
        p.banner = transpile_usage
        p.on("-h", "--help", "Show this help message") { puts transpile_usage; exit 0 }
        p.on("-s PATH", "--source=PATH", "Source file or directory") { |v| source_path = v }
        p.on("-c PATH", "--config=PATH", "Config file (default .warp.yaml)") { |v| config_path = v }
        p.on("-o DIR", "--out=DIR", "Output directory") { |v| out_dir = v }
        p.on("-f FORMAT", "--format=FORMAT", "Inspect output format: pretty|json (default: pretty)") { |v| inspect_format = v }
        p.on("--rbs=PATH", "RBS file to load (repeatable)") { |v| extra_rbs << v }
        p.on("--rbi=PATH", "RBI file to load (repeatable)") { |v| extra_rbi << v }
        p.on("--inline-rbs=BOOL", "Parse inline # @rbs comments (default true)") { |v| inline_rbs = (v != "false") }
        p.on("--generate-rbs=BOOL", "Generate .rbs signature files (default false)") { |v| generate_rbs = (v != "false") }
        p.on("--generate-rbi=BOOL", "Generate .rbi annotation files (default false)") { |v| generate_rbi = (v != "false") }
        p.on("--inspect", "Show pipeline internals (source CST, target CST, transformations)") { inspect = true }
        p.on("--parallel=N", "Use N parallel workers (default: CPU cores)") do |v|
          parallel_workers = v.to_i? || Warp::Parallel::CPUDetector.cpu_count
        end
        p.on("--dry-run", "Parse/validate without writing output files") { dry_run = true }
        p.on("--stdout", "Write output to stdout") { stdout = true }
        p.on("-v", "--verbose", "Print detailed information about system and workers") { verbose = true }
        p.on("--backend=NAME", "Backend override: scalar|sse2|avx|avx2|avx512|neon|armv6") { |v| backend_override = v }
      end

      parsed_args = args || [] of String
      parser.parse(parsed_args)
      if backend_override
        return 1 unless apply_backend_override(backend_override.not_nil!)
      end
      if parsed_args.size > 0 && source_path == "."
        source_path = parsed_args[0]
      end

      config = ConfigLoader.load(config_path)
      transpiler_config = ConfigLoader.load_transpiler_config(config_path)

      # Announce which config file is being used (or if none found)
      used_config : String? = nil
      if config_path
        cp = config_path.not_nil!
        unless File.exists?(cp)
          puts "Config file specified (#{cp}) not found; will use .warp.yaml if present, otherwise defaults."
        else
          used_config = cp
        end
      end

      if used_config.nil?
        if File.exists?(".warp.yaml")
          used_config = ".warp.yaml"
        elsif File.exists?("warp.yaml")
          # Legacy config detected but we only support .warp.yaml
          puts "Found legacy config 'warp.yaml' but only '.warp.yaml' is supported. Rename it to '.warp.yaml' to use it."
        end
      end

      if used_config
        puts "Using config: #{used_config}"
      else
        puts "No config file found; using defaults"
      end

      output_root = (out_dir || config.output_dir).not_nil!
      rbs_output_root = config.rbs_output_dir
      rbi_output_root = config.rbi_output_dir

      if out_dir.nil?
        output_root = case target
                      when TranspileTarget::Ruby
                        config.ruby_output_dir
                      when TranspileTarget::Crystal
                        config.crystal_output_dir
                      when TranspileTarget::Rbs
                        config.rbs_output_dir
                      when TranspileTarget::Rbi
                        config.rbi_output_dir
                      else
                        config.output_dir
                      end
      else
        # When --out is provided, adjust RBS/RBI output dirs to be under --out/rbs and --out/rbi
        rbs_output_root = File.join(out_dir.not_nil!, "rbs")
        rbi_output_root = File.join(out_dir.not_nil!, "rbi")
      end

      files = collect_files(source_path, config, target)
      if files.empty?
        puts "No source files found."
        return 1
      end

      # Handle --inspect flag for single file debugging
      if inspect && files.size == 1
        inspect_transpilation_pipeline(files[0], target, config, transpiler_config)
        return 0
      end

      # Determine parallelism
      workers = if pw = parallel_workers
                  pw
                elsif files.size > 4
                  Warp::Parallel::CPUDetector.cpu_count
                else
                  1
                end
      workers = 1 if stdout # No parallel when using stdout

      # Show system info (always when verbose, or when using parallel)
      if verbose || workers > 1
        puts Warp::Parallel::CPUDetector.summary
        puts "Using #{workers} parallel worker#{'s' if workers != 1}"
        if verbose
          print_verbose_worker_info(workers)
        end
        puts
      end

      success_count = 0
      failure_count = 0
      output_files_total = 0

      if workers > 1
        # Parallel processing
        processor = Warp::Parallel::FileProcessor.new(workers)

        stats_chan = Channel(Tuple(Bool, Int32)).new(files.size)
        processor.process_files(files) do |path|
          ok, out_count = process_file(path, output_root, target, config, extra_rbs, extra_rbi, inline_rbs, generate_rbs, generate_rbi, stdout, rbs_output_root, rbi_output_root, dry_run, verbose, transpiler_config)
          stats_chan.send({ok, out_count})
        end

        files.size.times do
          ok, out_count = stats_chan.receive
          if ok
            success_count += 1
          else
            failure_count += 1
          end
          output_files_total += out_count
        end
      else
        # Sequential processing
        files.each_with_index do |path, i|
          ok, out_count = process_file(path, output_root, target, config, extra_rbs, extra_rbi, inline_rbs, generate_rbs, generate_rbi, stdout, rbs_output_root, rbi_output_root, dry_run, verbose, transpiler_config)
          if ok
            success_count += 1
          else
            failure_count += 1
          end
          output_files_total += out_count
        end
      end

      # Compute actual output files on disk (more accurate than internal counters)
      actual_output_files = 0
      if !dry_run && !stdout && output_root && File.exists?(output_root)
        actual_output_files = Dir.glob(File.join(output_root, "**", "*")).select { |p| File.file?(p) }.size
      end

      # Print summary
      puts
      puts "Summary:"
      puts "  Files processed: #{files.size}"
      puts "  Successful: #{success_count}"
      puts "  Failed: #{failure_count}"

      if actual_output_files != 0
        if actual_output_files != output_files_total
          puts "  Output files generated: #{actual_output_files} (reported: #{output_files_total})"
        else
          puts "  Output files generated: #{actual_output_files}"
        end
      else
        puts "  Output files generated: #{output_files_total}"
      end

      0

      0
    end

    private def self.run_dump(args : Array(String)) : Int32
      args = args || [] of String
      if args.empty? || args.first? == "-h" || args.first? == "--help" || args.first? == "help"
        puts dump_usage
        return 0
      end

      stage = args[0]
      stage = "full" if stage == "all"

      unless ["simd", "tokens", "tape", "soa", "cst", "dom", "ast", "full"].includes?(stage)
        puts "Unknown dump target: #{stage}"
        puts dump_usage
        return 1
      end

      run_dump_stage(stage, args[1..])
    end

    private def self.run_dump_stage(stage : String, args : Array(String)) : Int32
      lang_name = "auto"
      format_name = "pretty"
      jsonc = false
      perf = false
      backend_override : String? = nil

      parser = OptionParser.new do |p|
        p.banner = dump_stage_usage(stage)
        p.on("-l LANG", "--lang=LANG", "Language: auto|json|jsonc|ruby|crystal") { |v| lang_name = v }
        p.on("-f FORMAT", "--format=FORMAT", "Output format: pretty|json") { |v| format_name = v }
        p.on("--jsonc", "Enable JSONC parsing (JSON only)") { jsonc = true }
        p.on("--perf", "Report SIMD timing/throughput") { perf = true }
        p.on("--backend=NAME", "Backend override: scalar|sse2|avx|avx2|avx512|neon|armv6") { |v| backend_override = v }
        p.on("-h", "--help", "Show this help message") { puts dump_stage_usage(stage); exit 0 }
      end

      parser.parse(args)

      if backend_override
        return 1 unless apply_backend_override(backend_override.not_nil!)
      end

      if args.empty?
        puts "Missing file argument."
        puts dump_stage_usage(stage)
        return 1
      end

      if args.size > 1
        puts "Too many arguments. Expected a single file path."
        puts dump_stage_usage(stage)
        return 1
      end

      path = args[0]
      unless File.exists?(path) && File.file?(path)
        puts "File not found: #{path}"
        return 1
      end

      bytes = File.read(path).to_slice
      lang_tuple = resolve_dump_language(lang_name, path, bytes, jsonc)
      return 1 unless lang_tuple

      lang, jsonc_effective = lang_tuple
      format = parse_dump_format(format_name)
      unless format
        puts "Unknown format: #{format_name}"
        puts dump_stage_usage(stage)
        return 1
      end

      case stage
      when "simd"
        return dump_simd_stage(lang, bytes, format, path, perf)
      when "tokens"
        return dump_tokens_stage(lang, bytes, format, path, jsonc_effective)
      when "tape"
        return dump_tape_stage(lang, bytes, format, path, jsonc_effective)
      when "soa"
        return dump_soa_stage(lang, bytes, format, path, jsonc_effective)
      when "cst"
        return dump_cst_stage(lang, bytes, format, path, jsonc_effective)
      when "dom"
        return dump_dom_stage(lang, bytes, format, path, jsonc_effective)
      when "ast"
        return dump_ast_stage(lang, bytes, format, path, jsonc_effective)
      when "full"
        return dump_full_stage(lang, bytes, format, path, jsonc_effective, perf)
      else
        puts "Unknown dump target: #{stage}"
        return 1
      end
    end

    private def self.parse_dump_format(name : String) : DumpFormat?
      case name.downcase
      when "pretty" then DumpFormat::Pretty
      when "json"   then DumpFormat::Json
      else
        nil
      end
    end

    private def self.apply_backend_override(name : String) : Bool
      backend = Warp::Backend.select_by_name(name)
      unless backend
        puts "Unknown or unavailable backend: #{name}"
        return false
      end
      Warp::Backend.reset(backend)
      true
    end

    private def self.resolve_dump_language(lang_name : String, path : String, bytes : Bytes, jsonc : Bool) : Tuple(DumpLanguage, Bool)?
      name = lang_name.downcase
      case name
      when "auto"
        detected = detect_dump_language(path, bytes)
        return nil unless detected
        lang, jsonc_detected = detected
        return {lang, jsonc || jsonc_detected}
      when "json"
        return {DumpLanguage::Json, jsonc}
      when "jsonc"
        return {DumpLanguage::Json, true}
      when "ruby", "rb"
        if jsonc
          puts "--jsonc is only supported for JSON inputs."
          return nil
        end
        return {DumpLanguage::Ruby, false}
      when "crystal", "cr"
        if jsonc
          puts "--jsonc is only supported for JSON inputs."
          return nil
        end
        return {DumpLanguage::Crystal, false}
      else
        puts "Unknown language: #{lang_name}"
        return nil
      end
    end

    private def self.detect_dump_language(path : String, bytes : Bytes) : Tuple(DumpLanguage, Bool)?
      ext = File.extname(path).downcase
      case ext
      when ".json"  then return {DumpLanguage::Json, false}
      when ".jsonc" then return {DumpLanguage::Json, true}
      when ".rb"    then return {DumpLanguage::Ruby, false}
      when ".cr"    then return {DumpLanguage::Crystal, false}
      end

      first = first_nonspace_byte(bytes)
      if first == '{'.ord || first == '['.ord
        return {DumpLanguage::Json, false}
      end

      text = String.new(bytes)
      crystal_hints = ["macro ", "lib ", "struct ", "enum ", "fun ", "annotation "]
      if crystal_hints.any? { |hint| text.includes?(hint) }
        return {DumpLanguage::Crystal, false}
      end

      ruby_hints = ["def ", "class ", "module ", "end", "elsif ", "unless ", "yield "]
      if ruby_hints.any? { |hint| text.includes?(hint) }
        return {DumpLanguage::Ruby, false}
      end

      puts "Unable to auto-detect language. Use --lang to specify json|ruby|crystal."
      nil
    end

    private def self.first_nonspace_byte(bytes : Bytes) : UInt8?
      i = 0
      while i < bytes.size
        c = bytes[i]
        if c != ' '.ord && c != '\t'.ord && c != '\n'.ord && c != '\r'.ord
          return c
        end
        i += 1
      end
      nil
    end

    private def self.dump_simd_stage(lang : DumpLanguage, bytes : Bytes, format : DumpFormat, path : String, perf : Bool = false) : Int32
      start_time = Time.instant
      scan_result : Warp::Lang::Common::ScanResult = case lang
      when DumpLanguage::Json
        json_result = Warp::Lexer::EnhancedSimdScan.index(bytes)
        Warp::Lang::Common::ScanResult.new(json_result.buffer.backing || Array(UInt32).new, json_result.error, "json")
      when DumpLanguage::Ruby
        Warp::Lang::Ruby.simd_scan(bytes)
      when DumpLanguage::Crystal
        Warp::Lang::Crystal.simd_scan(bytes)
      else
        Warp::Lang::Common::ScanResult.new(Array(UInt32).new, Warp::Core::ErrorCode::Empty, "unknown")
      end

      unless scan_result.error.success?
        write_dump_error("simd", lang, format, "SIMD scan failed (#{scan_result.error}) for #{path}.")
        return 1
      end

      elapsed = perf ? (Time.instant - start_time) : Time::Span.zero
      elapsed_ms = elapsed.total_milliseconds
      mb = bytes.size / (1024.0 * 1024.0)
      mb_per_s = perf && elapsed.total_seconds > 0 ? mb / elapsed.total_seconds : 0.0

      indices = scan_result.indices

      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "SIMD structural indices (#{scan_result.language}, #{indices.size} found)"
        io.puts "index   offset   byte  char"
        if perf
          io.puts "elapsed_ms #{elapsed_ms.round(3)}  mb_per_s #{mb_per_s.round(3)}"
        end
        indices.each_with_index do |idx_u32, i|
          idx = idx_u32.to_i
          byte = idx < bytes.size ? bytes[idx] : 0_u8
          char = idx < bytes.size ? bytes[idx].chr : '?'
          io.puts "#{i.to_s.rjust(5)}  #{idx.to_s.rjust(6)}  #{byte.to_s.rjust(4)}  #{char.inspect}"
        end
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", "simd"
            json.field "language", dump_language_label(lang)
            json.field "count", indices.size
            if perf
              json.field "elapsed_ms", elapsed_ms
              json.field "mb_per_s", mb_per_s
            end
            json.field "indices" do
              json.array do
                indices.each_with_index do |idx_u32, i|
                  idx = idx_u32.to_i
                  byte = idx < bytes.size ? bytes[idx] : 0_u8
                  char = idx < bytes.size ? bytes[idx].chr : '?'
                  json.object do
                    json.field "index", i
                    json.field "offset", idx
                    json.field "byte", byte.to_i
                    json.field "char", char.to_s
                  end
                end
              end
            end
          end
        end
        STDOUT.puts
      end

      0
    end

    private def self.dump_tokens_stage(lang : DumpLanguage, bytes : Bytes, format : DumpFormat, path : String, jsonc : Bool) : Int32
      case lang
      when DumpLanguage::Json
        if jsonc
          tokens, error = Warp::Lexer::TokenScanner.scan(bytes, true)
          unless error.success?
            write_dump_error("tokens", lang, format, "Token scan failed (#{error}) for #{path}.")
            return 1
          end
          return dump_cst_token_list(tokens, bytes, format, "json", "tokens")
        else
          parser = Warp::Parser.new
          case format
          when DumpFormat::Pretty
            io = STDOUT
            io.puts "Tokens (json)"
            io.puts "index   kind        start  length  text"
            idx = 0
            err = parser.each_token(bytes) do |tok|
              text = slice_text(bytes, tok.start, tok.length)
              io.puts "#{idx.to_s.rjust(5)}  #{tok.type.to_s.ljust(10)}  #{tok.start.to_s.rjust(5)}  #{tok.length.to_s.rjust(6)}  #{text.inspect}"
              idx += 1
            end
            unless err.success?
              write_dump_error("tokens", lang, format, "Token scan failed (#{err}) for #{path}.")
              return 1
            end
          when DumpFormat::Json
            count = 0
            err = nil
            JSON.build(STDOUT) do |json|
              json.object do
                json.field "stage", "tokens"
                json.field "language", dump_language_label(lang)
                json.field "tokens" do
                  json.array do
                    err = parser.each_token(bytes) do |tok|
                      text = slice_text(bytes, tok.start, tok.length)
                      json.object do
                        json.field "index", count
                        json.field "kind", tok.type.to_s
                        json.field "start", tok.start
                        json.field "length", tok.length
                        json.field "text", text
                      end
                      count += 1
                    end
                  end
                end
                json.field "count", count
              end
            end
            STDOUT.puts
            if err && !err.not_nil!.success?
              write_dump_error("tokens", lang, format, "Token scan failed (#{err.not_nil!}) for #{path}.")
              return 1
            end
          end
        end
      when DumpLanguage::Ruby
        tokens, error, pos = Warp::Lang::Ruby::Lexer.scan(bytes)
        unless error.success?
          diag = Warp::Diagnostics.lex_error("lex error", bytes, pos, path)
          write_dump_error("tokens", lang, format, diag.to_s)
          return 1
        end
        return dump_ruby_token_list(tokens, bytes, format, "ruby", "tokens")
      when DumpLanguage::Crystal
        tokens, error, pos = Warp::Lang::Crystal::Lexer.scan(bytes)
        unless error.success?
          diag = Warp::Diagnostics.lex_error("lex error", bytes, pos, path)
          write_dump_error("tokens", lang, format, diag.to_s)
          return 1
        end
        return dump_crystal_token_list(tokens, bytes, format, "crystal", "tokens")
      end

      0
    end

    private def self.dump_tape_stage(lang : DumpLanguage, bytes : Bytes, format : DumpFormat, path : String, jsonc : Bool) : Int32
      case lang
      when DumpLanguage::Json
        parser = Warp::Parser.new
        result = parser.parse_document(bytes, validate_literals: true, validate_numbers: true, jsonc: jsonc)
        unless result.error.success?
          write_dump_error("tape", lang, format, "Tape parse failed (#{result.error}) for #{path}.")
          return 1
        end
        doc = result.doc.not_nil!
        return dump_json_tape(doc, bytes, format)
      when DumpLanguage::Ruby
        tokens, error, pos = Warp::Lang::Ruby::Lexer.scan(bytes)
        unless error.success?
          diag = Warp::Diagnostics.lex_error("lex error", bytes, pos, path)
          write_dump_error("tape", lang, format, diag.to_s)
          return 1
        end
        root, parse_error = Warp::Lang::Ruby::CST::Parser.parse(bytes, tokens)
        unless parse_error.success? && root
          write_dump_error("tape", lang, format, "Ruby CST parse failed (#{parse_error}) for #{path}.")
          return 1
        end
        red = Warp::Lang::Ruby::CST::RedNode.new(root.not_nil!)
        tape = Warp::Lang::Ruby::Tape::Builder.build(bytes, red)
        return dump_ruby_tape(tape, bytes, format)
      when DumpLanguage::Crystal
        write_dump_error("tape", lang, format, "Tape is not implemented for Crystal yet.")
        return 1
      end

      0
    end

    private def self.dump_soa_stage(lang : DumpLanguage, bytes : Bytes, format : DumpFormat, path : String, jsonc : Bool) : Int32
      case lang
      when DumpLanguage::Json
        parser = Warp::Parser.new
        result = parser.parse_document(bytes, validate_literals: true, validate_numbers: true, jsonc: jsonc)
        unless result.error.success?
          write_dump_error("soa", lang, format, "SoA parse failed (#{result.error}) for #{path}.")
          return 1
        end
        doc = result.doc.not_nil!
        return dump_json_soa(doc, format)
      when DumpLanguage::Ruby
        write_dump_error("soa", lang, format, "SoA is not implemented for Ruby yet.")
        return 0
      when DumpLanguage::Crystal
        write_dump_error("soa", lang, format, "SoA is not implemented for Crystal yet.")
        return 0
      end

      0
    end

    private def self.dump_dom_stage(lang : DumpLanguage, bytes : Bytes, format : DumpFormat, path : String, jsonc : Bool) : Int32
      case lang
      when DumpLanguage::Json
        parser = Warp::Parser.new
        result = parser.parse_dom(bytes, jsonc: jsonc)
        unless result.error.success?
          write_dump_error("dom", lang, format, "DOM parse failed (#{result.error}) for #{path}.")
          return 1
        end
        value = result.value
        unless value
          write_dump_error("dom", lang, format, "DOM parse returned nil for #{path}.")
          return 1
        end
        return dump_json_dom(value, format)
      when DumpLanguage::Ruby
        write_dump_error("dom", lang, format, "DOM is not implemented for Ruby yet.")
        return 0
      when DumpLanguage::Crystal
        write_dump_error("dom", lang, format, "DOM is not implemented for Crystal yet.")
        return 0
      end

      0
    end

    private def self.dump_cst_stage(lang : DumpLanguage, bytes : Bytes, format : DumpFormat, path : String, jsonc : Bool) : Int32
      case lang
      when DumpLanguage::Json
        parser = Warp::Parser.new
        result = parser.parse_cst(bytes, jsonc: jsonc)
        unless result.error.success?
          write_dump_error("cst", lang, format, "CST parse failed (#{result.error}) for #{path}.")
          return 1
        end
        doc = result.doc.not_nil!
        return dump_json_cst(doc, bytes, format)
      when DumpLanguage::Ruby
        tokens, error, pos = Warp::Lang::Ruby::Lexer.scan(bytes)
        unless error.success?
          diag = Warp::Diagnostics.lex_error("lex error", bytes, pos, path)
          write_dump_error("cst", lang, format, diag.to_s)
          return 1
        end
        root, parse_error = Warp::Lang::Ruby::CST::Parser.parse(bytes, tokens)
        unless parse_error.success? && root
          write_dump_error("cst", lang, format, "Ruby CST parse failed (#{parse_error}) for #{path}.")
          return 1
        end
        red = Warp::Lang::Ruby::CST::RedNode.new(root.not_nil!)
        return dump_ruby_cst(red, bytes, format)
      when DumpLanguage::Crystal
        tokens, error, pos = Warp::Lang::Crystal::Lexer.scan(bytes)
        unless error.success?
          diag = Warp::Diagnostics.lex_error("lex error", bytes, pos, path)
          write_dump_error("cst", lang, format, diag.to_s)
          return 1
        end
        root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(bytes, tokens)
        unless parse_error.success? && root
          write_dump_error("cst", lang, format, "Crystal CST parse failed (#{parse_error}) for #{path}.")
          return 1
        end
        doc = Warp::Lang::Crystal::CST::Document.new(bytes, Warp::Lang::Crystal::CST::RedNode.new(root.not_nil!))
        return dump_crystal_cst(doc, bytes, format)
      end

      0
    end

    private def self.dump_ast_stage(lang : DumpLanguage, bytes : Bytes, format : DumpFormat, path : String, jsonc : Bool) : Int32
      case lang
      when DumpLanguage::Json
        parser = Warp::Parser.new
        result = parser.parse_ast(bytes, jsonc: jsonc)
        unless result.error.success?
          write_dump_error("ast", lang, format, "AST parse failed (#{result.error}) for #{path}.")
          return 1
        end
        node = result.node.not_nil!
        return dump_json_ast(node, format)
      when DumpLanguage::Ruby
        result = Warp::Lang::Ruby::Parser.parse(bytes)
        unless result.error.success? && result.node
          write_dump_error("ast", lang, format, "Ruby AST parse failed (#{result.error}) for #{path}.")
          return 1
        end
        return dump_ruby_ast(result.node.not_nil!, format)
      when DumpLanguage::Crystal
        write_dump_error("ast", lang, format, "AST is not implemented for Crystal yet.")
        return 1
      end

      0
    end

    private def self.dump_full_stage(lang : DumpLanguage, bytes : Bytes, format : DumpFormat, path : String, jsonc : Bool, perf : Bool) : Int32
      case format
      when DumpFormat::Pretty
        io = STDOUT
        dump_full_stage_pretty(io, lang, bytes, path, jsonc, perf)
      when DumpFormat::Json
        dump_full_stage_json(lang, bytes, path, jsonc, perf)
      end

      0
    end

    private def self.dump_full_stage_pretty(io : IO, lang : DumpLanguage, bytes : Bytes, path : String, jsonc : Bool, perf : Bool)
      io.puts "Full dump (#{dump_language_label(lang)})"

      io.puts "\n== simd =="
      dump_simd_stage(lang, bytes, DumpFormat::Pretty, path, perf)

      io.puts "\n== tokens =="
      dump_tokens_stage(lang, bytes, DumpFormat::Pretty, path, jsonc)

      io.puts "\n== tape =="
      dump_tape_stage(lang, bytes, DumpFormat::Pretty, path, jsonc)

      io.puts "\n== soa =="
      dump_soa_stage(lang, bytes, DumpFormat::Pretty, path, jsonc)

      io.puts "\n== cst =="
      dump_cst_stage(lang, bytes, DumpFormat::Pretty, path, jsonc)

      io.puts "\n== dom =="
      dump_dom_stage(lang, bytes, DumpFormat::Pretty, path, jsonc)

      io.puts "\n== ast =="
      dump_ast_stage(lang, bytes, DumpFormat::Pretty, path, jsonc)
    end

    private def self.dump_full_stage_json(lang : DumpLanguage, bytes : Bytes, path : String, jsonc : Bool, perf : Bool)
      JSON.build(STDOUT) do |json|
        json.object do
          json.field "language", dump_language_label(lang)
          json.field "stages" do
            json.object do
              json.field "simd" do
                write_json_simd_all_langs(json, lang, bytes, path, perf)
              end
              json.field "tokens" do
                write_json_tokens(json, lang, bytes, jsonc, path)
              end
              json.field "tape" do
                write_json_tape(json, lang, bytes, jsonc, path)
              end
              json.field "soa" do
                write_json_soa(json, lang, bytes, jsonc, path)
              end
              json.field "cst" do
                write_json_cst(json, lang, bytes, jsonc, path)
              end
              json.field "dom" do
                write_json_dom(json, lang, bytes, jsonc, path)
              end
              json.field "ast" do
                write_json_ast(json, lang, bytes, jsonc, path)
              end
            end
          end
        end
      end
      STDOUT.puts
    end

    private def self.dump_language_label(lang : DumpLanguage) : String
      case lang
      when DumpLanguage::Json    then "json"
      when DumpLanguage::Ruby    then "ruby"
      when DumpLanguage::Crystal then "crystal"
      else                            "unknown"
      end
    end

    private def self.write_dump_error(stage : String, lang : DumpLanguage, format : DumpFormat, message : String)
      if format == DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", stage
            json.field "language", dump_language_label(lang)
            json.field "error", message
          end
        end
        STDOUT.puts
      else
        # Write "not implemented" messages to stdout so they appear in full dumps
        # Write actual errors to stderr for standalone stage dumps
        if message.includes?("is not implemented")
          STDOUT.puts message
        else
          STDERR.puts message
        end
      end
    end

    private def self.slice_text(bytes : Bytes, start : Int32, length : Int32) : String
      return "" if start < 0 || length <= 0 || start >= bytes.size
      max_len = Math.min(length, bytes.size - start)
      String.new(bytes[start, max_len])
    end

    private def self.dump_cst_token_list(tokens : Array(Warp::CST::Token), bytes : Bytes, format : DumpFormat, lang_label : String, stage : String) : Int32
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "Tokens (#{lang_label})"
        io.puts "index   kind            start  length  text"
        tokens.each_with_index do |tok, idx|
          text = slice_text(bytes, tok.start, tok.length)
          io.puts "#{idx.to_s.rjust(5)}  #{tok.kind.to_s.ljust(14)}  #{tok.start.to_s.rjust(5)}  #{tok.length.to_s.rjust(6)}  #{text.inspect}"
        end
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", stage
            json.field "language", lang_label
            json.field "tokens" do
              json.array do
                tokens.each_with_index do |tok, idx|
                  text = slice_text(bytes, tok.start, tok.length)
                  json.object do
                    json.field "index", idx
                    json.field "kind", tok.kind.to_s
                    json.field "start", tok.start
                    json.field "length", tok.length
                    json.field "text", text
                  end
                end
              end
            end
            json.field "count", tokens.size
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.dump_ruby_token_list(tokens : Array(Warp::Lang::Ruby::Token), bytes : Bytes, format : DumpFormat, lang_label : String, stage : String) : Int32
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "Tokens (#{lang_label})"
        io.puts "index   kind            start  length  text"
        tokens.each_with_index do |tok, idx|
          text = slice_text(bytes, tok.start, tok.length)
          io.puts "#{idx.to_s.rjust(5)}  #{tok.kind.to_s.ljust(14)}  #{tok.start.to_s.rjust(5)}  #{tok.length.to_s.rjust(6)}  #{text.inspect}"
        end
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", stage
            json.field "language", lang_label
            json.field "tokens" do
              json.array do
                tokens.each_with_index do |tok, idx|
                  text = slice_text(bytes, tok.start, tok.length)
                  json.object do
                    json.field "index", idx
                    json.field "kind", tok.kind.to_s
                    json.field "start", tok.start
                    json.field "length", tok.length
                    json.field "text", text
                  end
                end
              end
            end
            json.field "count", tokens.size
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.dump_crystal_token_list(tokens : Array(Warp::Lang::Crystal::Token), bytes : Bytes, format : DumpFormat, lang_label : String, stage : String) : Int32
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "Tokens (#{lang_label})"
        io.puts "index   kind            start  length  text"
        tokens.each_with_index do |tok, idx|
          text = slice_text(bytes, tok.start, tok.length)
          io.puts "#{idx.to_s.rjust(5)}  #{tok.kind.to_s.ljust(14)}  #{tok.start.to_s.rjust(5)}  #{tok.length.to_s.rjust(6)}  #{text.inspect}"
        end
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", stage
            json.field "language", lang_label
            json.field "tokens" do
              json.array do
                tokens.each_with_index do |tok, idx|
                  text = slice_text(bytes, tok.start, tok.length)
                  json.object do
                    json.field "index", idx
                    json.field "kind", tok.kind.to_s
                    json.field "start", tok.start
                    json.field "length", tok.length
                    json.field "text", text
                  end
                end
              end
            end
            json.field "count", tokens.size
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.dump_json_tape(doc : Warp::IR::Document, bytes : Bytes, format : DumpFormat) : Int32
      tape = doc.tape
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "Tape (json)"
        io.puts "index   type         a       b       text"
        tape.each_with_index do |entry, idx|
          text = json_tape_text(bytes, entry)
          io.puts "#{idx.to_s.rjust(5)}  #{entry.type.to_s.ljust(10)}  #{entry.a.to_s.rjust(5)}  #{entry.b.to_s.rjust(5)}  #{text.inspect}"
        end
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", "tape"
            json.field "language", "json"
            json.field "entries" do
              json.array do
                tape.each_with_index do |entry, idx|
                  text = json_tape_text(bytes, entry)
                  json.object do
                    json.field "index", idx
                    json.field "type", entry.type.to_s
                    json.field "a", entry.a
                    json.field "b", entry.b
                    json.field "text", text
                  end
                end
              end
            end
            json.field "count", tape.size
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.json_tape_text(bytes : Bytes, entry : Warp::IR::Entry) : String
      case entry.type
      when Warp::IR::TapeType::Key, Warp::IR::TapeType::String, Warp::IR::TapeType::Number,
           Warp::IR::TapeType::True, Warp::IR::TapeType::False, Warp::IR::TapeType::Null
        slice_text(bytes, entry.a, entry.b)
      else
        ""
      end
    end

    private def self.dump_json_soa(doc : Warp::IR::Document, format : DumpFormat) : Int32
      soa = doc.soa_view
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "SoA (json)"
        io.puts "index   type         a       b"
        soa.types.each_with_index do |type, idx|
          io.puts "#{idx.to_s.rjust(5)}  #{type.to_s.ljust(10)}  #{soa.a[idx].to_s.rjust(5)}  #{soa.b[idx].to_s.rjust(5)}"
        end
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", "soa"
            json.field "language", "json"
            json.field "entries" do
              json.array do
                soa.types.each_with_index do |type, idx|
                  json.object do
                    json.field "index", idx
                    json.field "type", type.to_s
                    json.field "a", soa.a[idx]
                    json.field "b", soa.b[idx]
                  end
                end
              end
            end
            json.field "count", soa.types.size
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.dump_json_dom(value : Warp::DOM::Value, format : DumpFormat) : Int32
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "DOM (json)"
        io.puts format_json_dom_pretty(value, 0)
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", "dom"
            json.field "language", "json"
            json.field "value" do
              write_dom_value_json(json, value)
            end
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.format_json_dom_pretty(value : Warp::DOM::Value, indent : Int32) : String
      indent_str = "  " * indent
      case value
      when Nil
        "nil"
      when Bool
        value ? "true" : "false"
      when Int64
        value.to_s
      when Float64
        value.to_s
      when String
        value.inspect
      when Array
        if value.empty?
          "[]"
        else
          items = value.map { |v| format_json_dom_pretty(v, indent + 1) }
          "[\n#{items.map { |item| "#{indent_str}  #{item}" }.join(",\n")}\n#{indent_str}]"
        end
      when Hash
        if value.empty?
          "{}"
        else
          items = value.map { |k, v| "#{k.inspect}: #{format_json_dom_pretty(v, indent + 1)}" }
          "{\n#{items.map { |item| "#{indent_str}  #{item}" }.join(",\n")}\n#{indent_str}}"
        end
      else
        value.to_s
      end
    end

    private def self.write_dom_value_json(json : JSON::Builder, value : Warp::DOM::Value) : Nil
      case value
      when Nil
        json.null
      when Bool
        json.bool(value)
      when Int64
        json.number(value)
      when Float64
        json.number(value)
      when String
        json.string(value)
      when Array
        json.array do
          value.each { |v| write_dom_value_json(json, v) }
        end
      when Hash
        json.object do
          value.each do |k, v|
            json.field(k) { write_dom_value_json(json, v) }
          end
        end
      end
    end

    private def self.dump_ruby_tape(tape : Array(Warp::Lang::Ruby::Tape::Entry), bytes : Bytes, format : DumpFormat) : Int32
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "Tape (ruby)"
        io.puts "index   type         trivia  start   end     text"
        tape.each_with_index do |entry, idx|
          text = slice_text(bytes, entry.lexeme_start, entry.lexeme_end - entry.lexeme_start)
          io.puts "#{idx.to_s.rjust(5)}  #{entry.type.to_s.ljust(10)}  #{entry.trivia_start.to_s.rjust(6)}  #{entry.lexeme_start.to_s.rjust(6)}  #{entry.lexeme_end.to_s.rjust(6)}  #{text.inspect}"
        end
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", "tape"
            json.field "language", "ruby"
            json.field "entries" do
              json.array do
                tape.each_with_index do |entry, idx|
                  text = slice_text(bytes, entry.lexeme_start, entry.lexeme_end - entry.lexeme_start)
                  json.object do
                    json.field "index", idx
                    json.field "type", entry.type.to_s
                    json.field "trivia_start", entry.trivia_start
                    json.field "lexeme_start", entry.lexeme_start
                    json.field "lexeme_end", entry.lexeme_end
                    json.field "text", text
                  end
                end
              end
            end
            json.field "count", tape.size
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.dump_json_cst(doc : Warp::CST::Document, bytes : Bytes, format : DumpFormat) : Int32
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "CST (json)"
        write_json_cst_pretty(io, doc.root, bytes, 0)
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", "cst"
            json.field "language", "json"
            json.field "root" do
              write_json_cst_json(json, doc.root, bytes)
            end
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.dump_ruby_cst(root : Warp::Lang::Ruby::CST::RedNode, bytes : Bytes, format : DumpFormat) : Int32
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "CST (ruby)"
        write_ruby_cst_pretty(io, root, bytes, 0)
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", "cst"
            json.field "language", "ruby"
            json.field "root" do
              write_ruby_cst_json(json, root, bytes)
            end
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.dump_crystal_cst(doc : Warp::Lang::Crystal::CST::Document, bytes : Bytes, format : DumpFormat) : Int32
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "CST (crystal)"
        write_crystal_cst_pretty(io, doc.root, bytes, 0)
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", "cst"
            json.field "language", "crystal"
            json.field "root" do
              write_crystal_cst_json(json, doc.root, bytes)
            end
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.dump_json_ast(node : Warp::AST::Node, format : DumpFormat) : Int32
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "AST (json)"
        write_json_ast_pretty(io, node, 0)
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", "ast"
            json.field "language", "json"
            json.field "root" do
              write_json_ast_json(json, node)
            end
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.dump_ruby_ast(node : Warp::Lang::Ruby::AST::Node, format : DumpFormat) : Int32
      case format
      when DumpFormat::Pretty
        io = STDOUT
        io.puts "AST (ruby)"
        write_ruby_ast_pretty(io, node, 0)
      when DumpFormat::Json
        JSON.build(STDOUT) do |json|
          json.object do
            json.field "stage", "ast"
            json.field "language", "ruby"
            json.field "root" do
              write_ruby_ast_json(json, node)
            end
          end
        end
        STDOUT.puts
      end
      0
    end

    private def self.write_json_cst_pretty(io : IO, node : Warp::CST::RedNode, bytes : Bytes, depth : Int32)
      indent = "  " * depth
      token = node.token
      if token
        text = slice_text(bytes, token.start, token.length)
        io.puts "#{indent}- #{node.kind} [#{token.start}, #{token.length}] #{text.inspect}"
      else
        io.puts "#{indent}- #{node.kind}"
      end
      node.children.each do |child|
        write_json_cst_pretty(io, child, bytes, depth + 1)
      end
    end

    private def self.write_json_cst_json(json : JSON::Builder, node : Warp::CST::RedNode, bytes : Bytes)
      json.object do
        json.field "kind", node.kind.to_s
        if tok = node.token
          json.field "token" do
            json.object do
              json.field "kind", tok.kind.to_s
              json.field "start", tok.start
              json.field "length", tok.length
              json.field "text", slice_text(bytes, tok.start, tok.length)
            end
          end
        end
        json.field "leading_trivia" do
          json.array do
            node.leading_trivia.each do |tr|
              json.object do
                json.field "kind", tr.kind.to_s
                json.field "start", tr.start
                json.field "length", tr.length
                json.field "text", slice_text(bytes, tr.start, tr.length)
              end
            end
          end
        end
        json.field "children" do
          json.array do
            node.children.each do |child|
              write_json_cst_json(json, child, bytes)
            end
          end
        end
      end
    end

    private def self.write_ruby_cst_pretty(io : IO, node : Warp::Lang::Ruby::CST::RedNode, bytes : Bytes, depth : Int32)
      indent = "  " * depth
      token = node.token
      if token
        text = slice_text(bytes, token.start, token.length)
        io.puts "#{indent}- #{node.kind} [#{token.start}, #{token.length}] #{text.inspect}"
      else
        io.puts "#{indent}- #{node.kind}"
      end
      node.children.each do |child|
        write_ruby_cst_pretty(io, child, bytes, depth + 1)
      end
    end

    private def self.write_ruby_cst_json(json : JSON::Builder, node : Warp::Lang::Ruby::CST::RedNode, bytes : Bytes)
      json.object do
        json.field "kind", node.kind.to_s
        if tok = node.token
          json.field "token" do
            json.object do
              json.field "kind", tok.kind.to_s
              json.field "start", tok.start
              json.field "length", tok.length
              json.field "text", slice_text(bytes, tok.start, tok.length)
            end
          end
        end
        json.field "leading_trivia" do
          json.array do
            node.leading_trivia.each do |tr|
              json.object do
                json.field "kind", tr.kind.to_s
                json.field "start", tr.start
                json.field "length", tr.length
                json.field "text", slice_text(bytes, tr.start, tr.length)
              end
            end
          end
        end
        json.field "trailing_trivia" do
          json.array do
            node.trailing_trivia.each do |tr|
              json.object do
                json.field "kind", tr.kind.to_s
                json.field "start", tr.start
                json.field "length", tr.length
                json.field "text", slice_text(bytes, tr.start, tr.length)
              end
            end
          end
        end
        json.field "children" do
          json.array do
            node.children.each do |child|
              write_ruby_cst_json(json, child, bytes)
            end
          end
        end
      end
    end

    private def self.write_crystal_cst_pretty(io : IO, node : Warp::Lang::Crystal::CST::RedNode, bytes : Bytes, depth : Int32)
      indent = "  " * depth
      if text = node.text
        io.puts "#{indent}- #{node.kind} #{text.inspect}"
      else
        io.puts "#{indent}- #{node.kind}"
      end
      node.children.each do |child|
        write_crystal_cst_pretty(io, child, bytes, depth + 1)
      end
    end

    private def self.write_crystal_cst_json(json : JSON::Builder, node : Warp::Lang::Crystal::CST::RedNode, bytes : Bytes)
      json.object do
        json.field "kind", node.kind.to_s
        json.field "text", node.text
        json.field "leading_trivia" do
          json.array do
            node.leading_trivia.each do |tr|
              json.object do
                json.field "kind", tr.kind.to_s
                json.field "start", tr.start
                json.field "length", tr.length
                json.field "text", slice_text(bytes, tr.start, tr.length)
              end
            end
          end
        end
        json.field "trailing_trivia" do
          json.array do
            node.trailing_trivia.each do |tr|
              json.object do
                json.field "kind", tr.kind.to_s
                json.field "start", tr.start
                json.field "length", tr.length
                json.field "text", slice_text(bytes, tr.start, tr.length)
              end
            end
          end
        end
        if payload = node.method_payload
          json.field "method_payload" do
            json.object do
              json.field "name", payload.name
              json.field "return_type", payload.return_type
              json.field "had_parens", payload.had_parens
              json.field "body", payload.body
              json.field "params" do
                json.array do
                  payload.params.each do |param|
                    json.object do
                      json.field "name", param.name
                      json.field "type", param.type
                    end
                  end
                end
              end
            end
          end
        end
        json.field "children" do
          json.array do
            node.children.each do |child|
              write_crystal_cst_json(json, child, bytes)
            end
          end
        end
      end
    end

    private def self.write_json_ast_pretty(io : IO, node : Warp::AST::Node, depth : Int32)
      indent = "  " * depth
      if value = node.value
        io.puts "#{indent}- #{node.kind} #{value.inspect}"
      else
        io.puts "#{indent}- #{node.kind}"
      end
      node.children.each do |child|
        write_json_ast_pretty(io, child, depth + 1)
      end
    end

    private def self.write_json_ast_json(json : JSON::Builder, node : Warp::AST::Node)
      json.object do
        json.field "kind", node.kind.to_s
        json.field "value", node.value
        json.field "children" do
          json.array do
            node.children.each do |child|
              write_json_ast_json(json, child)
            end
          end
        end
      end
    end

    private def self.write_ruby_ast_pretty(io : IO, node : Warp::Lang::Ruby::AST::Node, depth : Int32)
      indent = "  " * depth
      io.puts "#{indent}- #{node.kind} [#{node.start}, #{node.length}] #{node.value.inspect}"
      node.children.each do |child|
        write_ruby_ast_pretty(io, child, depth + 1)
      end
    end

    private def self.write_ruby_ast_json(json : JSON::Builder, node : Warp::Lang::Ruby::AST::Node)
      json.object do
        json.field "kind", node.kind.to_s
        json.field "value", node.value
        json.field "start", node.start
        json.field "length", node.length
        json.field "meta", node.meta
        json.field "children" do
          json.array do
            node.children.each do |child|
              write_ruby_ast_json(json, child)
            end
          end
        end
      end
    end

    private def self.write_json_simd_all_langs(json : JSON::Builder, lang : DumpLanguage, bytes : Bytes, path : String, perf : Bool)
      start_time = Time.instant
      scan_result : Warp::Lang::Common::ScanResult = case lang
      when DumpLanguage::Json
        json_result = Warp::Lexer::EnhancedSimdScan.index(bytes)
        Warp::Lang::Common::ScanResult.new(json_result.buffer.backing || Array(UInt32).new, json_result.error, "json")
      when DumpLanguage::Ruby
        Warp::Lang::Ruby.simd_scan(bytes)
      when DumpLanguage::Crystal
        Warp::Lang::Crystal.simd_scan(bytes)
      else
        Warp::Lang::Common::ScanResult.new(Array(UInt32).new, Warp::Core::ErrorCode::Empty, "unknown")
      end

      elapsed = perf ? (Time.instant - start_time) : Time::Span.zero
      elapsed_ms = elapsed.total_milliseconds
      mb = bytes.size / (1024.0 * 1024.0)
      mb_per_s = perf && elapsed.total_seconds > 0 ? mb / elapsed.total_seconds : 0.0

      if scan_result.error.success?
        indices = scan_result.indices
        json.object do
          json.field "count", indices.size
          if perf
            json.field "elapsed_ms", elapsed_ms
            json.field "mb_per_s", mb_per_s
          end
          json.field "indices" do
            json.array do
              indices.each_with_index do |idx_u32, i|
                idx = idx_u32.to_i
                byte = idx < bytes.size ? bytes[idx] : 0_u8
                char = idx < bytes.size ? bytes[idx].chr : '?'
                json.object do
                  json.field "index", i
                  json.field "offset", idx
                  json.field "byte", byte.to_i
                  json.field "char", char.to_s
                end
              end
            end
          end
        end
      else
        write_json_error(json, "SIMD scan failed (#{scan_result.error}) for #{path}.")
      end
    end

    private def self.write_json_simd(json : JSON::Builder, bytes : Bytes)
      result = Warp::Lexer.index(bytes)
      if result.error.success?
        indices = result.buffer.backing || [] of UInt32
        json.object do
          json.field "count", indices.size
          json.field "indices" do
            json.array do
              indices.each_with_index do |idx_u32, i|
                idx = idx_u32.to_i
                byte = idx < bytes.size ? bytes[idx] : 0_u8
                char = idx < bytes.size ? bytes[idx].chr : '?'
                json.object do
                  json.field "index", i
                  json.field "offset", idx
                  json.field "byte", byte.to_i
                  json.field "char", char.to_s
                end
              end
            end
          end
        end
      else
        write_json_error(json, "SIMD scan failed (#{result.error}).")
      end
    end

    private def self.write_json_tokens(json : JSON::Builder, lang : DumpLanguage, bytes : Bytes, jsonc : Bool, path : String)
      case lang
      when DumpLanguage::Json
        if jsonc
          tokens, error = Warp::Lexer::TokenScanner.scan(bytes, true)
          unless error.success?
            write_json_error(json, "Token scan failed (#{error}) for #{path}.")
            return
          end
          json.object do
            json.field "count", tokens.size
            json.field "tokens" do
              json.array do
                tokens.each_with_index do |tok, idx|
                  json.object do
                    json.field "index", idx
                    json.field "kind", tok.kind.to_s
                    json.field "start", tok.start
                    json.field "length", tok.length
                    json.field "text", slice_text(bytes, tok.start, tok.length)
                  end
                end
              end
            end
          end
        else
          parser = Warp::Parser.new
          count = 0
          err = nil
          json.object do
            json.field "tokens" do
              json.array do
                err = parser.each_token(bytes) do |tok|
                  json.object do
                    json.field "index", count
                    json.field "kind", tok.type.to_s
                    json.field "start", tok.start
                    json.field "length", tok.length
                    json.field "text", slice_text(bytes, tok.start, tok.length)
                  end
                  count += 1
                end
              end
            end
            json.field "count", count
          end
          if err && !err.not_nil!.success?
            write_json_error(json, "Token scan failed (#{err.not_nil!}) for #{path}.")
          end
        end
      when DumpLanguage::Ruby
        tokens, error, pos = Warp::Lang::Ruby::Lexer.scan(bytes)
        unless error.success?
          diag = Warp::Diagnostics.lex_error("lex error", bytes, pos, path)
          write_json_error(json, diag.to_s)
          return
        end
        json.object do
          json.field "count", tokens.size
          json.field "tokens" do
            json.array do
              tokens.each_with_index do |tok, idx|
                json.object do
                  json.field "index", idx
                  json.field "kind", tok.kind.to_s
                  json.field "start", tok.start
                  json.field "length", tok.length
                  json.field "text", slice_text(bytes, tok.start, tok.length)
                  json.field "trivia" do
                    json.array do
                      tok.trivia.each do |tr|
                        json.object do
                          json.field "kind", tr.kind.to_s
                          json.field "start", tr.start
                          json.field "length", tr.length
                          json.field "text", slice_text(bytes, tr.start, tr.length)
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      when DumpLanguage::Crystal
        tokens, error, pos = Warp::Lang::Crystal::Lexer.scan(bytes)
        unless error.success?
          diag = Warp::Diagnostics.lex_error("lex error", bytes, pos, path)
          write_json_error(json, diag.to_s)
          return
        end
        json.object do
          json.field "count", tokens.size
          json.field "tokens" do
            json.array do
              tokens.each_with_index do |tok, idx|
                json.object do
                  json.field "index", idx
                  json.field "kind", tok.kind.to_s
                  json.field "start", tok.start
                  json.field "length", tok.length
                  json.field "text", slice_text(bytes, tok.start, tok.length)
                  json.field "trivia" do
                    json.array do
                      tok.trivia.each do |tr|
                        json.object do
                          json.field "kind", tr.kind.to_s
                          json.field "start", tr.start
                          json.field "length", tr.length
                          json.field "text", slice_text(bytes, tr.start, tr.length)
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    private def self.write_json_tape(json : JSON::Builder, lang : DumpLanguage, bytes : Bytes, jsonc : Bool, path : String)
      case lang
      when DumpLanguage::Json
        parser = Warp::Parser.new
        result = parser.parse_document(bytes, validate_literals: true, validate_numbers: true, jsonc: jsonc)
        unless result.error.success?
          write_json_error(json, "Tape parse failed (#{result.error}) for #{path}.")
          return
        end
        doc = result.doc.not_nil!
        json.object do
          json.field "count", doc.tape.size
          json.field "entries" do
            json.array do
              doc.tape.each_with_index do |entry, idx|
                json.object do
                  json.field "index", idx
                  json.field "type", entry.type.to_s
                  json.field "a", entry.a
                  json.field "b", entry.b
                  json.field "text", json_tape_text(bytes, entry)
                end
              end
            end
          end
        end
      when DumpLanguage::Ruby
        tokens, error, pos = Warp::Lang::Ruby::Lexer.scan(bytes)
        unless error.success?
          diag = Warp::Diagnostics.lex_error("lex error", bytes, pos, path)
          write_json_error(json, diag.to_s)
          return
        end
        root, parse_error = Warp::Lang::Ruby::CST::Parser.parse(bytes, tokens)
        unless parse_error.success? && root
          write_json_error(json, "Ruby CST parse failed (#{parse_error}) for #{path}.")
          return
        end
        red = Warp::Lang::Ruby::CST::RedNode.new(root.not_nil!)
        tape = Warp::Lang::Ruby::Tape::Builder.build(bytes, red)
        json.object do
          json.field "count", tape.size
          json.field "entries" do
            json.array do
              tape.each_with_index do |entry, idx|
                json.object do
                  json.field "index", idx
                  json.field "type", entry.type.to_s
                  json.field "trivia_start", entry.trivia_start
                  json.field "lexeme_start", entry.lexeme_start
                  json.field "lexeme_end", entry.lexeme_end
                  json.field "text", slice_text(bytes, entry.lexeme_start, entry.lexeme_end - entry.lexeme_start)
                end
              end
            end
          end
        end
      when DumpLanguage::Crystal
        write_json_error(json, "Tape is not implemented for Crystal yet.")
      end
    end

    private def self.write_json_soa(json : JSON::Builder, lang : DumpLanguage, bytes : Bytes, jsonc : Bool, path : String)
      case lang
      when DumpLanguage::Json
        parser = Warp::Parser.new
        result = parser.parse_document(bytes, validate_literals: true, validate_numbers: true, jsonc: jsonc)
        unless result.error.success?
          write_json_error(json, "SoA parse failed (#{result.error}) for #{path}.")
          return
        end
        doc = result.doc.not_nil!
        soa = doc.soa_view
        json.array do
          soa.types.each_with_index do |type, idx|
            json.object do
              json.field "index", idx
              json.field "type", type.to_s
              json.field "a", soa.a[idx]
              json.field "b", soa.b[idx]
            end
          end
        end
      when DumpLanguage::Ruby
        write_json_error(json, "SoA is not implemented for Ruby yet.")
      when DumpLanguage::Crystal
        write_json_error(json, "SoA is not implemented for Crystal yet.")
      end
    end

    private def self.write_json_dom(json : JSON::Builder, lang : DumpLanguage, bytes : Bytes, jsonc : Bool, path : String)
      case lang
      when DumpLanguage::Json
        parser = Warp::Parser.new
        result = parser.parse_dom(bytes, jsonc: jsonc)
        unless result.error.success?
          write_json_error(json, "DOM parse failed (#{result.error}) for #{path}.")
          return
        end
        value = result.value
        unless value
          write_json_error(json, "DOM parse returned nil for #{path}.")
          return
        end
        write_dom_value_json(json, value)
      when DumpLanguage::Ruby
        write_json_error(json, "DOM is not implemented for Ruby yet.")
      when DumpLanguage::Crystal
        write_json_error(json, "DOM is not implemented for Crystal yet.")
      end
    end

    private def self.write_json_cst(json : JSON::Builder, lang : DumpLanguage, bytes : Bytes, jsonc : Bool, path : String)
      case lang
      when DumpLanguage::Json
        parser = Warp::Parser.new
        result = parser.parse_cst(bytes, jsonc: jsonc)
        unless result.error.success?
          write_json_error(json, "CST parse failed (#{result.error}) for #{path}.")
          return
        end
        doc = result.doc.not_nil!
        write_json_cst_json(json, doc.root, bytes)
      when DumpLanguage::Ruby
        tokens, error, pos = Warp::Lang::Ruby::Lexer.scan(bytes)
        unless error.success?
          diag = Warp::Diagnostics.lex_error("lex error", bytes, pos, path)
          write_json_error(json, diag.to_s)
          return
        end
        root, parse_error = Warp::Lang::Ruby::CST::Parser.parse(bytes, tokens)
        unless parse_error.success? && root
          write_json_error(json, "Ruby CST parse failed (#{parse_error}) for #{path}.")
          return
        end
        write_ruby_cst_json(json, Warp::Lang::Ruby::CST::RedNode.new(root.not_nil!), bytes)
      when DumpLanguage::Crystal
        tokens, error, pos = Warp::Lang::Crystal::Lexer.scan(bytes)
        unless error.success?
          diag = Warp::Diagnostics.lex_error("lex error", bytes, pos, path)
          write_json_error(json, diag.to_s)
          return
        end
        root, parse_error = Warp::Lang::Crystal::CST::Parser.parse(bytes, tokens)
        unless parse_error.success? && root
          write_json_error(json, "Crystal CST parse failed (#{parse_error}) for #{path}.")
          return
        end
        doc = Warp::Lang::Crystal::CST::Document.new(bytes, Warp::Lang::Crystal::CST::RedNode.new(root.not_nil!))
        write_crystal_cst_json(json, doc.root, bytes)
      end
    end

    private def self.write_json_ast(json : JSON::Builder, lang : DumpLanguage, bytes : Bytes, jsonc : Bool, path : String)
      case lang
      when DumpLanguage::Json
        parser = Warp::Parser.new
        result = parser.parse_ast(bytes, jsonc: jsonc)
        unless result.error.success?
          write_json_error(json, "AST parse failed (#{result.error}) for #{path}.")
          return
        end
        write_json_ast_json(json, result.node.not_nil!)
      when DumpLanguage::Ruby
        result = Warp::Lang::Ruby::Parser.parse(bytes)
        unless result.error.success? && result.node
          write_json_error(json, "Ruby AST parse failed (#{result.error}) for #{path}.")
          return
        end
        write_ruby_ast_json(json, result.node.not_nil!)
      when DumpLanguage::Crystal
        write_json_error(json, "AST is not implemented for Crystal yet.")
      end
    end

    private def self.write_json_error(json : JSON::Builder, message : String)
      json.object do
        json.field "error", message
      end
    end

    private def self.collect_files(source_path : String, config : ProjectConfig, target : TranspileTarget) : Array(String)
      if File.file?(source_path)
        return [source_path]
      end

      # Prioritize target-specific includes/excludes from the new config format
      includes = case target
                 when TranspileTarget::Ruby    then config.ruby_include || config.include
                 when TranspileTarget::Crystal then config.crystal_include || config.include
                 when TranspileTarget::Rbs, TranspileTarget::Rbi, TranspileTarget::InjectRbs
                   config.ruby_include || config.include
                 else
                   config.include
                 end

      excludes = case target
                 when TranspileTarget::Ruby    then config.ruby_exclude || config.exclude
                 when TranspileTarget::Crystal then config.crystal_exclude || config.exclude
                 when TranspileTarget::Rbs, TranspileTarget::Rbi, TranspileTarget::InjectRbs
                   config.ruby_exclude || config.exclude
                 else
                   config.exclude
                 end

      exts = case target
             when TranspileTarget::Crystal, TranspileTarget::Rbs, TranspileTarget::Rbi, TranspileTarget::InjectRbs
               [".rb"]
             when TranspileTarget::Ruby
               [".cr"]
             else
               [".rb", ".cr"]
             end

      base_dir = File.directory?(source_path) ? source_path : nil
      files = includes.flat_map do |glob|
        if base_dir
          # If the include glob starts with a top-level segment that is an ancestor of the base dir
          # drop that leading segment and evaluate the glob relative to the base dir.
          first_segment = glob.split("/", 2)[0]
          base_segments = base_dir.split(File::SEPARATOR)
          if base_segments.includes?(first_segment)
            remainder = glob.split("/", 2)[1] || ""
            pattern = remainder.empty? ? base_dir : File.join(base_dir, remainder)
          else
            pattern = File.join(base_dir, glob)
          end
        else
          pattern = glob
        end
        Dir.glob(pattern)
      end
      files = files.select { |f| File.file?(f) && exts.any? { |ext| f.ends_with?(ext) } }
      files = files.reject { |f| excludes.any? { |ex| File.match?(ex, f) } }
      files.uniq

      # If no files matched the configured includes (common when includes are for the other language),
      # fall back to scanning the source directory for files with the target extensions.
      if files.empty? && base_dir
        files = exts.flat_map do |ext|
          Dir.glob(File.join(base_dir, "**/*#{ext}"))
        end.select { |f| File.file?(f) }
        files.uniq
      else
        files
      end
    end

    private def self.process_file(
      path : String,
      output_root : String,
      target : TranspileTarget,
      config : ProjectConfig,
      extra_rbs : Array(String),
      extra_rbi : Array(String),
      inline_rbs : Bool,
      generate_rbs : Bool,
      generate_rbi : Bool,
      stdout : Bool,
      rbs_output_root : String? = nil,
      rbi_output_root : String? = nil,
      dry_run : Bool = false,
      verbose : Bool = false,
      transpiler_config : Warp::Lang::Ruby::TranspilerConfig? = nil,
    ) : Tuple(Bool, Int32)
      source = File.read(path)
      bytes = source.to_slice

      # Use provided RBS/RBI output roots, or fall back to config
      rbs_output_dir = rbs_output_root || config.rbs_output_dir
      rbi_output_dir = rbi_output_root || config.rbi_output_dir
      case target
      when TranspileTarget::Ruby
        result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(bytes, path, transpiler_config)
        if result.error != Warp::Core::ErrorCode::Success
          puts "Transpile error (Crystal->Ruby): #{path}"
          result.diagnostics.each { |d| puts "  - #{d}" }

          if verbose && (tokens = result.tokens)
            puts "\nToken stream up to error:"
            tokens.each_with_index do |t, idx|
              txt = String.new(bytes[t.start, Math.min(t.length, bytes.size - t.start)])
              puts "  #{idx.to_s.rjust(3)}: #{t.kind} #{txt.inspect}"
            end
          end
          return {false, 0}
        end

        output_count = 0
        if dry_run
          # No output in dry-run mode
        elsif stdout
          puts result.output
        else
          write_or_print(path, output_root, result.output, ".rb", stdout, config.folder_mappings)
          output_count += 1

          # Generate accompanying RBS/RBI files if requested
          if (generate_rbs || config.generate_rbs) && !stdout && !dry_run
            ruby_bytes = result.output.to_slice
            tokens, lex_error, _ = Warp::Lang::Ruby::Lexer.scan(ruby_bytes)
            if lex_error == Warp::Core::ErrorCode::Success
              extractor = Warp::Lang::Ruby::Annotations::AnnotationExtractor.new(ruby_bytes, tokens)
              sigs = extractor.extract
              rbs_content = build_rbs(sigs)
              write_output(path, rbs_output_dir, rbs_content, ".rbs", config.folder_mappings)
              output_count += 1
            end
          end

          if (generate_rbi || config.generate_rbi) && !stdout && !dry_run
            ruby_bytes = result.output.to_slice
            tokens, lex_error, _ = Warp::Lang::Ruby::Lexer.scan(ruby_bytes)
            if lex_error == Warp::Core::ErrorCode::Success
              extractor = Warp::Lang::Ruby::Annotations::AnnotationExtractor.new(ruby_bytes, tokens)
              sigs = extractor.extract
              rbi_content = build_rbi(sigs)
              write_output(path, rbi_output_dir, rbi_content, ".rbi", config.folder_mappings)
              output_count += 1
            end
          end
        end
        return {true, output_count}
      when TranspileTarget::RoundTrip
        if path.ends_with?(".rb")
          result = Warp::Testing::BidirectionalValidator.ruby_to_crystal_to_ruby(source)
          print_with_progress_clear("Round-trip Ruby: #{path} (delta=#{result.formatting_delta})")
          result.diagnostics.each { |d| print_with_progress_clear("  - #{d}") }
        elsif path.ends_with?(".cr")
          result = Warp::Testing::BidirectionalValidator.crystal_to_ruby_to_crystal(source)
          print_with_progress_clear("Round-trip Crystal: #{path} (delta=#{result.formatting_delta})")
          result.diagnostics.each { |d| print_with_progress_clear("  - #{d}") }
        else
          print_with_progress_clear("Skipping unsupported file: #{path}")
        end
        return {true, 0}
      else
        tokens, lex_error, lex_pos = Warp::Lang::Ruby::Lexer.scan(bytes)
        if lex_error != Warp::Core::ErrorCode::Success
          diag = Warp::Diagnostics.lex_error("lex error", bytes, lex_pos, path)
          print_with_progress_clear(diag.to_s)

          if verbose
            puts "\nToken stream up to error:"
            tokens.each_with_index do |t, idx|
              txt = String.new(bytes[t.start, Math.min(t.length, bytes.size - t.start)])
              puts "  #{idx.to_s.rjust(3)}: #{t.kind} #{txt.inspect}"
            end
          end
          return {false, 0}
        end
      end

      case target
      when TranspileTarget::Rbs, TranspileTarget::Rbi, TranspileTarget::InjectRbs
        extractor = Warp::Lang::Ruby::Annotations::AnnotationExtractor.new(bytes, tokens)
        sigs = extractor.extract

        content = case target
                  when TranspileTarget::Rbs
                    build_rbs(sigs)
                  when TranspileTarget::Rbi
                    build_rbi(sigs)
                  else
                    Warp::Lang::Ruby::Annotations::InlineRbsInjector.inject(source, sigs)
                  end

        ext = target == TranspileTarget::Rbs ? ".rbs" : (target == TranspileTarget::Rbi ? ".rbi" : ".rb")
        if dry_run
          return {true, 0}
        else
          write_or_print(path, output_root, content, ext, stdout, config.folder_mappings)
          return {true, stdout ? 0 : 1}
        end
      else
        annotations = build_annotation_store(path, source, config, extra_rbs, extra_rbi, inline_rbs)
        result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(bytes, annotations, path)
        if result.error != Warp::Core::ErrorCode::Success
          print_with_progress_clear("Transpile error (Ruby->Crystal): #{path}")
          result.diagnostics.each { |d| print_with_progress_clear("  - #{d}") }

          if verbose && (toks = result.tokens)
            puts "\nToken stream up to error:"
            toks.each_with_index do |t, idx|
              txt = String.new(bytes[t.start, Math.min(t.length, bytes.size - t.start)])
              puts "  #{idx.to_s.rjust(3)}: #{t.kind} #{txt.inspect}"
            end
          end
          return {false, 0}
        end
        output_count = 0
        if dry_run
          # No output in dry-run mode
        elsif stdout
          puts result.output
        else
          out_path = output_path_for(path, output_root, ".cr", config.folder_mappings)
          if result.crystal_doc
            Warp::Lang::Crystal::Serializer.emit_to_file(result.crystal_doc.not_nil!, out_path)
            output_count += 1
          else
            write_output(path, output_root, result.output, ".cr", config.folder_mappings)
            output_count += 1
          end
        end
        return {true, output_count}
      end
    end

    private def self.output_path_for(source_path : String, output_root : String, ext : String, folder_mappings : Hash(String, String)? = nil) : String
      rel = source_path
      rel = rel.sub(%r{^\./}, "")

      # Apply folder mappings if provided
      if folder_mappings
        folder_mappings.each do |src_dir, dest_dir|
          if rel.starts_with?(src_dir)
            rel = dest_dir + rel[src_dir.size..-1]
            break
          end
        end
      end

      # Normalize common source extensions (.cr or .rb) to the requested output extension
      File.join(output_root, rel).sub(/\.(?:rb|cr)$/, ext)
    end

    private def self.write_or_print(source_path : String, output_root : String, content : String, ext : String, stdout : Bool, folder_mappings : Hash(String, String)? = nil)
      if stdout
        puts content
      else
        write_output(source_path, output_root, content, ext, folder_mappings)
      end
    end

    private def self.print_with_progress_clear(message : String)
      puts message
    end

    private def self.print_verbose_worker_info(worker_count : Int32)
      # Get core allocation for this worker count
      cores = Warp::Parallel::CPUDetector.allocate_workers_to_cores(worker_count)

      # Print detailed information about each worker with core assignment
      puts "Worker Allocation:"
      cores.each_with_index do |core, idx|
        worker_id = idx + 1
        puts "  Worker #{worker_id}: #{core}"
      end
      puts
      # Print SIMD capabilities
      puts "SIMD Capabilities:"
      simd_info = Warp::Parallel::CPUDetector.simd_capabilities
      simd_info.each do |capability, supported|
        status = supported ? "✓" : "✗"
        puts "  #{status} #{capability}"
      end
    end

    private def self.build_annotation_store(
      path : String,
      source : String,
      config : ProjectConfig,
      extra_rbs : Array(String),
      extra_rbi : Array(String),
      inline_rbs : Bool,
    ) : Warp::Lang::Ruby::Annotations::AnnotationStore
      store = Warp::Lang::Ruby::Annotations::AnnotationStore.new

      if inline_rbs
        inline_parser = Warp::Lang::Ruby::Annotations::InlineRbsParser.new
        inline_parser.parse(source).each do |name, sig|
          store.add_inline_rbs(name, sig)
        end
      end

      rbs_paths = [] of String
      rbi_paths = [] of String
      rbs_paths.concat(config.rbs_paths)
      rbi_paths.concat(config.rbi_paths)
      rbs_paths.concat(extra_rbs)
      rbi_paths.concat(extra_rbi)

      # Auto-detect sibling .rbs/.rbi files
      rbs_paths << path.sub(/\.rb$/, ".rbs") if File.exists?(path.sub(/\.rb$/, ".rbs"))
      rbi_paths << path.sub(/\.rb$/, ".rbi") if File.exists?(path.sub(/\.rb$/, ".rbi"))

      rbs_parser = Warp::Lang::Ruby::Annotations::RbsFileParser.new
      rbi_parser = Warp::Lang::Ruby::Annotations::RbiFileParser.new

      rbs_paths.uniq.each do |rbs_path|
        next unless File.exists?(rbs_path)
        rbs_parser.parse(File.read(rbs_path)).each do |name, sig|
          store.add_rbs(name, sig)
        end
      end

      rbi_paths.uniq.each do |rbi_path|
        next unless File.exists?(rbi_path)
        rbi_parser.parse(File.read(rbi_path)).each do |name, sig|
          store.add_rbi(name, sig)
        end
      end

      store
    end

    private def self.write_output(source_path : String, output_root : String, content : String, ext : String, folder_mappings : Hash(String, String)? = nil)
      out_path = output_path_for(source_path, output_root, ext, folder_mappings)
      FileUtils.mkdir_p(File.dirname(out_path))
      File.write(out_path, content)
    end

    private def self.build_rbs(sigs : Array(Warp::Lang::Ruby::Annotations::SigInfo)) : String
      lines = [] of String
      lines << "class Object"
      sigs.each do |sig|
        lines << "  #{Warp::Lang::Ruby::Annotations::RbsGenerator.rbs_definition(sig)}"
      end
      lines << "end"
      lines.join("\n") + "\n"
    end

    private def self.build_rbi(sigs : Array(Warp::Lang::Ruby::Annotations::SigInfo)) : String
      lines = [] of String
      lines << "# typed: true"
      lines << "class Object"
      sigs.each do |sig|
        sig_text = Warp::Lang::Ruby::Annotations::SorbetRbiGenerator.rbi_definition(sig)
        sig_text.lines.each do |ln|
          lines << "  #{ln}".rstrip
        end
      end
      lines << "end"
      lines.join("\n") + "\n"
    end

    private def self.run_detect(args : Array(String)) : Int32
      if args.empty?
        puts detect_usage
        return 1
      end

      pattern_type = args.first
      if pattern_type == "patterns"
        return detect_patterns(args[1..])
      else
        puts "Unknown detect command: #{pattern_type}"
        puts detect_usage
        return 1
      end
    end

    private def self.detect_usage : String
      <<-TXT
        Usage:
          warp detect patterns --lang <ruby|crystal> [options] <file>

        Options:
          --lang                 Language (ruby or crystal)
          --format               Output format (pretty or json) [default: pretty]
          --perf                 Show performance timing

        Examples:
          warp detect patterns --lang ruby script.rb
          warp detect patterns --lang crystal --format json code.cr
      TXT
    end

    private def self.detect_patterns(args : Array(String)) : Int32
      lang : String? = nil
      format = DumpFormat::Pretty
      perf = false
      path : String? = nil

      OptionParser.parse(args) do |p|
        p.on("--lang LANG", "Language (ruby or crystal)") { |l| lang = l }
        p.on("--format FORMAT", "Output format (pretty or json)") { |f| format = f == "json" ? DumpFormat::Json : DumpFormat::Pretty }
        p.on("--perf", "Show performance timing") { perf = true }
        p.on("-h", "--help") { puts detect_usage; exit 0 }
        p.unknown_args { |rest| path = rest.first? }
      end

      if lang.nil? || path.nil?
        puts "Error: --lang and file path required"
        puts detect_usage
        return 1
      end

      path_str = path.not_nil!
      unless File.exists?(path_str)
        puts "Error: File not found: #{path_str}"
        return 1
      end

      start_time = Time.instant if perf
      bytes = File.read(path_str).to_slice

      case lang.not_nil!.downcase
      when "ruby"
        patterns = Warp::Lang::Ruby.detect_all_patterns(bytes)
        output_patterns("ruby", patterns, format, perf, start_time)
      when "crystal"
        patterns = Warp::Lang::Crystal.detect_all_patterns(bytes)
        output_patterns("crystal", patterns, format, perf, start_time)
      else
        puts "Error: Unknown language '#{lang}'. Supported: ruby, crystal"
        return 1
      end

      0
    end

    private def self.output_patterns(lang : String, patterns : Hash(String, Array(UInt32)), format : DumpFormat, perf : Bool, start_time : Time::Instant?) : Nil
      elapsed_ms = 0.0
      if perf && start_time
        elapsed_ms = (Time.instant - start_time).total_milliseconds
      end

      if format == DumpFormat::Json
        result = {} of String => (String | Array(Int32) | Hash(String, Array(Int32)) | Float64)
        result["language"] = lang
        result["patterns"] = patterns.transform_values { |indices| indices.map(&.to_i) }
        result["elapsed_ms"] = elapsed_ms if perf
        puts result.to_json
      else
        puts "Language: #{lang}"
        patterns.each do |pattern_name, indices|
          first_ten = indices.first(10)
          rest_indicator = indices.size > 10 ? "..." : ""
          puts "  #{pattern_name}: #{indices.size} occurrences"
          puts "    Offsets: #{first_ten.inspect}#{rest_indicator}"
        end
        puts "  elapsed_ms: #{elapsed_ms.round(3)}" if perf
      end
    end

    private def self.inspect_transpilation_pipeline(file_path : String, target : TranspileTarget, config : ProjectConfig, transpiler_config : Warp::Lang::Ruby::TranspilerConfig? = nil) : Nil
      unless File.exists?(file_path) && File.file?(file_path)
        puts "Error: File not found: #{file_path}"
        return
      end

      bytes = File.read(file_path).to_slice
      target_name = case target
                    when TranspileTarget::Ruby
                      "Ruby"
                    when TranspileTarget::Crystal
                      "Crystal"
                    else
                      "Unknown"
                    end

      puts "=== Transpilation Pipeline Inspector ==="
      puts "File: #{file_path}"
      puts "Target: #{target_name}"
      puts

      case target
      when TranspileTarget::Ruby
        # Transpile Crystal -> Ruby
        puts "[INPUT: Crystal Source]"
        puts "Size: #{bytes.size} bytes"
        puts "Preview:"
        puts bytes.to_s[0...500]
        puts

        puts "[LEXING Crystal]"
        c_tokens, c_lex_error, _ = Warp::Lang::Crystal::Lexer.scan(bytes)
        if c_lex_error != Warp::Core::ErrorCode::Success
          puts "ERROR: Lexing failed (#{c_lex_error})"
          return
        end
        puts "✓ Lexing successful: #{c_tokens.size} tokens"
        puts

        puts "[PARSING Crystal CST]"
        c_cst, c_parse_error = Warp::Lang::Crystal::CST::Parser.parse(bytes, c_tokens)
        if c_parse_error != Warp::Core::ErrorCode::Success
          puts "ERROR: Parsing failed (#{c_parse_error})"
          return
        end
        puts "✓ Parsing successful"
        puts "  CST nodes: #{count_cst_nodes(c_cst)}"
        puts

        puts "[TRANSPILING Crystal -> Ruby]"
        result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(bytes, file_path, transpiler_config)
        if result.error != Warp::Core::ErrorCode::Success
          puts "ERROR: Transpilation failed (#{result.error})"
          return
        end
        puts "✓ Transpilation successful"
        puts "  Output size: #{result.output.size} bytes"
        puts

        puts "[OUTPUT: Ruby Source]"
        puts "Preview:"
        puts result.output[0...500]
      when TranspileTarget::Crystal
        # Transpile Ruby -> Crystal
        puts "[INPUT: Ruby Source]"
        puts "Size: #{bytes.size} bytes"
        puts "Preview:"
        puts bytes.to_s[0...500]
        puts

        puts "[LEXING Ruby]"
        r_tokens, r_lex_error, _ = Warp::Lang::Ruby::Lexer.scan(bytes)
        if r_lex_error != Warp::Core::ErrorCode::Success
          puts "ERROR: Lexing failed (#{r_lex_error})"
          return
        end
        puts "✓ Lexing successful: #{r_tokens.size} tokens"
        puts

        puts "[PARSING Ruby CST]"
        r_cst, r_parse_error = Warp::Lang::Ruby::CST::Parser.parse(bytes, r_tokens)
        if r_parse_error != Warp::Core::ErrorCode::Success
          puts "ERROR: Parsing failed (#{r_parse_error})"
          return
        end
        puts "✓ Parsing successful"
        puts

        puts "[SEMANTIC ANALYSIS]"
        annotations = Warp::Lang::Ruby::Annotations::AnnotationStore.new
        if r_cst
          analyzer = Warp::Lang::Ruby::SemanticAnalyzer.new(bytes, r_tokens, r_cst, annotations)
          context = analyzer.analyze
          puts "✓ Analysis complete"
          puts "  Diagnostics: #{context.diagnostics.size}"
        else
          puts "ERROR: No CST to analyze"
          return
        end
        puts

        puts "[BUILDING Crystal CST]"
        builder = Warp::Lang::Crystal::CSTBuilder.new
        crystal_doc = builder.build_from_context(context)
        puts "✓ Crystal CST built"
        puts

        puts "[EMITTING Crystal Source]"
        result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(bytes)
        if result.error != Warp::Core::ErrorCode::Success
          puts "ERROR: Transpilation failed (#{result.error})"
          return
        end
        puts "✓ Transpilation successful"
        puts "  Output size: #{result.output.size} bytes"
        puts

        puts "[OUTPUT: Crystal Source]"
        puts "Preview:"
        puts result.output[0...500]
      else
        puts "Inspect not supported for this target"
      end
    end

    private def self.count_cst_nodes(node : Warp::Lang::Crystal::CST::GreenNode) : Int32
      count = 1
      node.children.each { |child| count += count_cst_nodes(child) }
      count
    rescue
      1
    end
  end
end
