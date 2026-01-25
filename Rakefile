# frozen_string_literal: true

require 'bundler/setup'
require 'rspec/core/rake_task'
require 'fileutils'
require 'rake/clean'

# Load the WireGram library
$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'wiregram'

# Configuration
LANGUAGES = %w[expression json ucl].freeze
SNAPSHOT_DIR = 'spec/snapshots'

# Clean task
CLEAN.include(
  'tmp/**/*',
  'coverage/**/*',
  '.rspec_status',
  '*.gem',
  'pkg/**/*',
  'Gemfile.lock'
)

CLOBBER.include('tmp', 'coverage')

# Default task
task default: %w[test]

# Build task
desc 'Build the project (no compilation needed for Ruby)'
task :build do
  puts 'WireGram is a Ruby project - no compilation required'
  puts 'All dependencies are loaded via Bundler'
  puts 'Project is ready to use!'
end

# Test tasks
namespace :test do
  desc 'Run all tests'
  task :all do
    RSpec::Core::RakeTask.new(:spec) do |t|
      t.pattern = 'spec/**/*_spec.rb'
    end
    Rake::Task['spec'].invoke
  end

  desc 'Run expression language tests'
  task :expression do
    RSpec::Core::RakeTask.new(:expression_spec) do |t|
      t.pattern = 'spec/languages/expression/**/*_spec.rb'
    end
    Rake::Task['expression_spec'].invoke
  end

  desc 'Run JSON language tests'
  task :json do
    RSpec::Core::RakeTask.new(:json_spec) do |t|
      t.pattern = 'spec/languages/json/**/*_spec.rb'
    end
    Rake::Task['json_spec'].invoke
  end

  desc 'Run UCL language tests'
  task :ucl do
    RSpec::Core::RakeTask.new(:ucl_spec) do |t|
      t.pattern = 'spec/languages/ucl/**/*_spec.rb'
    end
    Rake::Task['ucl_spec'].invoke
  end

  desc 'Run specific test file'
  task :file, [:file_path] do |t, args|
    if args.file_path
      RSpec::Core::RakeTask.new(:file_spec) do |spec|
        spec.pattern = args.file_path
      end
      Rake::Task['file_spec'].invoke
    else
      puts 'Please specify a test file path'
      puts 'Example: rake test:file[spec/languages/expression/integration_spec.rb]'
    end
  end
end

# Alias main test task
task :test => 'test:all'

# Snapshot tasks
namespace :snapshots do
  desc 'Generate new snapshots for all languages'
  task :generate do
    ENV['UPDATE_SNAPSHOTS'] = '1'

    puts 'Generating snapshots for all languages...'

    LANGUAGES.each do |language|
      puts "Generating #{language} snapshots..."

      # Run snapshot tests for each language
      RSpec::Core::RakeTask.new("#{language}_snapshot_gen") do |t|
        t.pattern = "spec/languages/#{language}/snapshot_spec.rb"
      end
      Rake::Task["#{language}_snapshot_gen"].invoke
    end

    puts 'Snapshot generation complete!'
  end

  desc 'Update existing snapshots for all languages'
  task :update => :generate

  desc 'Generate snapshots for specific language'
  task :generate_for, [:language] do |t, args|
    if args.language && LANGUAGES.include?(args.language)
      ENV['UPDATE_SNAPSHOTS'] = '1'

      puts "Generating #{args.language} snapshots..."

      RSpec::Core::RakeTask.new("#{args.language}_snapshot_gen") do |t|
        t.pattern = "spec/languages/#{args.language}/snapshot_spec.rb"
      end
      Rake::Task["#{args.language}_snapshot_gen"].invoke

      puts "#{args.language} snapshot generation complete!"
    else
      puts "Invalid language. Available languages: #{LANGUAGES.join(', ')}"
    end
  end

  desc 'Verify snapshots exist for all tests'
  task :verify do
    puts 'Verifying snapshots...'

    missing_snapshots = []

    # Check for snapshot files
    LANGUAGES.each do |language|
      snapshot_dir = File.join(SNAPSHOT_DIR, language)
      if Dir.exist?(snapshot_dir)
        snapshot_files = Dir.glob(File.join(snapshot_dir, '*.snap'))
        puts "Found #{snapshot_files.size} snapshots for #{language}"
      else
        puts "No snapshots found for #{language}"
        missing_snapshots << language
      end
    end

    if missing_snapshots.empty?
      puts 'All snapshots verified successfully!'
    else
      puts "Missing snapshots for: #{missing_snapshots.join(', ')}"
      puts 'Run `rake snapshots:generate` to generate missing snapshots'
    end
  end

  desc 'Clean snapshot files'
  task :clean do
    puts 'Cleaning snapshot files...'

    LANGUAGES.each do |language|
      snapshot_dir = File.join(SNAPSHOT_DIR, language)
      if Dir.exist?(snapshot_dir)
        FileUtils.rm_rf(Dir.glob(File.join(snapshot_dir, '*.snap')))
        puts "Cleaned #{language} snapshots"
      end
    end

    puts 'Snapshot cleanup complete!'
  end
