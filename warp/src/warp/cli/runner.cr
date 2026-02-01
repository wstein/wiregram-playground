require "option_parser"
require "file_utils"

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

Targets:
  crystal       Ruby -> Crystal (default)
  ruby          Crystal -> Ruby
  rbs           Generate .rbs files from Sorbet sigs
  rbi           Generate .rbi files from Sorbet sigs
  inject-rbs    Inject inline # @rbs comments into Ruby source
  round-trip    Validate round-trip (Ruby <-> Crystal)
TXT
    end

    private def self.transpile_usage : String
      <<-TXT
Usage:
  warp transpile [crystal|ruby|rbs|rbi|inject-rbs|round-trip] [options]

Options:
  -s, --source=PATH       Source file or directory
  -c, --config=PATH       Config file (default .warp.yaml or warp.yaml)
  -o, --out=DIR           Output directory
  --rbs=PATH              RBS file to load (repeatable)
  --rbi=PATH              RBI file to load (repeatable)
  --inline-rbs=BOOL       Parse inline # @rbs comments (default true)
  --stdout                Write output to stdout
TXT
    end

    private def self.run_init(args : Array(String)) : Int32
      config_path = ".warp.yaml"
      template = <<-YAML
transpiler:
  include:
    - "**/*.rb"
    - "**/*.cr"
  exclude:
    - "spec/**"
    - "vendor/**"
annotations:
  rbs_paths: []
  rbi_paths: []
  inline_rbs: true
output:
  directory: "out"
  ruby_directory: "out/ruby"
  crystal_directory: "out/crystal"
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
      stdout = false

      parser = OptionParser.new do |p|
        p.banner = transpile_usage
        p.on("-s PATH", "--source=PATH", "Source file or directory") { |v| source_path = v }
        p.on("-c PATH", "--config=PATH", "Config file (default .warp.yaml or warp.yaml)") { |v| config_path = v }
        p.on("-o DIR", "--out=DIR", "Output directory") { |v| out_dir = v }
        p.on("--rbs=PATH", "RBS file to load (repeatable)") { |v| extra_rbs << v }
        p.on("--rbi=PATH", "RBI file to load (repeatable)") { |v| extra_rbi << v }
        p.on("--inline-rbs=BOOL", "Parse inline # @rbs comments (default true)") { |v| inline_rbs = (v != "false") }
        p.on("--stdout", "Write output to stdout") { stdout = true }
      end

      parser.parse(args || [] of String)

      config = ConfigLoader.load(config_path)
      output_root = (out_dir || config.output_dir).not_nil!
      if out_dir.nil?
        output_root = case target
                      when TranspileTarget::Ruby
                        config.ruby_output_dir
                      when TranspileTarget::Crystal
                        config.crystal_output_dir
                      else
                        config.output_dir
                      end
      end

      files = collect_files(source_path, config, target)
      if files.empty?
        puts "No source files found."
        return 1
      end

      files.each do |path|
        process_file(path, output_root, target, config, extra_rbs, extra_rbi, inline_rbs, stdout)
      end

      0
    end

    private def self.collect_files(source_path : String, config : ProjectConfig, target : TranspileTarget) : Array(String)
      if File.file?(source_path)
        return [source_path]
      end

      includes = config.include
      excludes = config.exclude
      exts = case target
             when TranspileTarget::Crystal, TranspileTarget::Rbs, TranspileTarget::Rbi, TranspileTarget::InjectRbs
               [".rb"]
             when TranspileTarget::Ruby
               [".cr"]
             else
               [".rb", ".cr"]
             end
      files = includes.flat_map { |g| Dir.glob(g) }.select { |f| exts.any? { |ext| f.ends_with?(ext) } }
      files = files.reject { |f| excludes.any? { |ex| File.match?(ex, f) } }
      files
    end

    private def self.process_file(
      path : String,
      output_root : String,
      target : TranspileTarget,
      config : ProjectConfig,
      extra_rbs : Array(String),
      extra_rbi : Array(String),
      inline_rbs : Bool,
      stdout : Bool,
    )
      source = File.read(path)
      bytes = source.to_slice
      case target
      when TranspileTarget::Ruby
        result = Warp::Lang::Crystal::CrystalToRubyTranspiler.transpile(bytes)
        if result.error != Warp::Core::ErrorCode::Success
          puts "Transpile error (Crystal->Ruby): #{path}"
          result.diagnostics.each { |d| puts "  - #{d}" }
          return
        end

        if stdout
          puts result.output
        else
          write_or_print(path, output_root, result.output, ".rb", stdout)
        end
        return
      when TranspileTarget::RoundTrip
        if path.ends_with?(".rb")
          result = Warp::Testing::BidirectionalValidator.ruby_to_crystal_to_ruby(source)
          puts "Round-trip Ruby: #{path} (delta=#{result.formatting_delta})"
          result.diagnostics.each { |d| puts "  - #{d}" }
        elsif path.ends_with?(".cr")
          result = Warp::Testing::BidirectionalValidator.crystal_to_ruby_to_crystal(source)
          puts "Round-trip Crystal: #{path} (delta=#{result.formatting_delta})"
          result.diagnostics.each { |d| puts "  - #{d}" }
        else
          puts "Skipping unsupported file: #{path}"
        end
        return
      else
        tokens, lex_error = Warp::Lang::Ruby::Lexer.scan(bytes)
        if lex_error != Warp::Core::ErrorCode::Success
          puts "Lex error (Ruby): #{path}"
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
        write_or_print(path, output_root, content, ext, stdout)
      else
        annotations = build_annotation_store(path, source, config, extra_rbs, extra_rbi, inline_rbs)
        result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(bytes, annotations)
        if result.error != Warp::Core::ErrorCode::Success
          puts "Transpile error (Ruby->Crystal): #{path}"
          result.diagnostics.each { |d| puts "  - #{d}" }
          return
        end
        if stdout
          puts result.output
        else
          out_path = output_path_for(path, output_root, ".cr")
          if result.crystal_doc
            Warp::Lang::Crystal::Serializer.emit_to_file(result.crystal_doc.not_nil!, out_path)
          else
            write_output(path, output_root, result.output, ".cr")
          end
        end
      end
    end

    private def self.output_path_for(source_path : String, output_root : String, ext : String) : String
      rel = source_path
      rel = rel.sub(%r{^\./}, "")
      File.join(output_root, rel).sub(/\.rb$/, ext)
    end

    private def self.write_or_print(source_path : String, output_root : String, content : String, ext : String, stdout : Bool)
      if stdout
        puts content
      else
        write_output(source_path, output_root, content, ext)
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

    private def self.write_output(source_path : String, output_root : String, content : String, ext : String)
      out_path = output_path_for(source_path, output_root, ext)
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
