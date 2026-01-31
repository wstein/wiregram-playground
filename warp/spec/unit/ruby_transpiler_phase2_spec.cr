require "../spec_helper"

describe "Ruby Annotation Extraction (Phase 2)" do
  it "extracts sig blocks and method names" do
    source = <<-RUBY
    sig { params(x: String).returns(Integer) }
    def greet(x)
      x.length
    end
    RUBY

    bytes = source.to_slice
    tokens, err = Warp::Lang::Ruby::Lexer.scan(bytes)
    err.should eq(Warp::Core::ErrorCode::Success)

    extractor = Warp::Lang::Ruby::Annotations::AnnotationExtractor.new(bytes, tokens)
    sigs = extractor.extract
    sigs.size.should eq(1)
    sigs[0].method_name.should eq("greet")
  end

  it "generates inline RBS comments" do
    source = <<-RUBY
    sig { params(x: String).returns(Integer) }
    def greet(x)
      x.length
    end
    RUBY

    bytes = source.to_slice
    tokens, err = Warp::Lang::Ruby::Lexer.scan(bytes)
    err.should eq(Warp::Core::ErrorCode::Success)

    extractor = Warp::Lang::Ruby::Annotations::AnnotationExtractor.new(bytes, tokens)
    sigs = extractor.extract
    output = Warp::Lang::Ruby::Annotations::InlineRbsInjector.inject(source, sigs)
    output.should contain("# @rbs (String) -> Integer")
  end
end