end

# Documentation tasks
namespace :doc do
  desc 'Generate documentation'
  task :generate do
    puts 'Generating documentation...'

    # Check if yard is available
    begin
      require 'yard'
      YARD::CLI::Yardoc.run('--output-dir', 'docs/api', '--readme', 'README.md')
      puts 'API documentation generated in docs/api/'
    rescue LoadError
      puts 'Yard not available. Install with: gem install yard'
      puts 'Generating basic documentation...'

      # Fallback: generate basic documentation
      FileUtils.mkdir_p('docs/api')

      # Generate language documentation
      LANGUAGES.each do |language|
        lang_module = "WireGram::Languages::#{language.capitalize}".constantize
        doc_file = File.join('docs/api', "#{language}_api.md")

        File.open(doc_file, 'w') do |f|
          f.puts "# #{language.capitalize} API Documentation"
          f.puts
          f.puts "## Available Methods"
          f.puts
          lang_module.methods(false).sort.each do |method|
            f.puts "- `#{method}`"
          end
        end
      end

      puts 'Basic documentation generated in docs/api/'
    end
  end

  desc 'Open documentation in browser'
  task :open do
    doc_dir = 'docs/api'
    if Dir.exist?(doc_dir)
      index_file = File.join(doc_dir, 'index.html')
      if File.exist?(index_file)
        puts "Opening documentation: #{index_file}"
        # Try different methods to open the file
        begin
          if RUBY_PLATFORM =~ /darwin/
            system("open #{index_file}")
          elsif RUBY_PLATFORM =~ /linux|bsd/
            system("xdg-open #{index_file}")
          elsif RUBY_PLATFORM =~ /mswin|mingw|cygwin/
            system("start #{index_file}")
          else
            puts "Please open #{index_file} manually"
          end
        rescue
          puts "Please open #{index_file} manually"
        end
      else
        puts "No index.html found in #{doc_dir}"
        puts "Run `rake doc:generate` first"
      end
    else
      puts "No documentation found in #{doc_dir}"
      puts "Run `rake doc:generate` first"
    end
  end
end

# Utility tasks
namespace :utils do
  desc 'List available languages'
  task :list_languages do
    puts 'Available languages:'
    LANGUAGES.each do |lang|
      puts "  - #{lang}"
    end
  end

  desc 'Show language statistics'
  task :stats do
    puts 'Language Statistics:'

    LANGUAGES.each do |language|
      lang_dir = File.join('lib/wiregram/languages', language)
      spec_dir = File.join('spec/languages', language)

      if Dir.exist?(lang_dir) && Dir.exist?(spec_dir)
        source_files = Dir.glob(File.join(lang_dir, '**/*.rb')).size
        test_files = Dir.glob(File.join(spec_dir, '**/*_spec.rb')).size
        fixture_files = Dir.glob(File.join(spec_dir, 'fixtures/**/*')).size

        puts "  #{language.capitalize}:"
        puts "    Source files: #{source_files}"
        puts "    Test files: #{test_files}"
        puts "    Fixture files: #{fixture_files}"
        puts
      end
    end
  end

  desc 'Run language examples'
  task :examples do
    examples_dir = 'examples'
    if Dir.exist?(examples_dir)
      puts 'Running examples...'

      Dir.glob(File.join(examples_dir, '*.rb')).each do |example_file|
        example_name = File.basename(example_file, '.rb')
        puts "Running #{example_name}..."

        begin
          load example_file
          puts "  #{example_name} completed successfully"
        rescue => e
          puts "  #{example_name} failed: #{e.message}"
        end
      end
    else
      puts "No examples directory found at #{examples_dir}"
    end
  end
