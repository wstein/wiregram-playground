# WireGram Playground ⚙️

A research playground for implementing and validating lexer/parser and toolchain generation prototypes.

## What we built

WireGram is a factory for language tooling: from a single `.wg` (UCL) grammar you can generate LSP servers, formatters, linters, auto-fixers, and MCP providers. The repository currently contains Phase‑0 prototypes (lexer and RD parser) for Ruby and Crystal.

## Quickstart — devcontainer (recommended) ✅

1. Open this repository in VS Code.
2. When prompted, "Reopen in Container" to build the Fedora devcontainer (see `.devcontainer/`).
3. After setup finishes, run the workspace tasks (see below) to run tests and benchmarks.

If you prefer not to use the devcontainer, ensure your environment has Ruby 3.4+, Crystal 1.19.1, RSpec, and other tools listed in `.devcontainer/scripts/devcontainer-setup.sh`.

---

## Running prototypes (workspace tasks)

Use the **Run Task...** command (Cmd/Ctrl+Shift+P → Tasks: Run Task) or the Tasks panel to execute these common actions:

- **Run Ruby prototypes (tests)** — runs the RSpec specs for the lexer and RD parser.
- **Run Ruby lexer benchmark** — runs a simple micro-benchmark script (1000 iterations) and prints timing.

(See `.vscode/tasks.json` for exact commands.)

---

## Devcontainer & VS Code recommendations (review + ratings)

I reviewed the current `.devcontainer/devcontainer.json` and the workspace. Below are recommended settings, ports, tasks, and launch configurations for prototype development, along with priority ratings.

### Recommended VS Code settings (implemented) 🔧

- `terminal.integrated.defaultProfile.linux: "fish"` — Use fish for dev productivity and prompt features. (Rating: High ✅)
- `files.associations: { "*.wg": "ini" }` — Basic association for WireGram grammar files for now. (Rating: Medium)
- `editor.formatOnSave: false` — Avoid automatic formatting while iterating on parsers. (Rating: High ✅)
- `yaml.format.enable: true` and prefer `.yaml` extension — keeps consistency with the constitution. (Rating: High ✅)

### Recommended forwarded ports (options) 🔌

- 8080 — Benchmark / instrumentation HTTP UI (Rating: Medium)
- 5005 — Debug server / remote attach for other backends (Rating: Low)

I set `8080` as a recommended forwarded port in the devcontainer but kept additional ports optional.

### Suggested workspace tasks & launches (implemented) ▶️

- Task: **Run Ruby prototypes (tests)** — `rspec --format documentation specs/...` (Rating: High ✅)
- Task: **Run Ruby lexer benchmark** — `ruby specs/.../run_lexer_bench.rb` (Rating: Medium)
- Launch: **Run Lexer Benchmark (terminal)** — launches the benchmark in the integrated terminal. (Rating: Medium)

### Extensions to install (implemented + suggested) 📦

- `castwide.solargraph` (Ruby LSP) — High ✅
- `crystal-lang.crystal` — High ✅
- `redhat.vscode-yaml` (YAML support) — High ✅
- `eamodio.gitlens` (git UI) — Medium
- `tadashi.fish` (Fish shell support) — Medium

---

## Files added / updated

- `.devcontainer/devcontainer.json` — forwardPorts + settings + extensions
- `.devcontainer/Dockerfile`, `.devcontainer/scripts/devcontainer-setup.sh` — provisioning
- `.vscode/tasks.json` — tasks for tests & bench
- `.vscode/launch.json` — terminal launches for the prototypes
- `.vscode/settings.json` — workspace settings

---

## Next suggestions (pick one)

1. Add Crystal test tasks and benchmark harness (I can scaffold). (Rating: High)  
2. Add a simple HTTP benchmark UI or exporter on port 8080 for reproducible benchmark artifacts. (Rating: Medium)  
3. Add a debug configuration for Ruby (rdbg) and Crystal (if supported) for interactive debugging of parsers. (Rating: Medium)

---

If you want, I can apply any of the next suggestions now — tell me which to prioritize.
