CPU Stub Helper

`with_stubbed_cpu(vendor, microarch, can_avx512 = false, can_avx2 = false)`

- vendor: `Warp::Parallel::CPUVendor` (e.g., `AMD`, `Intel`, `Unknown`)
- microarch: `Warp::Parallel::Microarchitecture` (e.g., `Zen4`, `Zen5`, `IceLake`)
- can_avx512: Bool - Whether selector should report AVX-512 available
- can_avx2: Bool - Whether selector should report AVX2 available

Usage example:

```crystal
with_stubbed_cpu(Warp::Parallel::CPUVendor::AMD, Warp::Parallel::Microarchitecture::Zen4, true, true) do
  backend = Warp::Backend::Selector.select
  # assert expectations
end
```

The helper restores original methods after the block to avoid polluting other tests.
