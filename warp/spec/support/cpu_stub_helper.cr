module SpecHelpers
  # Helper to stub CPU detection and selector capability methods for tests.
  # Usage:
  #   with_stubbed_cpu(Warp::Parallel::CPUVendor::AMD, Warp::Parallel::Microarchitecture::Zen4, true, true) do
  #     # test code
  #   end
  def with_stubbed_cpu(vendor, microarch, can_avx512 = false, can_avx2 = false, &)
    orig_vendor = Warp::Parallel::CPUDetector.method(:detect_vendor)
    orig_micro = Warp::Parallel::CPUDetector.method(:detect_microarchitecture)
    orig_can_avx512 = Warp::Backend::Selector.method(:can_use_avx512?) rescue nil
    orig_can_avx2 = Warp::Backend::Selector.method(:can_use_avx2?) rescue nil

    begin
      Warp::Parallel::CPUDetector.define_singleton_method(:detect_vendor) { vendor }
      Warp::Parallel::CPUDetector.define_singleton_method(:detect_microarchitecture) { microarch }
      Warp::Backend::Selector.define_singleton_method(:can_use_avx512?) { can_avx512 }
      Warp::Backend::Selector.define_singleton_method(:can_use_avx2?) { can_avx2 }

      yield
    ensure
      Warp::Parallel::CPUDetector.define_singleton_method(:detect_vendor) { orig_vendor.call }
      Warp::Parallel::CPUDetector.define_singleton_method(:detect_microarchitecture) { orig_micro.call }
      if orig_can_avx512
        Warp::Backend::Selector.define_singleton_method(:can_use_avx512?) { orig_can_avx512.call }
      end
      if orig_can_avx2
        Warp::Backend::Selector.define_singleton_method(:can_use_avx2?) { orig_can_avx2.call }
      end
    end
  end
end

# Include helper methods globally in specs
include SpecHelpers
