require "yaml"

module Warp::CLI
  struct ProjectConfig
    getter include : Array(String)
    getter exclude : Array(String)
    getter output_dir : String
    getter ruby_output_dir : String
    getter crystal_output_dir : String
    getter rbs_output_dir : String
    getter rbi_output_dir : String
    getter generate_rbs : Bool
    getter generate_rbi : Bool
    getter folder_mappings : Hash(String, String)
    getter rbs_paths : Array(String)
    getter rbi_paths : Array(String)
    getter inline_rbs : Bool

    def initialize(
      @include : Array(String),
      @exclude : Array(String),
      @output_dir : String,
      @ruby_output_dir : String,
      @crystal_output_dir : String,
      @rbs_output_dir : String,
      @rbi_output_dir : String,
      @generate_rbs : Bool = false,
      @generate_rbi : Bool = false,
      @folder_mappings : Hash(String, String) = {} of String => String,
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
        transpiler = data["transpiler"]?.try(&.as_h?)
        output = data["output"]?.try(&.as_h?)
        annotations = data["annotations"]?.try(&.as_h?)

        include_globs = transpiler.try(&.["include"]?).try(&.as_a?).try(&.map(&.as_s)) || ["**/*.rb", "**/*.cr"]
        exclude_globs = transpiler.try(&.["exclude"]?).try(&.as_a?).try(&.map(&.as_s)) || [] of String
        output_dir = output.try(&.["directory"]?).try(&.as_s) || "out"
        ruby_output_dir = output.try(&.["ruby_directory"]?).try(&.as_s) || output_dir
        crystal_output_dir = output.try(&.["crystal_directory"]?).try(&.as_s) || output_dir
        rbs_output_dir = output.try(&.["rbs_directory"]?).try(&.as_s) || ruby_output_dir
        rbi_output_dir = output.try(&.["rbi_directory"]?).try(&.as_s) || ruby_output_dir
        generate_rbs = output.try(&.["generate_rbs"]?).try(&.as_bool) || false
        generate_rbi = output.try(&.["generate_rbi"]?).try(&.as_bool) || false
        folder_mappings_yaml = output.try(&.["folder_mappings"]?).try(&.as_h?) || {} of YAML::Any => YAML::Any
        folder_mappings = folder_mappings_yaml.transform_keys(&.as_s).transform_values(&.as_s)
        rbs_paths = annotations.try(&.["rbs_paths"]?).try(&.as_a?).try(&.map(&.as_s)) || [] of String
        rbi_paths = annotations.try(&.["rbi_paths"]?).try(&.as_a?).try(&.map(&.as_s)) || [] of String
        inline_rbs = annotations.try(&.["inline_rbs"]?).try(&.as_bool) || true
        return ProjectConfig.new(include_globs, exclude_globs, output_dir, ruby_output_dir, crystal_output_dir, rbs_output_dir, rbi_output_dir, generate_rbs, generate_rbi, folder_mappings, rbs_paths, rbi_paths, inline_rbs)
      end

      # fallback to warp.yaml if present
      if File.exists?("warp.yaml")
        data = YAML.parse(File.read("warp.yaml"))
        transpiler = data["transpiler"]?.try(&.as_h?)
        output = data["output"]?.try(&.as_h?)
        annotations = data["annotations"]?.try(&.as_h?)

        include_globs = transpiler.try(&.["include"]?).try(&.as_a?).try(&.map(&.as_s)) || ["**/*.rb", "**/*.cr"]
        exclude_globs = transpiler.try(&.["exclude"]?).try(&.as_a?).try(&.map(&.as_s)) || [] of String
        output_dir = output.try(&.["directory"]?).try(&.as_s) || "out"
        ruby_output_dir = output.try(&.["ruby_directory"]?).try(&.as_s) || output_dir
        crystal_output_dir = output.try(&.["crystal_directory"]?).try(&.as_s) || output_dir
        rbs_output_dir = output.try(&.["rbs_directory"]?).try(&.as_s) || ruby_output_dir
        rbi_output_dir = output.try(&.["rbi_directory"]?).try(&.as_s) || ruby_output_dir
        generate_rbs = output.try(&.["generate_rbs"]?).try(&.as_bool) || false
        generate_rbi = output.try(&.["generate_rbi"]?).try(&.as_bool) || false
        folder_mappings_yaml = output.try(&.["folder_mappings"]?).try(&.as_h?) || {} of YAML::Any => YAML::Any
        folder_mappings = folder_mappings_yaml.transform_keys(&.as_s).transform_values(&.as_s)
        rbs_paths = annotations.try(&.["rbs_paths"]?).try(&.as_a?).try(&.map(&.as_s)) || [] of String
        rbi_paths = annotations.try(&.["rbi_paths"]?).try(&.as_a?).try(&.map(&.as_s)) || [] of String
        inline_rbs = annotations.try(&.["inline_rbs"]?).try(&.as_bool) || true
        return ProjectConfig.new(include_globs, exclude_globs, output_dir, ruby_output_dir, crystal_output_dir, rbs_output_dir, rbi_output_dir, generate_rbs, generate_rbi, folder_mappings, rbs_paths, rbi_paths, inline_rbs)
      end

      ProjectConfig.new(["**/*.rb", "**/*.cr"], [] of String, "out", "out", "out", "out", "out", false, false, {} of String => String, [] of String, [] of String, true)
    end
  end
end
