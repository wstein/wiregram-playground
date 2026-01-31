#!/usr/bin/env ruby

require 'prism'
require 'json'
require 'set'

class RubyIRGenerator
  def initialize(project_root = Dir.pwd)
    @project_root = File.expand_path(project_root)
    @visited_files = Set.new
    @ir = {
      "files" => {},
      "dependencies" => [],
      "classes" => {},
      "methods" => {},
      "constants" => {},
      "includes" => []
    }
  end

  def parse_file(file_path)
    return if @visited_files.include?(file_path)
    @visited_files.add(file_path)

    begin
      source = File.read(file_path)
      ast = Prism.parse(source)

      file_ir = {
        "path" => file_path,
        "classes" => [],
        "methods" => [],
        "constants" => [],
        "includes" => [],
        "requires" => []
      }

      # Parse the AST
      ast.value.statements.body.each do |node|
        case node.type
        when :ClassNode
          class_info = parse_class(node)
          file_ir["classes"] << class_info
          @ir["classes"][class_info["name"]] = class_info

          # Parse methods and includes inside the class
          node.body.body.each do |class_node|
            case class_node.type
            when :DefNode
              method_info = parse_method(class_node)
              file_ir["methods"] << method_info
              @ir["methods"][method_info["signature"]] = method_info
            when :CallNode
              if class_node.name == :include
                include_info = parse_include(class_node)
                file_ir["includes"] << include_info
                @ir["includes"] << include_info
              end
            end
          end
        when :DefNode
          method_info = parse_method(node)
          file_ir["methods"] << method_info
          @ir["methods"][method_info["signature"]] = method_info
        when :ConstantPathWriteNode
          const_info = parse_constant(node)
          file_ir["constants"] << const_info
          @ir["constants"][const_info["name"]] = const_info
        when :CallNode
          if node.name == :require || node.name == :require_relative
            require_info = parse_require(node)
            file_ir["requires"] << require_info
            @ir["dependencies"] << require_info
          end
        when :IncludeNode
          include_info = parse_include(node)
          file_ir["includes"] << include_info
          @ir["includes"] << include_info
        end
      end

      @ir["files"][file_path] = file_ir
    rescue => e
      puts "Error parsing #{file_path}: #{e.message}"
    end
  end

  def parse_class(node)
    {
      "name" => node.constant_path.slice,
      "superclass" => node.superclass&.slice,
      "methods" => [],
      "constants" => [],
      "line" => node.location.start_line
    }
  end

  def parse_method(node)
    params = if node.parameters
      node.parameters.requireds.map(&:slice).join(", ")
    else
      ""
    end

    {
      "name" => node.name.to_s,
      "signature" => "#{node.name}(#{params})",
      "line" => node.location.start_line
    }
  end

  def parse_constant(node)
    {
      "name" => node.constant_path.slice,
      "value" => node.value&.slice,
      "line" => node.location.start_line
    }
  end

  def parse_require(node)
    require_path = node.arguments&.arguments&.first&.slice || ""
    {
      "type" => node.name.to_s,
      "path" => require_path,
      "line" => node.location.start_line
    }
  end

  def parse_include(node)
    {
      "module" => node.arguments&.arguments&.first&.slice || node.name.slice,
      "line" => node.location.start_line
    }
  end

  def resolve_project_includes
    # Find all Ruby files in the project
    ruby_files = Dir.glob("#{@project_root}/**/*.rb")

    ruby_files.each do |file|
      parse_file(file)
    end

    # Resolve includes for project-specific modules
    @ir["includes"].each do |include_info|
      module_name = include_info["module"]
      # Look for files that might define this module
      potential_files = find_module_files(module_name)
      include_info["resolved_files"] = potential_files
    end
  end

  def find_module_files(module_name)
    # Convert module name to potential file paths
    # e.g., "MyModule::Nested" -> "my_module/nested.rb"
    file_candidates = []

    # Handle nested modules
    parts = module_name.split('::')
    base_name = parts.last.downcase

    # Look for files with the module name
    file_candidates << "#{base_name}.rb"
    file_candidates << "#{base_name.pluralize}.rb" if base_name.singularize != base_name

    # Look in common directories
    common_dirs = ['lib', 'app', 'models', 'controllers', 'helpers']
    common_dirs.each do |dir|
      file_candidates << "#{dir}/#{base_name}.rb"
      file_candidates << "#{dir}/#{base_name.pluralize}.rb" if base_name.singularize != base_name
    end

    # Search for matching files
    potential_files = []
    file_candidates.each do |candidate|
      full_path = File.join(@project_root, candidate)
      potential_files << full_path if File.exist?(full_path)
    end

    potential_files
  end

  def generate_ir
    resolve_project_includes
    @ir
  end

  def to_json
    JSON.pretty_generate(generate_ir)
  end
end

# CLI interface
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby ruby_parser.rb <file_path> [project_root]"
    puts "Example: ruby ruby_parser.rb app/models/user.rb"
    exit 1
  end

  file_path = ARGV[0]
  project_root = ARGV[1] || File.dirname(file_path)

  if !File.exist?(file_path)
    puts "Error: File '#{file_path}' does not exist"
    exit 1
  end

  generator = RubyIRGenerator.new(project_root)
  ir_json = generator.to_json

  puts ir_json
end
