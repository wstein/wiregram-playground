require "../spec_helper"
require "json"

private def run_cli(*args : String) : String
  output = IO::Memory.new
  error = IO::Memory.new
  status = Process.run("crystal", ["run", "bin/warp.cr", "--"] + args.to_a, output: output, error: error)
  status.success?.should be_true
  output.to_s
end

describe "CLI dump integration" do
  it "dumps Ruby CST JSON including leading_trivia" do
    output = run_cli("dump", "cst", "-l", "ruby", "-f", "json", "spec/fixtures/cli/rb_simple.rb")
    json = JSON.parse(output)
    json["stage"].should eq("cst")
    json["language"].should eq("ruby")

    root = json["root"]
    root.should_not be_nil
    root["leading_trivia"].should_not be_nil
    root["leading_trivia"].as_a?.should_not be_nil
    root["trailing_trivia"].should_not be_nil
    root["trailing_trivia"].as_a?.should_not be_nil
  end

  it "dumps Crystal CST JSON including leading_trivia" do
    output = run_cli("dump", "cst", "-l", "crystal", "-f", "json", "spec/fixtures/cli/cr_simple.cr")
    json = JSON.parse(output)
    json["stage"].should eq("cst")
    json["language"].should eq("crystal")

    root = json["root"]
    root.should_not be_nil
    root["leading_trivia"].should_not be_nil
    root["leading_trivia"].as_a?.should_not be_nil
    root["trailing_trivia"].should_not be_nil
    root["trailing_trivia"].as_a?.should_not be_nil
  end
end
