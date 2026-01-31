require "../spec_helper"

describe "RbsFileParser" do
  it "parses method signatures with return types" do
    source = File.read("spec/fixtures/annotations/rbs_simple.rbs")
    parser = Warp::Lang::Ruby::Annotations::RbsFileParser.new
    sigs = parser.parse(source)

    sigs.has_key?("User.name").should be_true
    sigs.has_key?("self.User.find").should be_true

    sigs["User.name"].return_type.should eq("String")
    sigs["self.User.find"].return_type.should eq("User")
  end
end
