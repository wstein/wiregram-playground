<!--
Sync Impact Report
- Version change: template → 1.0.0
- Modified principles: Added CLEAN Code Quality; Test-First & Testing Standards; UX Consistency & Accessibility; Language-Agnostic High Performance; Simplicity (FOCUSED/DRY/KISS/SOLID)
- Added sections: Documentation & Artifacts; Development Workflow
- Removed sections: none
- Templates requiring updates:
  - .specify/templates/plan-template.md ✅ updated
  - .specify/templates/spec-template.md ✅ updated
  - .specify/templates/tasks-template.md ✅ updated
  - .specify/templates/agent-file-template.md ✅ updated
  - .specify/templates/commands/*.md ⚠ pending (no files found)
- Follow-up TODOs: none
-->

# Wiregram Playground Constitution

## Core Principles

### I. CLEAN Code Quality (NON-NEGOTIABLE)

Code MUST be readable, well-structured, and maintainable. Every contribution MUST include clear intent, inline documentation where needed, and pass automated static analysis and lints. Type annotations, consistent formatting, and small, focused functions and modules are REQUIRED. Rationale: Research artifacts must be reproducible and reviewable by peers across languages and time.

### II. Test-First & Testing Standards (NON-NEGOTIABLE)

All work MUST follow a Test-First discipline: tests (unit, integration, contract, or acceptance) are written and verified to FAIL before implementation begins. Tests MUST be automated and run in CI on every PR; gate criteria include passing tests and no new high-severity lint findings. Coverage targets are advisory (e.g., 80% for critical modules) but testing MUST prioritize correctness and reproducibility. Rationale: Ensures experimental validity and prevents regressions in research outcomes.

### III. UX Consistency & Accessibility

User-facing APIs, CLIs, UIs, and developer ergonomics MUST be consistent, documented, and language-agnostic where possible. Error messages, schema names, and user journeys MUST follow a documented style guide and be accessible. Rationale: Consistency reduces cognitive load for researchers and external reviewers, improving reproducibility and evaluation.

### IV. Language-Agnostic, High Performance & Interoperability

Designs MUST be language-agnostic: interfaces, contracts, and data schemas MUST be explicit and versioned. Performance requirements MUST be captured in the Plan (p95/p99 targets, resource constraints) and validated with benchmarks. Interoperability (clear JSON/text protocols, schema validations) is REQUIRED for cross-language experiments. Rationale: Research experiments often compare implementations across languages and require objective performance measurements.

### V. Simplicity: FOCUSED, DRY, KISS, SOLID

Prefer the simplest solution that satisfies requirements. Modules MUST be focused, adhere to SOLID principles where applicable, avoid duplication (DRY), and keep designs minimal (KISS). Complex solutions MUST be justified with measurable benefits. Rationale: Simpler designs are easier to reason about, test, and reproduce in an academic setting.

## Documentation & Artifacts

- Architecture documentation MUST follow **arc42** using **Asciidoc** and be stored in the Antora layout at `docs/modules/ROOT/pages`.
- Major decisions and proposals MUST be recorded as **RFCs** and **ADRs** in `docs/rfc/` and `docs/adr/` respectively; meeting minutes MUST be kept in `docs/minutes/`.
- Documentation MUST include quickstarts, reproducible experiment steps, and benchmark instructions. Where configuration files are used, prefer the **`.yaml`** extension for consistency.

## Development Workflow

- Branching: feature branches SHOULD follow `feat/` or `research/` prefixes; PRs MUST be small and scoped to a single change or experiment.
- Reviews: All PRs MUST have at least one approving reviewer; substantial changes (new principles, infra, or API) require two approvers, one of whom MUST be a maintainer or project lead.
- Gates: CI MUST enforce linting, Test-First evidence (tests included and executed), and that all tests pass before merge. Performance-sensitive changes MUST include benchmarks and performance regression checks.
- Commits: Use clear, imperative commit messages and reference RFCs/ADRs where relevant.
- Artifacts: Every experiment or feature MUST include a Plan, Spec, Tasks, Tests, Documentation, and benchmark artifacts when applicable.

## Governance

- Constitution status: This document is the authoritative source for project principles and governance.
- Amendments: Proposals to amend the constitution MUST be made as an RFC in `docs/rfc/` and include a migration plan, tests, and PR that updates this file. Amendments require approval by at least **two** maintainers and an explicit version bump.
- Versioning policy (semantic):
  - **MAJOR** when principles or governance change in a backward-incompatible way (removal or redefinition of principles).
  - **MINOR** when new principles or sections are added or materially expanded guidance is introduced.
  - **PATCH** for clarifications, wording fixes, or non-substantive refinements.
- Compliance: The project SHOULD perform an annual constitution compliance review and maintain an audit log of governance decisions.

**Version**: 1.0.0 | **Ratified**: 2026-01-23 | **Last Amended**: 2026-01-23
