require "../spec_helper"
require "json"

describe "CLI dump integration" do
  it "dumps Ruby CST JSON including leading_trivia" do
    out = IO.popen("crystal run bin/warp.cr -- dump cst -l ruby -f json spec/fixtures/cli/rb_simple.rb", "r") { |io| io.read }
    json = JSON.parse(out)
    json["stage"].should eq("cst")
    json["language"].should eq("ruby")

    root = json["root"]
    root.should_not be_nil
    root["leading_trivia"].should_not be_nil
    root["leading_trivia"].is_a?(::Array).should be_true
  end

  it "dumps Crystal CST JSON including leading_trivia" do
    out = IO.popen("crystal run bin/warp.cr -- dump cst -l crystal -f json spec/fixtures/cli/cr_simple.cr", "r") { |io| io.read }
    json = JSON.parse(out)
    json["stage"].should eq("cst")
    json["language"].should eq("crystal")

    root = json["root"]
    root.should_not be_nil
    root["leading_trivia"].should_not be_nil
    root["leading_trivia"].is_a?(::Array).should be_true
  end
end
