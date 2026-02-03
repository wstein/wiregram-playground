require "../spec_helper"

describe "SIMD alignment checks" do
  it "reports SimdAlignmentError when strict mode is enabled and offset not aligned" do
    ENV["WARP_ALIGNMENT_MODE"] = "strict"
    ENV["WARP_ALIGNMENT_BYTES"] = "16"
    backend = Warp::Backend.current
    err = backend.check_alignment_offset(1)
    err.should eq(Warp::Core::ErrorCode::SimdAlignmentError)
    ENV.delete("WARP_ALIGNMENT_MODE")
    ENV.delete("WARP_ALIGNMENT_BYTES")
  end

  it "succeeds when offset is aligned or strict mode disabled" do
    backend = Warp::Backend.current
    err = backend.check_alignment_offset(0)
    err.should eq(Warp::Core::ErrorCode::Success)
  end

  it "honors warn mode without failing" do
    ENV["WARP_ALIGNMENT_MODE"] = "warn"
    ENV["WARP_ALIGNMENT_BYTES"] = "32"
    backend = Warp::Backend.current
    err = backend.check_alignment_offset(1)
    err.should eq(Warp::Core::ErrorCode::Success)
    ENV.delete("WARP_ALIGNMENT_MODE")
    ENV.delete("WARP_ALIGNMENT_BYTES")
  end

  it "resets SIMD scanners for reuse" do
    bytes = "puts 'hi'".to_slice

    ruby_scanner = Warp::Lang::Ruby::SimdScanner.new(bytes)
    ruby_scanner.scan
    ruby_scanner.reset
    ruby_scanner.error.should eq(Warp::Core::ErrorCode::Success)

    crystal_scanner = Warp::Lang::Crystal::SimdScanner.new(bytes)
    crystal_scanner.scan
    crystal_scanner.reset
    crystal_scanner.error.should eq(Warp::Core::ErrorCode::Success)
  end
end
