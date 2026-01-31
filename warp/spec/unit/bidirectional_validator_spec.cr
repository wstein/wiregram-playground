require "../spec_helper"

describe "BidirectionalValidator" do
  it "round-trips Ruby -> Crystal -> Ruby" do
    source = <<-RB
      sig { params(x: Integer).returns(Integer) }
      def add(x)
        x + 1
      end
    RB

    result = Warp::Testing::BidirectionalValidator.ruby_to_crystal_to_ruby(source)
    result.success.should eq(true)
    result.output.should contain("def add")
  end

  it "round-trips Crystal -> Ruby -> Crystal" do
    source = <<-CR
      def greet(name : String) : String
        "hello \#{name}"
      end
    CR

    result = Warp::Testing::BidirectionalValidator.crystal_to_ruby_to_crystal(source)
    result.success.should eq(true)
    result.output.should contain("def greet")
  end
end
