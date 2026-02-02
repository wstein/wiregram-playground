require "option_parser"
require "file_utils"
require "../parallel/cpu_detector"
require "../parallel/file_processor"

module Warp::CLI
  enum TranspileTarget
    Crystal
    Ruby
    Rbs
    Rbi
    InjectRbs
    RoundTrip
  end

  class Runner
    def self.run(args : Array(String)) : Int32
      return run_init(args[1..]) if args.first? == "init"
      return run_transpile(args[1..]) if args.first? == "transpile"
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
  version       Show version information
  help          Show this help message
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
  --rbs=PATH              RBS file to load (repeatable)
  --rbi=PATH              RBI file to load (repeatable)
  --inline-rbs=BOOL       Parse inline # @rbs comments (default true)
  --generate-rbs=BOOL     Generate .rbs signature files (default false)
  --generate-rbi=BOOL     Generate .rbi annotation files (default false)
  --parallel=N            Use N parallel workers (default: CPU cores)
  --stdout                Write output to stdout
  -v, --verbose           Print detailed system and worker information

Debugging Flags:
  --dump-tokens           Dump tokens to stdout
  --dump-cst              Dump Concrete Syntax Tree to stdout
  --dump-ast              Dump Abstract Syntax Tree to stdout
  --dump-tape             Dump Tape IR to stdout
  --dump-simd             Dump SIMD structural indices to stdout
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
      dump_tokens = false
      dump_cst = false
      dump_ast = false
      dump_tape = false
      dump_simd = false

      parser = OptionParser.new do |p|
        p.banner = transpile_usage
        p.on("-h", "--help", "Show this help message") { puts transpile_usage; exit 0 }
        p.on("-s PATH", "--source=PATH", "Source file or directory") { |v| source_path = v }
        p.on("-c PATH", "--config=PATH", "Config file (default .warp.yaml)") { |v| config_path = v }
        p.on("-o DIR", "--out=DIR", "Output directory") { |v| out_dir = v }
        p.on("--rbs=PATH", "RBS file to load (repeatable)") { |v| extra_rbs << v }
        p.on("--rbi=PATH", "RBI file to load (repeatable)") { |v| extra_rbi << v }
        p.on("--inline-rbs=BOOL", "Parse inline # @rbs comments (default true)") { |v| inline_rbs = (v != "false") }
        p.on("--generate-rbs=BOOL", "Generate .rbs signature files (default false)") { |v| generate_rbs = (v != "false") }
        p.on("--generate-rbi=BOOL", "Generate .rbi annotation files (default false)") { |v| generate_rbi = (v != "false") }
        p.on("--parallel=N", "Use N parallel workers (default: CPU cores)") do |v|
          parallel_workers = v.to_i? || Warp::Parallel::CPUDetector.cpu_count
        end
        p.on("--stdout", "Write output to stdout") { stdout = true }
        p.on("-v", "--verbose", "Print detailed information about system and workers") { verbose = true }
        p.on("--dump-tokens", "Dump tokens to stdout") { dump_tokens = true }
        p.on("--dump-cst", "Dump CST to stdout") { dump_cst = true }
        p.on("--dump-ast", "Dump AST to stdout") { dump_ast = true }
        p.on("--dump-tape", "Dump Tape IR to stdout") { dump_tape = true }
        p.on("--dump-simd", "Dump SIMD structural indices") { dump_simd = true }
      end

      parser.parse(args || [] of String)

      config = ConfigLoader.load(config_path)

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

      if workers > 1
        # Parallel processing
        processor = Warp::Parallel::FileProcessor.new(workers)

        processor.process_files(files) do |path|
          process_file(path, output_root, target, config, extra_rbs, extra_rbi, inline_rbs, generate_rbs, generate_rbi, stdout, rbs_output_root, rbi_output_root, dump_tokens, dump_cst, dump_ast, dump_tape, dump_simd, verbose)
        end
      else
        # Sequential processing
        files.each_with_index do |path, i|
          process_file(path, output_root, target, config, extra_rbs, extra_rbi, inline_rbs, generate_rbs, generate_rbi, stdout, rbs_output_root, rbi_output_root, dump_tokens, dump_cst, dump_ast, dump_tape, dump_simd, verbose)
        end
      end

      0
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
      dump_tokens : Bool = false,
      dump_cst : Bool = false,
      dump_ast : Bool = false,
      dump_tape : Bool = false,
      dump_simd : Bool = false,
      verbose : Bool = false,
    )
      source = File.read(path)
      bytes = source.to_slice

      if dump_tokens
        Warp::Lang::Ruby::Inspector.dump_tokens(bytes)
        return
      end

      if dump_cst
        Warp::Lang::Ruby::Inspector.dump_cst(bytes)
        return
      end

      if dump_ast
        Warp::Lang::Ruby::Inspector.dump_ast(bytes)
        return
      end

      if dump_tape
        Warp::Lang::Ruby::Inspector.dump_tape(bytes)
        return
      end

      if dump_simd
        Warp::Lang::Ruby::Inspector.dump_simd(bytes)
        return
      end

      # Use provided RBS/RBI output roots, or fall back to config
      rbs_output_dir = rbs_output_root || config.rbs_output_dir
      rbi_output_dir = rbi_output_root || config.rbi_output_dir
      case target
      when TranspileTarget::Ruby
        result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(bytes, path)
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
          return
        end

        if stdout
          puts result.output
        else
          write_or_print(path, output_root, result.output, ".rb", stdout, config.folder_mappings)

          # Generate accompanying RBS/RBI files if requested
          if (generate_rbs || config.generate_rbs) && !stdout
            ruby_bytes = result.output.to_slice
            tokens, lex_error, _ = Warp::Lang::Ruby::Lexer.scan(ruby_bytes)
            if lex_error == Warp::Core::ErrorCode::Success
              extractor = Warp::Lang::Ruby::Annotations::AnnotationExtractor.new(ruby_bytes, tokens)
              sigs = extractor.extract
              rbs_content = build_rbs(sigs)
              write_output(path, rbs_output_dir, rbs_content, ".rbs", config.folder_mappings)
            end
          end

          if (generate_rbi || config.generate_rbi) && !stdout
            ruby_bytes = result.output.to_slice
            tokens, lex_error, _ = Warp::Lang::Ruby::Lexer.scan(ruby_bytes)
            if lex_error == Warp::Core::ErrorCode::Success
              extractor = Warp::Lang::Ruby::Annotations::AnnotationExtractor.new(ruby_bytes, tokens)
              sigs = extractor.extract
              rbi_content = build_rbi(sigs)
              write_output(path, rbi_output_dir, rbi_content, ".rbi", config.folder_mappings)
            end
          end
        end
        return
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
        return
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
          return
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
        write_or_print(path, output_root, content, ext, stdout, config.folder_mappings)
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
          return
        end
        if stdout
          puts result.output
        else
          out_path = output_path_for(path, output_root, ".cr", config.folder_mappings)
          if result.crystal_doc
            Warp::Lang::Crystal::Serializer.emit_to_file(result.crystal_doc.not_nil!, out_path)
          else
            write_output(path, output_root, result.output, ".cr", config.folder_mappings)
          end
        end
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
  end
end
