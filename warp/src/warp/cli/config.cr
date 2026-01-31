require "yaml"

module Warp::CLI
  struct ProjectConfig
    getter include : Array(String)
    getter exclude : Array(String)
    getter output_dir : String
    getter rbs_paths : Array(String)
    getter rbi_paths : Array(String)
    getter inline_rbs : Bool

    def initialize(
      @include : Array(String),
      @exclude : Array(String),
      @output_dir : String,
      @rbs_paths : Array(String) = [] of String,
      @rbi_paths : Array(String) = [] of String,
      @inline_rbs : Bool = true,
    )
    end
  end

  class ConfigLoader
    def self.load(path : String?) : ProjectConfig
      config_path = path || ".warp.yaml"
      if File.exists?(config_path)
        data = YAML.parse(File.read(config_path))
        include_globs = data["transpiler"]?["include"]?.try(&.as_a?).try(&.map(&.as_s)) || ["**/*.rb"]
        exclude_globs = data["transpiler"]?["exclude"]?.try(&.as_a?).try(&.map(&.as_s)) || [] of String
        output_dir = data["output"]?["directory"]?.try(&.as_s) || "out"
        rbs_paths = data["annotations"]?["rbs_paths"]?.try(&.as_a?).try(&.map(&.as_s)) || [] of String
        rbi_paths = data["annotations"]?["rbi_paths"]?.try(&.as_a?).try(&.map(&.as_s)) || [] of String
        inline_rbs = data["annotations"]?["inline_rbs"]?.try(&.as_bool) || true
        return ProjectConfig.new(include_globs, exclude_globs, output_dir, rbs_paths, rbi_paths, inline_rbs)
      end

      # fallback to warp.yaml if present
      if File.exists?("warp.yaml")
        data = YAML.parse(File.read("warp.yaml"))
        include_globs = data["transpiler"]?["include"]?.try(&.as_a?).try(&.map(&.as_s)) || ["**/*.rb"]
        exclude_globs = data["transpiler"]?["exclude"]?.try(&.as_a?).try(&.map(&.as_s)) || [] of String
        output_dir = data["output"]?["directory"]?.try(&.as_s) || "out"
        rbs_paths = data["annotations"]?["rbs_paths"]?.try(&.as_a?).try(&.map(&.as_s)) || [] of String
        rbi_paths = data["annotations"]?["rbi_paths"]?.try(&.as_a?).try(&.map(&.as_s)) || [] of String
        inline_rbs = data["annotations"]?["inline_rbs"]?.try(&.as_bool) || true
        return ProjectConfig.new(include_globs, exclude_globs, output_dir, rbs_paths, rbi_paths, inline_rbs)
      end

      ProjectConfig.new(["**/*.rb"], [] of String, "out", [] of String, [] of String, true)
    end
  end
end
