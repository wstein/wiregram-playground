require "../spec_helper"

# Integration tests for Phase 1 CST-to-CST pipeline
describe "CST-to-CST Transpiler (Phase 1)" do
  it "emits identical output for unchanged input" do
    source = <<-RUBY
    # frozen_string_literal: true
    class Example
      def greet(name)
        "Hello, " + name
      end
    end
    RUBY

    result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    result.output.should eq(source)
  end

  it "handles empty input" do
    result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile("".to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    result.output.should eq("")
  end

  it "returns a Crystal CST document" do
    source = "def hello\n  'world'\nend\n"
    result = Warp::Lang::Ruby::CSTToCSTTranspiler.transpile(source.to_slice)
    result.error.should eq(Warp::Core::ErrorCode::Success)
    result.crystal_doc.should_not be_nil
  end
end
