require "../spec_helper"

describe Warp::Backend::Selector do
  it "selects scalar backend when override is set" do
    previous = ENV["WARP_BACKEND"]?
    begin
      ENV["WARP_BACKEND"] = "ScAlAr"
      backend = Warp::Backend::Selector.select
      backend.should be_a(Warp::Backend::ScalarBackend)
    ensure
      if previous
        ENV["WARP_BACKEND"] = previous
      else
        ENV.delete("WARP_BACKEND")
      end
    end
  end

  it "resolves backend by name via the public API" do
    backend = Warp::Backend.select_by_name("scalar")
    backend.should be_a(Warp::Backend::ScalarBackend)
  end

  it "falls back to the default backend for unknown overrides" do
    previous = ENV["WARP_BACKEND"]?
    begin
      ENV["WARP_BACKEND"] = "unknown"
      backend = Warp::Backend::Selector.select
      {% if flag?(:aarch64) %}
        backend.should be_a(Warp::Backend::NeonBackend)
      {% else %}
        backend.should be_a(Warp::Backend::ScalarBackend)
      {% end %}
    ensure
      if previous
        ENV["WARP_BACKEND"] = previous
      else
        ENV.delete("WARP_BACKEND")
      end
    end
  end

  it "accepts SIMDJSON_BACKEND as an override source" do
    previous = ENV["SIMDJSON_BACKEND"]?
    begin
      ENV["SIMDJSON_BACKEND"] = "scalar"
      backend = Warp::Backend::Selector.select
      backend.should be_a(Warp::Backend::ScalarBackend)
    ensure
      if previous
        ENV["SIMDJSON_BACKEND"] = previous
      else
        ENV.delete("SIMDJSON_BACKEND")
      end
    end
  end

  {% if flag?(:aarch64) %}
  it "selects neon backend when explicitly requested" do
    previous = ENV["WARP_BACKEND"]?
    begin
      ENV["WARP_BACKEND"] = "neon"
      backend = Warp::Backend::Selector.select
      backend.should be_a(Warp::Backend::NeonBackend)
    ensure
      if previous
        ENV["WARP_BACKEND"] = previous
      else
        ENV.delete("WARP_BACKEND")
      end
    end
  end
  {% end %}
end

describe Warp::Backend::ScalarBackend do
  it "supports lexing when forced as the current backend" do
    backend = Warp::Backend::ScalarBackend.new
    Warp::Backend.reset(backend)
    bytes = %({"a":1,"b":[true,false]}).to_slice
    result = Warp::Lexer.index(bytes)
    result.error.should eq(Warp::ErrorCode::Success)
  ensure
    Warp::Backend.reset
  end

  it "builds masks for control, whitespace, op, quote, and backslash bytes" do
    backend = Warp::Backend::ScalarBackend.new
    bytes = Bytes['{'.ord.to_u8, ' '.ord.to_u8, '\n'.ord.to_u8, '"'.ord.to_u8,
                  '\\'.ord.to_u8, 0x01_u8, 'a'.ord.to_u8, ']'.ord.to_u8]
    masks = backend.build_masks(bytes.to_unsafe, bytes.size)

    (masks.op & (1_u64 << 0)).should_not eq(0_u64)
    (masks.op & (1_u64 << 2)).should_not eq(0_u64)
    (masks.op & (1_u64 << 7)).should_not eq(0_u64)
    (masks.whitespace & (1_u64 << 1)).should_not eq(0_u64)
    (masks.quote & (1_u64 << 3)).should_not eq(0_u64)
    (masks.backslash & (1_u64 << 4)).should_not eq(0_u64)
    (masks.control & (1_u64 << 5)).should_not eq(0_u64)
    ((masks.whitespace >> bytes.size) != 0_u64).should be_true
  end
end