end

# Development tasks
namespace :dev do
  desc 'Run interactive console with project loaded'
  task :console do
    puts 'Starting WireGram console...'
    puts 'Type `exit` to quit'

    # Start IRB with project loaded
    require 'irb'
    require 'irb/completion'

    # Load all languages for easy access
    require 'wiregram/languages/expression'
    require 'wiregram/languages/json'
    require 'wiregram/languages/ucl'

    ARGV.clear
    IRB.start
  end

  desc 'Run all development checks'
  task :check do
    puts 'Running development checks...'

    # Check Ruby version
    required_ruby_version = '2.7.0'
    current_ruby_version = RUBY_VERSION

    if Gem::Version.new(current_ruby_version) >= Gem::Version.new(required_ruby_version)
      puts "✓ Ruby version #{current_ruby_version} is compatible"
    else
      puts "✗ Ruby version #{current_ruby_version} is incompatible (need >= #{required_ruby_version})"
    end

    # Check dependencies
    begin
      require 'bundler'
      puts '✓ Bundler is available'
    rescue LoadError
      puts '✗ Bundler is not available'
    end

    # Check test framework
    begin
      require 'rspec'
      puts '✓ RSpec is available'
    rescue LoadError
      puts '✗ RSpec is not available'
    end

    # Check language modules
    LANGUAGES.each do |language|
      begin
        require "wiregram/languages/#{language}"
        puts "✓ #{language.capitalize} language module loads successfully"
      rescue => e
        puts "✗ #{language.capitalize} language module failed to load: #{e.message}"
      end
    end
  end

  desc 'Profile performance'
  task :profile do
    puts 'Profiling WireGram performance...'

    require 'benchmark'

    test_cases = {
      'Expression' => 'let x = 42 + 10 * (5 - 2)',
      'JSON' => '{"name": "test", "value": 42, "nested": {"key": "value"}}',
      'UCL' => 'key = "value"; nested { subkey = 42; }'
    }

    test_cases.each do |name, input|
      puts "\nProfiling #{name}:"

      module_name = "WireGram::Languages::#{name}"
      language_module = module_name.constantize

      Benchmark.bm do |x|
        x.report('Complete pipeline:') do
          100.times { language_module.process(input) }
        end

        x.report('Tokenization:') do
          100.times { language_module.tokenize(input) }
        end

        x.report('Parsing:') do
          100.times { language_module.parse(input) }
        end

        x.report('Transformation:') do
          100.times { language_module.transform(input) }
        end

        x.report('Serialization:') do
          100.times { language_module.serialize(input) }
        end
      end
    end
  end
end

# Help task
desc 'Show available tasks'
task :help do
  puts 'WireGram Rake Tasks:'
  puts
  puts 'Build Tasks:'
  puts '  rake build                    - Build the project'
  puts
  puts 'Test Tasks:'
  puts '  rake test                     - Run all tests'
  puts '  rake test:expression          - Run expression language tests'
  puts '  rake test:json                - Run JSON language tests'
  puts '  rake test:ucl                 - Run UCL language tests'
  puts '  rake test:file[path]          - Run specific test file'
  puts
  puts 'Snapshot Tasks:'
  puts '  rake snapshots:generate       - Generate new snapshots'
  puts '  rake snapshots:update         - Update existing snapshots'
  puts '  rake snapshots:generate_for[lang] - Generate snapshots for specific language'
  puts '  rake snapshots:verify         - Verify snapshots exist'
  puts '  rake snapshots:clean          - Clean snapshot files'
  puts
  puts 'Documentation Tasks:'
  puts '  rake doc:generate             - Generate documentation'
  puts '  rake doc:open                 - Open documentation in browser'
  puts
  puts 'Utility Tasks:'
  puts '  rake utils:list_languages     - List available languages'
  puts '  rake utils:stats              - Show language statistics'
  puts '  rake utils:examples           - Run language examples'
  puts
  puts 'Development Tasks:'
  puts '  rake dev:console              - Run interactive console'
  puts '  rake dev:check                - Run development checks'
  puts '  rake dev:profile              - Profile performance'
  puts
  puts 'Other Tasks:'
  puts '  rake clean                    - Clean build artifacts'
  puts '  rake clobber                  - Remove all generated files'
  puts '  rake help                     - Show this help message'
end

# Set default task
task :default => :help
