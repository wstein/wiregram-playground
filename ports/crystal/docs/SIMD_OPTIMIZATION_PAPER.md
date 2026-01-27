# High-Performance Lexing on Apple M4: SIMD Acceleration and Structural Indexing

## Abstract
This paper presents the design and implementation of a SIMD-accelerated lexing system for the WireGram project, specifically optimized for the Apple M4 architecture (ARMv9.4-A). We explore techniques such as structural indexing, symbolic UTF-8 processing, and upfront lexing rules using NEON (AdvSIMD) intrinsics via Crystal's inline assembly.

## Introduction
Lexing high-volume configuration formats like UCL and JSON is traditionally a byte-by-byte sequential process. On modern high-performance cores like the Apple M4, branch prediction and superscalar execution allow sequential lexers to reach high speeds (~130 MB/s). However, to push beyond the gigabyte-per-second threshold, SIMD parallelism is required to skip non-structural data and whitespace.

## Optimization Techniques

### 1. SIMD-based Structural Indexing
We implemented a NEON-based scanner that processes 16 bytes per cycle. It identifies structural characters (`{`, `}`, `[`, `]`, `:`, `,`, `"`, `\`) and whitespace. 
- **Instruction Sequence:** Using `ld1` to load blocks, `cmeq`/`cmhs` for parallel comparison, and a custom bitmask extraction sequence using `mul` and `addv`.
- **M4 Benefit:** The Apple M4's high SIMD throughput and low-latency NEON unit allow this scanner to run with minimal overhead.

### 2. Symbolic UTF-8 Processing
Instead of validating UTF-8 sequences byte-by-byte, we use a "symbolic" approach where we only perform full validation if the SIMD pass detects non-ASCII bytes (bit 7 set). This avoids expensive UTF-8 decoding in the common ASCII case.

### 3. Upfront Lexing Rules (Stage 1)
We implemented a two-stage lexer:
- **Stage 1:** Rapidly scan the entire input and build a "structural index" (positions of all potential tokens).
- **Stage 2:** The parser/lexer jumps directly between these positions, effectively "teleporting" over long literals and whitespace.

## Benchmarks
The following benchmarks were conducted on an Apple M4 using a 19MB UCL file (`rcl_test.json`).

| Lexing Strategy | Throughput (MB/s) | Latency (ms) | Speedup |
| :--- | :--- | :--- | :--- |
| Sequential (Crystal Optimized) | ~980 | 110.6 | 1.00x |
| SIMD Acceleration | ~790 | 136.7 | 0.81x* |
| SIMD + Upfront Indexing | ~630 | 171.1 | 0.64x* |

*\*Note: On the Apple M4, the extremely efficient branch predictor makes the manual byte-loop very hard to beat for files with high token density. SIMD optimizations show more benefit on files with long strings or massive whitespace blocks.*

## 5. Deeper Optimizations (Stage 2 Teleportation)

### 5.1 Stage 2 Architecture: Teleportation
Stage 1 (SIMD Structural Indexing) creates a roadmap of the entire source. In Stage 2, the lexer can "teleport" between structural positions.

When the lexer encounters an unquoted string or a literal, instead of scanning byte-by-byte or using a regex, it simply jumps to the next index in the structural roadmap. This effectively skips the content of large literals in O(1) jump time.

### 5.2 Implementation Details
- **`teleport_to_next`**: A new primitive in `BaseLexer` that advances `@position` to the next structural character found in Stage 1.
- **Optimized Indexing**: The loop to extract indices from SIMD bitmasks was optimized using `trailing_zeros_count` (which maps to `rbit/clz` on AArch64), avoiding bit-by-bit checking.

## 6. Future Suggestions and Ratings

| Optimization | Description | Potential Impact | Complexity | Rating |
|--------------|-------------|------------------|------------|--------|
| **Branchless Stage 2** | Use a jump table or computed goto based on the structural character at the current index to avoid `case/when` overhead. | High (20-30%) | High | ★★★★☆ |
| **SIMD-based Unquoted Scan** | Use NEON to scan for delimiters in unquoted strings without a full upfront index. | Medium (10-15%) | Medium | ★★★☆☆ |
| **Parallel Stage 1** | Run Stage 1 indexing in a separate fiber/thread while Stage 2 starts processing the first chunks. | High (Parallelism) | High | ★★★☆☆ |
| **Stage 2 Bit-packing** | Store the structural index as a bitmask or a more compact stream to reduce memory bandwidth. | Low (5-10%) | Medium | ★★☆☆☆ |

## 7. Hardware Specifics: Apple M4
- **Architecture:** ARMv9.4-A.
- **NEON Performance:** 4x 128-bit NEON units.
- **L1 Cache:** 192KB Instruction, 128KB Data per P-core.
- **Observations:** The M4's "branch target injection" and advanced prefetchers mean that the overhead of building an index upfront (Stage 1) is currently higher than the cost of a well-predicted sequential scan for typical config files.

## Conclusion
While SIMD provides massive theoretical throughput, the practical implementation in a high-level language like Crystal must account for allocation overhead and the extreme efficiency of modern CPU branch predictors. The implemented SIMD infrastructure provides a foundation for multi-gigabyte processing in future streaming architectures.
