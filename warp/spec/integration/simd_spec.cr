require "../spec_helper"
require "json"

private def run_warp_cli(args : Array(String)) : Tuple(String, String, Process::Status)
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  status = Process.run("crystal", ["run", "bin/warp.cr", "--"] + args, output: stdout, error: stderr)
  {stdout.to_s, stderr.to_s, status}
end

describe "SIMD scanning via dump CLI" do
  it "outputs SIMD structural indices for JSON" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "simd", "--lang", "json", "spec/fixtures/cli/sample.json"])

    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("SIMD structural indices").should be_true
    stdout_text.includes?("json").should be_true
  end

  it "outputs enhanced SIMD structural indices for JSON" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "simd", "--lang", "json", "--enhanced", "spec/fixtures/cli/sample.json"])

    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("SIMD structural indices").should be_true
    stdout_text.includes?("json").should be_true
  end

  it "outputs SIMD timing in JSON when perf enabled" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "simd", "--lang", "json", "--format", "json", "--perf", "spec/fixtures/cli/sample.json"])

    status.success?.should be_true
    stderr_text.empty?.should be_true

    data = JSON.parse(stdout_text).as_h
    data["elapsed_ms"].should_not be_nil
  end

  it "outputs SIMD structural indices for Ruby" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "simd", "--lang", "ruby", "spec/fixtures/cli/rb_simple.rb"])

    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("SIMD structural indices").should be_true
    stdout_text.includes?("ruby").should be_true
  end

  it "outputs SIMD structural indices for Crystal" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "simd", "--lang", "crystal", "src/warp.cr"])

    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("SIMD structural indices").should be_true
    stdout_text.includes?("crystal").should be_true
  end

  it "outputs SIMD data as JSON for Ruby" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "simd", "--lang", "ruby", "--format", "json", "spec/fixtures/cli/rb_simple.rb"])

    status.success?.should be_true
    stderr_text.empty?.should be_true

    begin
      data = JSON.parse(stdout_text).as_h
      data["indices"].as_a.size.should be > 0
    rescue JSON::ParseException
      fail "Output should be valid JSON"
    end
  end

  it "outputs SIMD data as JSON for Crystal" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "simd", "--lang", "crystal", "--format", "json", "src/warp.cr"])

    status.success?.should be_true
    stderr_text.empty?.should be_true

    begin
      data = JSON.parse(stdout_text).as_h
      data["indices"].as_a.size.should be > 0
    rescue JSON::ParseException
      fail "Output should be valid JSON"
    end
  end

  it "handles full pipeline dump with SIMD for Ruby" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "full", "--lang", "ruby", "--format", "pretty", "spec/fixtures/cli/rb_simple.rb"])

    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("== simd ==").should be_true
    stdout_text.includes?("SIMD structural indices").should be_true
  end

  it "handles full pipeline dump with SIMD for Crystal" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "full", "--lang", "crystal", "--format", "pretty", "src/warp.cr"])

    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("== simd ==").should be_true
    stdout_text.includes?("SIMD structural indices").should be_true
  end
end
