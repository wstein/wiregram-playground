# Phase 0 Research: WireGram — MVP Decisions

**Feature**: WireGram — Universal Code Tooling Factory
**Branch**: 001-wiregram-framework
**Run date**: 2026-01-23

## Summary

This research document records the decisions for the MVP technical choices and the research tasks to validate them. The team selected **Ruby** and **Crystal** as initial target languages. The chosen strategies are:

- Lexer: use **builtin regex** engines in Ruby and Crystal for tokenization, with explicit support for preserving leading/trailing trivia.
- Parser: implement **RD (recursive-descent)** parsers per target runtime, tailored for error tolerance and concrete syntax preservation.

## Decisions

1. Decision: Lexer implementation will be **runtime builtin regex-based** for Ruby and Crystal.
   - Rationale: Both languages provide highly optimized regex implementations; using builtin regex enables idiomatic tokenizers, easier implementation in the target language, and good performance with minimal C-API bridging.
   - Alternatives considered: Hand-written DFA lexers, generator-produced DFA (increased complexity), or third-party lexing libraries. Rejected because they increase implementation complexity and reduce parity with idiomatic runtime code.

2. Decision: Parser implementation strategy is **RD (recursive-descent)**.
   - Rationale: RD parsers provide clear mapping between grammar productions and implementation, are easy to debug, and support error tolerance and precise trivia propagation more straightforwardly than generated table parsers for the research scope.
   - Alternatives considered: Parser generators (LR/LALR/GLR) and PEG parsers. Rejected for MVP due to complexity in preserving concrete syntax and trivia, and poorer error recovery characteristics for our needs.

3. Decision: MVP languages are **Ruby + Crystal** (dynamic + static pair).
   - Rationale: Validates cross-paradigm concerns early and reduces risk in research claims about language-agnostic runtime properties.

4. Decision (pending): **Generator implementation language** — Research will evaluate Rust vs Crystal vs hybrid approaches.
   - Rationale: Rust offers performance and a rich ecosystem; Crystal could offer faster iteration if team prefers a single-language stack; hybrid approaches may balance development speed and runtime performance. This is an actionable Phase 0 task.

## Research Tasks (R1–R5)

- R1: Lexer Prototypes (Ruby & Crystal) — **IN PROGRESS**
  - Implement minimal regex-based tokenizers for a MiniLang grammar that preserve leading/trailing trivia.
  - Measure tokenization throughput on representative files (small → 1MB) and record artifacts.
  - Deliverable: `research/lexer-prototype/` with code, micro-benchmarks, and notes. (scaffolded)

- R2: RD Parser Prototype — **IN PROGRESS**
  - Implement a small RD parser for MiniLang that demonstrates error recovery, AST + concrete node preservation, and idempotent printing.
  - Tests: round-trip parse → print → parse results equivalence over test corpus.
  - Deliverable: `research/parser-prototype/` with tests and sample corpora. (scaffolded)

- R3: Generator Language Evaluation
  - Build small PoCs: one in Rust and one in Crystal (or hybrid) that generate Ruby and Crystal runtime code for a small grammar.
  - Compare development ergonomics, binary size, and cross-compilation concerns.
  - Deliverable: recommendation document: `research/generator-language.md` with tradeoffs.

- R4: Contract & LSP Integration Design
  - Define testable contracts for LSP interactions, linter report JSON schema, and benchmark artifact schema.
  - Deliverable: `specs/001-wiregram-framework/contracts/` initial schemas and example messages.

- R5: Benchmark Plan
  - Define reference hardware, dataset, measurement procedure, warm-up cycles, and artifact storage layout (prefer reproducible builds and metadata capture).
  - Deliverable: `research/benchmark-plan.md` with commands to reproduce measurements.


- R3: Generator Language Evaluation
  - Build small PoCs: one in Rust and one in Crystal (or hybrid) that generate Ruby and Crystal runtime code for a small grammar.
  - Compare development ergonomics, binary size, and cross-compilation concerns.
  - Deliverable: recommendation document: `research/generator-language.md` with tradeoffs.

- R4: Contract & LSP Integration Design
  - Define testable contracts for LSP interactions, linter report JSON schema, and benchmark artifact schema.
  - Deliverable: `specs/001-wiregram-framework/contracts/` initial schemas and example messages.

- R5: Benchmark Plan
  - Define reference hardware, dataset, measurement procedure, warm-up cycles, and artifact storage layout (prefer reproducible builds and metadata capture).
  - Deliverable: `research/benchmark-plan.md` with commands to reproduce measurements.

## Acceptance Criteria for Phase 0

- R1 and R2 prototypes demonstrate feasibility and pass their respective tests.
- R3 delivers a clear recommendation for generator implementation language.
- R4 provides contract skeletons to be used in Phase 1 design.
- R5 establishes benchmark procedures and expected artifact formats.

## Risks & Mitigations

- Risk: Using regex-based lexers might be insufficient for some languages' lexing needs. Mitigation: Prototype and measure on realistic corpus and fallback to small DFA engine if necessary.
- Risk: RD parser performance for large grammars. Mitigation: Profile and optimize hot paths; consider partial table-based parsing for performance-critical productions if needed.

---

Next: Run the Phase 0 prototypes (R1–R3) and produce the deliverables above. When prototypes validate choices, proceed to Phase 1 design and generate `data-model.md`, `quickstart.md`, and `contracts/` artifacts.
