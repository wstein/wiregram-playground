# frozen_string_literal: true

# Integration helpers for Cucumber feature tests.
#
# These provide small utilities used by the feature step definitions
# (fixture loading, CLI invocation, IO capture, etc.).
module IntegrationHelpers
  def language_module(language)
    case language
    when 'expression'
      WireGram::Languages::Expression
    when 'json'
      WireGram::Languages::Json
    when 'ucl'
      WireGram::Languages::Ucl
    else
      raise "Unknown language: #{language}"
    end
  end

  def fixture_path(language, filename)
    File.expand_path("../../spec/languages/#{language}/fixtures/#{filename}", __dir__)
  end

  def load_fixture(language, filename)
    File.read(fixture_path(language, filename))
  end

  def capture_io
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    [$stdout.string, $stderr.string]
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def with_stdin(stdin)
    original_stdin = $stdin
    $stdin = stdin
    yield
  ensure
    $stdin = original_stdin
  end

  def run_cli(args, stdin: nil)
    stdin ||= StringIO.new('')
    stdin.define_singleton_method(:tty?) do
      true
    end

    @cli_exit_status = 0
    @cli_stdout = ''
    @cli_stderr = ''

    with_stdin(stdin) do
      @cli_stdout, @cli_stderr = capture_io do
        WireGram::CLI::Runner.start(args)
      rescue SystemExit => e
        @cli_exit_status = e.status || 1
      end
    end
  end
end

World(IntegrationHelpers)
