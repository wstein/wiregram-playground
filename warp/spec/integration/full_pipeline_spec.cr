require "../spec_helper"
require "json"

private def run_warp_cli(args : Array(String)) : Tuple(String, String, Process::Status)
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  status = Process.run("crystal", ["run", "bin/warp.cr", "--"] + args, output: stdout, error: stderr)
  {stdout.to_s, stderr.to_s, status}
end

describe "Full pipeline dump (simd -> tokens -> tape -> cst)" do
  it "runs full pipeline for Ruby corpus sample" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "full", "--lang", "ruby", "spec/fixtures/cli/rb_simple.rb"])

    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("== simd ==").should be_true
    stdout_text.includes?("== tokens ==").should be_true
    stdout_text.includes?("== tape ==").should be_true
    stdout_text.includes?("== cst ==").should be_true
  end

  it "runs full pipeline for Crystal sample" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "full", "--lang", "crystal", "src/warp.cr"])

    status.success?.should be_true
    stderr_text.empty?.should be_true
    stdout_text.includes?("== simd ==").should be_true
    stdout_text.includes?("== tokens ==").should be_true
    stdout_text.includes?("== tape ==").should be_true
    stdout_text.includes?("== cst ==").should be_true
  end

  it "emits JSON stages for Ruby" do
    stdout_text, stderr_text, status = run_warp_cli(["dump", "full", "--lang", "ruby", "--format", "json", "spec/fixtures/cli/rb_simple.rb"])

    status.success?.should be_true
    stderr_text.empty?.should be_true
    data = JSON.parse(stdout_text).as_h
    data["stages"].as_h["simd"].should_not be_nil
    data["stages"].as_h["tokens"].should_not be_nil
    data["stages"].as_h["tape"].should_not be_nil
    data["stages"].as_h["cst"].should_not be_nil
  end
end
