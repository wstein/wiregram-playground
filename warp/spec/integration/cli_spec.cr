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

  it "preserves newlines when transpiling Ruby to Crystal" do
    fixture_file = "spec/fixtures/cli/rb_simple.rb"
    cmd = ["crystal", "run", "bin/warp.cr", "--", "transpile", "crystal", "-s", fixture_file, "--stdout"].join(" ")

    out = %x(#{cmd})

    # Output should contain newlines, not all concatenated
    # Count lines - should be at least 4 for a simple multi-line function
    line_count = out.lines.size
    line_count.should be > 3

    # Should preserve structure
    out.includes?("def ").should eq(true)
    out.includes?("end").should eq(true)
  end

  it "preserves newlines when transpiling Crystal to Ruby" do
    fixture_file = "spec/fixtures/cli/cr_simple.cr"
    cmd = ["crystal", "run", "bin/warp.cr", "--", "transpile", "ruby", "-s", fixture_file, "--stdout"].join(" ")

    out = %x(#{cmd})

    # Output should contain newlines, not all concatenated
    line_count = out.lines.size
    line_count.should be > 2

    # Should preserve structure
    out.includes?("def ").should eq(true)
    out.includes?("end").should eq(true)
  end
end
