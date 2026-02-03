require "yaml"

module Warp::Lang::Ruby
  # TranspilerConfig loads and manages transpiler configuration
  class TranspilerConfig
    struct LibraryRule
      property action : String # "comment_out", "remove", "map_type", "remove_cast"
      property pattern : String?
      property replacement : String?
      property description : String?

      def initialize(@action, @pattern = nil, @replacement = nil, @description = nil)
      end
    end

    @config : Hash(YAML::Any, YAML::Any)

    def initialize(config_path : String? = nil)
      path = config_path || (File.exists?(".warp.yaml") ? ".warp.yaml" : "warp-transpile.yaml")
      if File.exists?(path)
        parsed = YAML.parse(File.read(path))
        @config = parsed.as_h
      else
        @config = {} of YAML::Any => YAML::Any
      end
    end

    # Get library rule for target language
    def get_library_rule(target_lang : Symbol, library_name : String) : LibraryRule?
      target_key = target_lang.to_s

      targets_any = @config["targets"]?
      return nil unless targets_any
      targets = targets_any.as_h?
      return nil unless targets

      target_config_any = targets[YAML::Any.new(target_key)]?
      return nil unless target_config_any
      target_config = target_config_any.as_h?
      return nil unless target_config

      libraries_any = target_config[YAML::Any.new("libraries")]?
      return nil unless libraries_any
      libraries = libraries_any.as_h?
      return nil unless libraries

      lib_config_any = libraries[YAML::Any.new(library_name)]?
      return nil unless lib_config_any
      lib_config = lib_config_any.as_h?
      return nil unless lib_config

      # Extract action with fallback to "keep"
      action_any = lib_config[YAML::Any.new("action")]?
      action = (action_any.as_s? if action_any) || "keep"

      # Extract optional fields
      pattern_any = lib_config[YAML::Any.new("pattern")]?
      pattern = pattern_any.as_s? if pattern_any

      replacement_any = lib_config[YAML::Any.new("replacement")]?
      replacement = replacement_any.as_s? if replacement_any

      description_any = lib_config[YAML::Any.new("description")]?
      description = description_any.as_s? if description_any

      LibraryRule.new(
        action: action,
        pattern: pattern,
        replacement: replacement,
        description: description
      )
    end

    # Get type mapping for target language
    def get_type_mapping(target_lang : Symbol) : Hash(String, String)
      target_key = target_lang.to_s

      targets_any = @config["targets"]?
      return {} of String => String unless targets_any
      targets = targets_any.as_h?
      return {} of String => String unless targets

      target_config_any = targets[YAML::Any.new(target_key)]?
      return {} of String => String unless target_config_any
      target_config = target_config_any.as_h?
      return {} of String => String unless target_config

      mappings_any = target_config[YAML::Any.new("type_mappings")]?
      return {} of String => String unless mappings_any
      mappings = mappings_any.as_h?
      return {} of String => String unless mappings

      result = {} of String => String
      mappings.each do |k, v|
        result[k.as_s] = v.as_s
      end
      result
    end

    # Get Sorbet construct rule
    def get_sorbet_construct_rule(construct_name : String) : LibraryRule?
      constructs = @config["targets"]?["crystal"]?["sorbet_constructs"]?
      return nil unless constructs

      rule_config = constructs[construct_name]?
      return nil unless rule_config

      LibraryRule.new(
        action: rule_config["action"]?.as_s || "keep",
        pattern: rule_config["pattern"]?.as_s?,
        replacement: rule_config["replacement"]?.as_s?,
        description: rule_config["description"]?.as_s?
      )
    end

    # Check if keyword argument conversion is enabled
    def keyword_arguments_enabled?(target_lang : Symbol) : Bool
      target_key = target_lang.to_s
      enabled = @config["targets"]?[target_key]?["keyword_arguments"]?["enabled"]?
      enabled.as_bool? || false
    end

    # Get global settings
    def preserve_comments? : Bool
      @config["settings"]?["preserve_comments"]?.as_bool? || true
    end

    def preserve_formatting? : Bool
      @config["settings"]?["preserve_formatting"]?.as_bool? || true
    end

    def minimal_changes? : Bool
      @config["settings"]?["minimal_changes"]?.as_bool? || true
    end

    # Get target output path for a given target language
    def get_target_path(target_lang : Symbol) : String?
      target_key = target_lang.to_s
      targets_any = @config["targets"]?
      return nil unless targets_any
      targets = targets_any.as_h?
      return nil unless targets

      target_config_any = targets[YAML::Any.new(target_key)]?
      return nil unless target_config_any
      target_config = target_config_any.as_h?
      return nil unless target_config

      target_path_any = target_config[YAML::Any.new("target_path")]?
      return nil unless target_path_any
      target_path_any.as_s?
    end

    # Get folder mappings from output section
    def get_folder_mappings : Hash(String, String)
      output_any = @config["output"]?
      return {} of String => String unless output_any
      output = output_any.as_h?
      return {} of String => String unless output

      mappings_any = output[YAML::Any.new("folder_mappings")]?
      return {} of String => String unless mappings_any
      mappings = mappings_any.as_h?
      return {} of String => String unless mappings

      result = {} of String => String
      mappings.each do |k, v|
        result[k.as_s] = v.as_s
      end
      result
    end

    # Get standard library require mappings (e.g., spec → rspec)
    def get_stdlib_mappings : Hash(String, String)
      mappings_any = @config["stdlib_mappings"]?
      return {} of String => String unless mappings_any
      mappings = mappings_any.as_h?
      return {} of String => String unless mappings

      result = {} of String => String
      mappings.each do |k, v|
        result[k.as_s] = v.as_s
      end
      result
    end
  end
end
