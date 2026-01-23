# Feature Specification: WireGram — Universal Code Tooling Factory

**Feature Branch**: `001-wiregram-framework`  
**Created**: 2026-01-23  
**Status**: Draft  
**Input**: User description: "WireGram is a universal, high-fidelity framework for generating the complete lifecycle of code analysis tools from a single declarative definition. It is not just a parser generator; it is a factory for Language Servers (LSP), Model Context Protocol (MCP) providers, formatters, linters, and auto-fixers. By defining a language grammar once in a .wg (UCL) file, WireGram generates a hardware-accelerated, error-tolerant runtime capable of understanding and manipulating source code structure. Current compiler frontends are fragmented; parsers often discard 'trivia' (comments, whitespace) making them unsafe for automated refactoring, while linters and LSPs are often built on disparate, slow, or ad-hoc regex engines. WireGram unifies these domains and democratizes production-grade developer tooling."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generate working LSP + Formatter (Priority: P1)

A language designer provides a `.wg` grammar for a simple imperative language (MiniLang) and uses WireGram to generate an LSP server and a formatter. The generated artifacts are integrated into an editor and a CI validation pipeline.

**Why this priority**: Delivering a working LSP and formatter proves the core end-to-end workflow (grammar → editor tooling) and demonstrates preservation of trivia (comments/whitespace) and correctness for refactor and format operations.

**Independent Test**: Using a provided MiniLang `.wg`, run the generator to produce LSP and formatter artifacts. Validate via:

- Editor integration test: basic LSP requests (hover, goto-definition, completion) respond correctly on a sample corpus.
- Formatting test: Formatter produces idempotent output for the corpus and preserves comments/trivia.

**Acceptance Scenarios**:

1. **Given** a valid `.wg` and sample repository, **When** the generator runs, **Then** it outputs an LSP bundle and a formatter binary/library.
2. **Given** code with comments and whitespace, **When** the formatter runs repeatedly, **Then** the output stabilizes (second run yields identical file contents) and comments are preserved.

---

### User Story 2 - Linter + Safe Auto-Fixer (Priority: P2)

A tool author uses the same `.wg` to generate a linter with a set of provable, semantics-preserving auto-fixes and a report format that can be consumed by CI.

**Why this priority**: Quality tooling (lint + auto-fix) increases adoption and proves that transformations are safe for automated remediation.

**Independent Test**: Run linter + auto-fix across a test corpus with seeded violations. Verify that: linter detects expected issues, auto-fix applies deterministic changes, and a round-trip check (parse → transform → print → parse) yields equivalent semantics for fixed files.

**Acceptance Scenarios**:

1. **Given** a corpus with seeded rule violations, **When** the linter runs, **Then** it emits a structured report with rule IDs and locations.
2. **Given** the same corpus and auto-fix enabled, **When** fixes are applied, **Then** the transformed files pass the parity check (semantics-preserving validation harness).

---

### User Story 3 - Reproducible Benchmarking & Experiment Artifacts (Priority: P3)

A researcher runs a benchmark suite for the generated runtime on a representative corpus and records reproducible performance measurements and artifacts.

**Why this priority**: Performance and reproducibility are core research requirements; benchmarks support claims about hardware acceleration and correctness at scale.

**Independent Test**: Execute the benchmark harness shipped with the generated runtime. Validate that results are reproducible (repeated runs within acceptable variance) and that the artifacts (raw traces, summary reports) are archived alongside the feature's documentation.

**Acceptance Scenarios**:

1. **Given** benchmark input files and hardware profile, **When** the benchmark runs, **Then** it produces a reproducible summary report and storeable artifacts.
2. **Given** a performance regression, **When** comparing baseline and new runs, **Then** the CI flags the regression and links the benchmark artifacts for investigation.

---

### Edge Cases

