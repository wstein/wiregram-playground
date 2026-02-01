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
end
