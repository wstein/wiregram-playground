# simdjson (Crystal)

ARM64-focused JSON parsing scaffolding for Apple Silicon (M-series).

This project provides:
- A zero-copy, slice-based token iterator in Crystal.
- SIMD-accelerated stage1 on AArch64 via NEON

## Build

Build the Crystal side:

```
crystal build bin/bench.cr
```

Run the benchmark (`--release` for higher throughput):

```
./bin/bench [options] <json file> [json file...]
```
Options:
- `--release`: re-run with `crystal --release`.
- `--profile`: report stage1/stage2 timings (runs both stages).
Multiple files are parsed in parallel automatically.

Note: the CLI no longer displays an interactive progress bar during parallel runs to avoid contention; use `--verbose` to print worker and system allocation details.

Example:

```
./bin/bench --release ~/Downloads/twitter.json big.json big2.json
```

## Coverage

Crystal 1.19 does not expose built-in coverage in `crystal spec`. Use kcov:

```
./scripts/coverage_kcov
```


## Usage

```crystal
require "./src/simdjson"

bytes = File.read("data.json").to_slice
parser = Simdjson::Parser.new
parser.each_token(bytes) do |tok|
  # tok.type, tok.start, tok.length
  # tok.slice(bytes) returns a zero-copy slice
end

doc_result = parser.parse_document(bytes, validate_literals: true, validate_numbers: true)
if doc_result.error.success?
  doc = doc_result.doc
  iter = doc.not_nil!.iterator
  iter.each do |entry|
    # entry.type and iter.slice(entry) for zero-copy access
  end
end
```

Notes:
- The current Crystal parser is a zero-copy token iterator. It does not build a DOM.
- String values are returned as raw JSON slices (quotes stripped) without unescaping.
- Stage1 uses Crystal NEON asm on AArch64 with a scalar fallback for non-AArch64 builds.
- UTF-8 is validated during stage1; set `SIMDJSON_VERIFY_NEON=1` to cross-check SIMD masks with scalar for debugging (slower).
- Stage2 builds a zero-copy tape without unescaping or number conversion.
- Literal/number validation is optional and can be enabled per-parse without copying.

Limitations:
- No string unescape yet.
- No DOM builder yet; you get a token stream based on structural indexes.
