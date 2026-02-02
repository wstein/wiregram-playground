require "../spec_helper"

describe "CLI Integration" do
  it "transpiles Crystal -> Ruby using CLI with stdout" do
    fixture_dir = "spec/fixtures/cli"
    cmd = ["crystal", "run", "bin/warp.cr", "--", "transpile", "ruby", "-s", fixture_dir, "--stdout"].join(" ")

    out = %x(#{cmd})

    out.includes?("sig {").should eq(true)
    out.includes?("def greet").should eq(true)
  end

  it "transpiles Ruby -> Crystal using CLI with stdout" do
    fixture_dir = "spec/fixtures/cli"
    cmd = ["crystal", "run", "bin/warp.cr", "--", "transpile", "crystal", "-s", fixture_dir, "--stdout"].join(" ")

    out = %x(#{cmd})

    # Should output Crystal code containing def or raw text
    out.includes?("def add").should eq(true)
  end

  it "prints a startup summary when verbose or parallel workers are enabled" do
    fixture_dir = "spec/fixtures/cli"
    # Force parallel to a known value and enable verbose to trigger the summary
    cmd = ["crystal", "run", "bin/warp.cr", "--", "transpile", "ruby", "-s", fixture_dir, "-v", "--parallel=10"].join(" ")

    out = %x(#{cmd})

    # The summary should include config info, CPU summary (with P/E counts and SIMD counts) and the worker count
    out.includes?("Using config:").should eq(true)
    out.includes?("CPU:").should eq(true)
    out.includes?("P-cores:").should eq(true)
    out.includes?("E-cores:").should eq(true)
    out.includes?("NEON:").should eq(true)
    out.includes?("Using").should eq(true)
    out.includes?("parallel").should eq(true)
  end
end
