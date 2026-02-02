require "../spec_helper"
require "json"

private def run_warp_cli(args : Array(String)) : Tuple(String, String, Process::Status)
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  status = Process.run("crystal", ["run", "bin/warp.cr", "--"] + args, output: stdout, error: stderr)
  {stdout.to_s, stderr.to_s, status}
end

describe "warp dump CLI" do
  it "dumps SIMD stream for JSON" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "simd", "--lang", "json", "spec/fixtures/cli/sample.json"])
    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("SIMD structural indices").should be_true
  end

  it "dumps tokens with auto language detection" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "tokens", "--lang", "auto", "spec/fixtures/cli/rb_simple.rb"])
    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("Tokens (ruby)").should be_true
  end

  it "dumps Ruby tape entries" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "tape", "--lang", "ruby", "spec/fixtures/cli/rb_simple.rb"])
    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("Tape (ruby)").should be_true
    stdout_text.includes?("MethodDef").should be_true
  end

  it "dumps JSON CST as JSON" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "cst", "-l", "json", "-f", "json", "spec/fixtures/cli/sample.json"])
    status.success?.should be_true
    stderr_text.empty?.should be_true
    parsed = JSON.parse(stdout_text)
    parsed["stage"].as_s.should eq("cst")
    parsed["language"].as_s.should eq("json")
    parsed["root"].as_h.should_not be_nil
  end

  it "dumps JSON AST with auto detection" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "ast", "spec/fixtures/cli/sample.json"])
    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("AST (json)").should be_true
  end

  it "dumps full pipeline output" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "full", "spec/fixtures/cli/rb_simple.rb"])
    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("Full dump").should be_true
    stdout_text.includes?("== tokens ==").should be_true
    stdout_text.includes?("== ast ==").should be_true
  end
end