- Partial or invalid input sources (e.g., truncated files) should produce a best-effort partial AST and usable editor diagnostics (error-tolerant parsing).
- Extremely large files (multi-megabyte) should be processed incrementally and within defined performance constraints (see Success Criteria).
- Ambiguous grammars: generator MUST detect ambiguous productions and provide clear diagnostics and actionable guidance.
- Mixed-language files: must preserve content outside the language fragment and only operate on recognized fragments.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST accept a `.wg` grammar and generate the following artifacts (configurable per run): LSP server, formatter, linter (with auto-fix), and an optional MCP provider.
- **FR-002**: Parsers MUST be **error-tolerant** and preserve all trivia (comments, whitespace) such that formatting and automated fixes preserve developer intent.
- **FR-003**: The formatter MUST be **idempotent**: running it twice on the same file yields identical output for ≥99% of the verified test corpus.
- **FR-004**: Generated linters MUST report structured findings with rule IDs and allow deterministic auto-fixes when a fix is provably semantics-preserving.
- **FR-005**: The generator MUST include a reproducible benchmark harness and a documented performance profile for each generated runtime.
- **FR-006**: Output artifacts MUST include tests (contract/behavioral tests) that validate core features (parse, format, lint, LSP interactions) against a seeded corpus.
- **FR-007**: Documentation for the language and generated artifacts MUST be produced in **arc42** Asciidoc form and placed in `docws/modules/ROOT/pages` with quickstarts and benchmark reproduction steps.
- **FR-008**: The tool MUST provide both a CLI and a library API (language bindings optional) for integration into CI and editor workflows.
- **FR-009**: Configurations and metadata SHOULD prefer `.yaml` extensions when applicable.
- **FR-010**: Lexer implementations for Ruby and Crystal MUST use the language's builtin regex engines and explicitly preserve leading/trailing trivia. Parser implementations MUST follow an RD (recursive-descent) design that supports error-tolerant parsing and concrete syntax preservation.

### Assumptions & Clarifications

- **Assumption**: Initial runtime implementation targets CPU-only execution with a design that can be extended to hardware accelerators later.
- **Decision (MVP target languages)**: **Ruby and Crystal** This provides a cross-paradigm initial validation set: Ruby (dynamic) and Crystal (static). Implications:
  - Provide test corpora and property-tests for both languages.
  - Acceptance tests and verification harnesses must validate generated artifacts for both languages.
  - Benchmarks and performance profiles must include runs for both languages and be recorded as benchmark artifacts.
  - Scope increases compared to a single-language MVP but yields stronger cross-language confidence and earlier detection of cross-paradigm issues.

### Key Entities *(include if feature involves data)*

- **WG Grammar**: The `.wg` UCL grammar definition; canonical source for generation.
- **Token**: Lexical token with attached trivia (leading/trailing comments, whitespace).
- **AST (Concrete + Abstract)**: Representations produced by the parser; preserved trivia in concrete nodes.
- **Generated Artifact**: LSP bundle, formatter, linter, MCP provider, test harness, and benchmark artifacts.
- **BenchmarkReport**: Serialized performance summary (p95/p99, variance, environment metadata).
- **TestCorpus**: Seeded example programs and property tests for validation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For **Ruby** and **Crystal** reference corpora generated from valid `.wg` grammars, WireGram produces functioning LSP and formatter artifacts that pass the provided behavioral test-suite (pass rate ≥ 95%) within a single CI run.
- **SC-002**: Formatter idempotence: For the verification corpus, at least **99%** of files are unchanged after a second formatting run.
- **SC-003**: Trivia preservation: Round-trip parse → transform → print retains developer-visible comments/trivia for ≥ 99% of the tests in the verification corpus.
- **SC-004**: Performance: For files up to 1MB, parse+basic analysis p95 completes under **500ms** on supported reference hardware (documented in benchmark artifacts).
- **SC-005**: Reproducibility: Repeated benchmark runs on the same hardware show variance within **±5%** for p95 measurements.

## Documentation & Governance *(mandatory)*

- **Documentation MUST** follow the **arc42** structure using **Asciidoc** and be placed in `docws/modules/ROOT/pages` to align with Antora site layout.
- **Major architectural decisions MUST** be captured as RFCs and ADRs in `docs/rfc/` and `docs/adr/` and meeting notes in `docs/minutes/`.
- **YAML files SHOULD** use the `.yaml` extension when possible for consistency.
- **Tests & acceptance criteria MUST** be present in the "User Scenarios & Testing" section and be independently executable.

---

### Clarifications Resolved

- **MVP target languages**: **Ruby** and **Crystal** This defines the initial verification matrix and test corpora; both languages will be included in acceptance tests and benchmark runs. Scope increases compared to a single-language MVP but provides better cross-paradigm validation.
