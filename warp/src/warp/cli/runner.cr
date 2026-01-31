require "option_parser"
require "file_utils"

module Warp::CLI
  enum AnnotationMode
    None
    SorbetInline
    SorbetFile
    RbsInline
    RbsFile
  end

  class Runner
    def self.run(args : Array(String)) : Int32
      return run_transpile(args) if args.first? == "transpile"
      return run_init(args) if args.first? == "init"
      puts "Usage: warp <transpile|init> [options]"
      1
    end

    private def self.run_init(args : Array(String)) : Int32
      config_path = ".warp.yaml"
      template = <<-YAML
transpiler:
  include:
    - "**/*.rb"
  exclude:
    - "spec/**"
    - "vendor/**"
annotations:
  rbs_paths: []
  rbi_paths: []
  inline_rbs: true
output:
  directory: "out"
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
      mode = AnnotationMode::None
      source_path = "."
      config_path : String? = nil
      out_dir : String? = nil
      extra_rbs = [] of String
      extra_rbi = [] of String
      inline_rbs = true

      parser = OptionParser.new do |p|
        p.banner = "Usage: warp transpile [options]"
        p.on("-s PATH", "--source=PATH", "Source file or directory") { |v| source_path = v }
        p.on("-c PATH", "--config=PATH", "Config file (default .warp.yaml or warp.yaml)") { |v| config_path = v }
        p.on("-o DIR", "--out=DIR", "Output directory") { |v| out_dir = v }
        p.on("--annotations=MODE", "Annotation mode: none|sorbet-inline|sorbet-file|rbs-inline|rbs-file") do |v|
          mode = case v
                 when "sorbet-inline" then AnnotationMode::SorbetInline
                 when "sorbet-file" then AnnotationMode::SorbetFile
                 when "rbs-inline" then AnnotationMode::RbsInline
                 when "rbs-file" then AnnotationMode::RbsFile
                 else AnnotationMode::None
                 end
        end
              p.on("--rbs=PATH", "RBS file to load (repeatable)") { |v| extra_rbs << v }
              p.on("--rbi=PATH", "RBI file to load (repeatable)") { |v| extra_rbi << v }
              p.on("--inline-rbs=BOOL", "Parse inline # @rbs comments (default true)") { |v| inline_rbs = (v != "false") }
      end

      parser.parse(args[1..-1] || [] of String)

      config = ConfigLoader.load(config_path)
      output_root = out_dir || config.output_dir

      files = collect_files(source_path, config)
      if files.empty?
        puts "No Ruby files found."
        return 1
      end

      files.each do |path|
        process_file(path, output_root, mode, config, extra_rbs, extra_rbi, inline_rbs)
      end

      0
    end

    private def self.collect_files(source_path : String, config : ProjectConfig) : Array(String)
      if File.file?(source_path)
        return [source_path]
      end

      includes = config.include
      excludes = config.exclude
      files = includes.flat_map { |g| Dir.glob(g) }.select { |f| f.ends_with?(".rb") }
      files = files.reject { |f| excludes.any? { |ex| File.fnmatch(ex, f) } }
      files
    end

    private def self.process_file(
      path : String,
      output_root : String,
      mode : AnnotationMode,
      config : ProjectConfig,
      extra_rbs : Array(String),
      extra_rbi : Array(String),
      inline_rbs : Bool,
    )
      source = File.read(path)
      bytes = source.to_slice
      tokens, lex_error = Warp::Lang::Ruby::Lexer.scan(bytes)
      return unless lex_error == Warp::Core::ErrorCode::Success

      extractor = Warp::Lang::Ruby::Annotations::AnnotationExtractor.new(bytes, tokens)
      sigs = extractor.extract

      case mode
      when AnnotationMode::SorbetInline
        write_output(path, output_root, source, ".rb")
      when AnnotationMode::SorbetFile
        rbi = build_rbi(sigs)
        write_output(path, output_root, rbi, ".rbi")
      when AnnotationMode::RbsInline
        output = Warp::Lang::Ruby::Annotations::InlineRbsInjector.inject(source, sigs)
        write_output(path, output_root, output, ".rb")
      when AnnotationMode::RbsFile
        rbs = build_rbs(sigs)
        write_output(path, output_root, rbs, ".rbs")
      else
        # Phase 1 CST-to-CST (no-op) as default
        annotations = build_annotation_store(path, source, config, extra_rbs, extra_rbi, inline_rbs)
        result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(bytes, annotations)
        write_output(path, output_root, result.output, ".cr")
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
      rel = source_path
      rel = rel.sub(%r{^\./}, "")
      out_path = File.join(output_root, rel).sub(/\.rb$/, ext)
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
