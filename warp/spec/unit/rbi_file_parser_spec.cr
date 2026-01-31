require "../spec_helper"

describe "RbiFileParser" do
  it "parses sig blocks in RBI files" do
    source = File.read("spec/fixtures/annotations/rbi_simple.rbi")
    parser = Warp::Lang::Ruby::Annotations::RbiFileParser.new
    sigs = parser.parse(source)

    sigs.has_key?("name").should be_true
    sigs["name"].return_type.should eq("String")
  end
end
