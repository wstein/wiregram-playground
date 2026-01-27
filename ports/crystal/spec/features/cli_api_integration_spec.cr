require "../spec_helper"

private def project_root
  File.expand_path("../../../..", __DIR__)
end

private def cli_path
  File.join(project_root, "ports/crystal/src/wiregram/cli.cr")
end

private def run_cli(args : Array(String))
  output = IO::Memory.new
  error = IO::Memory.new
  env = {"CRYSTAL_CACHE_DIR" => "/tmp/crystal_cache"}
  status = Process.run("crystal", ["run", cli_path, "--", *args], env: env, output: output, error: error)
  {stdout: output.to_s, stderr: error.to_s, status: status.exit_code}
end

describe "CLI and API integration" do
  it "lists languages via the CLI" do
    result = run_cli(["list"])

    expect(result[:status]).to eq(0)
    expect(result[:stdout]).to contain("Available languages:")
    expect(result[:stdout]).to contain("expression")
    expect(result[:stdout]).to contain("json")
    expect(result[:stdout]).to contain("ucl")
  end

  it "shows help for a language" do
    result = run_cli(["json", "help"])

    expect(result[:status]).to eq(0)
    expect(result[:stdout]).to contain("json commands:")
  end

  it "inspects json from a file" do
    path = File.join(Dir.tempdir, "wiregram_cli_#{Time.utc.to_unix}.json")
    File.write(path, "{\"a\":1}")

    begin
      result = run_cli(["json", "inspect", path])
      expect(result[:status]).to eq(0)
    ensure
      File.delete(path) if File.exists?(path)
    end
  end

  it "inspects json with no stdin" do
    result = run_cli(["json", "inspect"])

    expect(result[:status]).to eq(0)
  end

  it "rejects unknown language" do
    result = run_cli(["foobar", "help"])

    expect(result[:status]).to eq(1)
    expect(result[:stderr]).to contain("Unknown command: foobar")
  end

  it "exposes available languages in the API" do
    available = WireGram::CLI::Languages.available
    expect(available).to contain("json")
    expect(available).to contain("expression")
    expect(available).to contain("ucl")
  end

  it "resolves language modules" do
    {
      "json" => WireGram::Languages::Json,
      "expression" => WireGram::Languages::Expression,
      "ucl" => WireGram::Languages::Ucl
    }.each do |language, mod|
      resolved = WireGram::CLI::Languages.module_for(language)
      expect(resolved).to eq(mod)
    end
  end

  it "language modules support core actions" do
    cases = [
      {"language" => "json", "input" => "{\"name\": \"test\", \"value\": 42}"},
      {"language" => "expression", "input" => "let x = 10 + 20"},
      {"language" => "ucl", "input" => "server { port = 8080; }"}
    ]

    cases.each do |example|
      mod = WireGram::CLI::Languages.module_for(example["language"]).not_nil!
      result = mod.process(example["input"])

      expect(result.has_key?(:tokens)).to be_true
      expect(result.has_key?(:ast)).to be_true
      expect(result.has_key?(:output)).to be_true

      tokens = mod.tokenize(example["input"])
      expect(tokens).to be_a(Array(WireGram::Core::Token))

      ast = mod.parse(example["input"])
      expect(ast).to be_a(WireGram::Core::Node)
    end
  end
end
