require "../spec_helper"

describe "InlineRbsParser" do
  it "parses inline # @rbs comments and binds to next def" do
    source = File.read("spec/fixtures/annotations/inline_rbs.rb")
    parser = Warp::Lang::Ruby::Annotations::InlineRbsParser.new
    sigs = parser.parse(source)

    sigs.has_key?("greet").should be_true
    sigs["greet"].return_type.should eq("String")
    sigs["greet"].params["arg0"].should eq("String")
    sigs["greet"].params["arg1"].should eq("Integer")
  end
end
