require "../spec_helper"

describe "SIMD alignment checks" do
  it "reports SimdAlignmentError when strict mode is enabled and offset not aligned" do
    ENV["WARP_STRICT_ALIGNMENT"] = "1"
    backend = Warp::Backend.current
    err = backend.check_alignment_offset(1)
    err.should eq(Warp::Core::ErrorCode::SimdAlignmentError)
    ENV.delete("WARP_STRICT_ALIGNMENT")
  end

  it "succeeds when offset is aligned or strict mode disabled" do
    backend = Warp::Backend.current
    err = backend.check_alignment_offset(0)
    err.should eq(Warp::Core::ErrorCode::Success)
  end
end
