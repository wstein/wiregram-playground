# Implementation Plan: WireGram — Universal Code Tooling Factory

**Branch**: `001-wiregram-framework` | **Date**: 2026-01-23 | **Spec**: `specs/001-wiregram-framework/spec.md`
**Input**: Feature specification from `/specs/001-wiregram-framework/spec.md`

**Note**: This plan follows the project constitution; it specifies technical choices for the MVP: Ruby + Crystal lexers using builtin regex engines and RD (recursive-descent) parsers.

## Summary

WireGram generates production‑grade developer tooling (LSP, formatter, linter, MCP provider, test harness) from a single `.wg` grammar. For the MVP we will validate cross‑paradigm generation by targeting **Ruby (dynamic)** and **Crystal (static)** runtimes. Lexers will use each runtime's builtin regex capabilities for high‑quality tokenization and trivia preservation; parsers will be implemented as **RD (recursive‑descent)** parsers capable of error‑tolerant parsing and preserving concrete syntax including trivia. Deliverables include generator backends for Ruby and Crystal, behavioral tests, benchmark harness, arc42 docs, and RFC/ADR artifacts.

## Technical Context

**Language/Version**: Ruby >= 3.4 (runtime), Crystal >= 1.19 (runtime). **Generator implementation language**: NEEDS CLARIFICATION — candidate options include Rust (performance and ecosystem) or Crystal (single-language) — Phase 0 will decide.

**Primary Dependencies**: Ruby Regexp and Crystal Regex for lexer; generator tooling libs (templating for backends); JSON-RPC library for LSP; benchmark harness library.

**Storage**: N/A for runtime; artifacts and benchmarks stored in `benchmarks/` and `artifacts/` directories.

**Testing**: RSpec (Ruby), Crystal Spec (Crystal), contract tests in tests/contract, integration tests for LSP interactions in tests/integration. Include property-based tests for transformation correctness.

**Target Platform**: Linux x86_64 and macOS (CI and developer machines).

**Project Type**: Single monorepo with `generator/` and `backends/{ruby,crystal}` to share tests and tooling.

**Performance Goals**: Parse + basic analysis p95 < 500ms for files ≤ 1MB (reference hardware). Benchmark reproducibility ±5% variance.

**Constraints**: Parsers MUST be error-tolerant and preserve trivia; lexers MUST be implemented using target language builtin regex engines; formatter MUST be idempotent (99% target on verification corpus).

**Scale/Scope**: MVP supports Ruby and Crystal corpora; initial verification uses representative sample projects and files up to 1MB. Tests must cover parse/format/lint/LSP contract behaviors for both languages.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Gates determined based on the project constitution (`.specify/memory/constitution.md`):

- **MUST** comply with core code quality principles: **MODULAR**, **EXTENSIBLE**, **OO-DESIGN**, **FUNCTIONAL-STYLE**, **LANGUAGE-AGNOSTIC**, **HIGH-PERFORMANCE**, **ERROR-TOLERANT**, **ELEGANT**, **ACADEMIC-QUALITY**, **PROFESSIONALLY-DOCUMENTED**, **CLEAN**, **FOCUSED**, **DRY**, **KISS**, **SOLID**.
- **MUST** follow Test-First discipline: tests for the work MUST be written and observed to FAIL before implementation begins.
- **MUST** provide documentation in **arc42** Asciidoc format placed under `docs/modules/ROOT/pages` (Antora layout).
- **MUST** record major decisions as RFCs/ADRs and meeting minutes in `docs/rfc/`, `docs/adr/`, and `docs/minutes/` respectively.
- **SHOULD** prefer the `.yaml` extension for YAML files when possible and be consistent across the project.
- **MUST** include explicit performance goals and constraints in the plan's "Performance Goals" and "Constraints" fields.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations that require exceptions were identified. The choice to support **two** target languages (Ruby + Crystal) increases scope compared to a single-language MVP but is justified by improved cross-paradigm validation and stronger research claims.

---

## Phase 0: Outline & Research (in progress)

Purpose: Resolve remaining unknowns and validate core technical choices before detailed design.

Research tasks (deliverables: `research.md`):

- R1: Evaluate regex-based lexer viability in **Ruby** and **Crystal** — benchmarks for tokenization throughput and trivia handling; prototype tokenizers showing trivia preservation.
- R2: Design RD (recursive-descent) parser architecture that is error-tolerant and supports preserving concrete syntax and trivia; implement a small prototype parser for MiniLang to validate error recovery and idempotent printing.
- R3: Investigate generator implementation language tradeoffs (Rust vs Crystal vs hybrid approaches): build small PoC targeting codegen for Ruby and Crystal templates and measure iteration speed and cross-language portability.
- R4: Define cross-backend contract tests and LSP integration approach (JSON-RPC over stdio or TCP), and create contract specs under `specs/001-wiregram-framework/contracts/`.
- R5: Design benchmark harness and define reference hardware & measurement procedure; ensure reproducibility and artifact archiving.

Acceptance criteria for Phase 0:

- Prototypes for R1 and R2 exist and demonstrate feasibility.
- Recommendation for generator implementation language documented and justified.
- Contract test skeletons and benchmark plan documented in `research.md`.

## Phase 1: Design & Contracts (high level)

Prerequisite: Phase 0 research completed and recommended choices accepted.

Planned outputs:

- `data-model.md` capturing grammar ASTs, tokens, and artifact contracts.
- `contracts/` including OpenAPI or LSP interaction contracts, and JSON formats for linter reports and benchmark artifacts.
- `quickstart.md` describing how to generate a runtime for Ruby and Crystal from a sample `.wg`.

## Risks

- Performance regressions for large files: mitigate with early benchmarking (R5).
- Ambiguous grammars: mitigate with clear diagnostics and grammar tooling in the generator to detect ambiguities early.
- Cross-language parity: mitigate by enforcing contract and contract tests across backends.

## Next Steps

1. Complete Phase 0 tasks (execute R1–R5) and update `research.md` with results.
2. Record the generator implementation language decision as an ADR and update plan accordingly.
3. Produce Phase 1 artifacts (`data-model.md`, `contracts/`, `quickstart.md`) and generate tasks for implementation.
