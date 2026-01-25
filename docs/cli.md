# WireGram CLI 📦

## Overview ✅
This document describes the new umbrella CLI `bin/wiregram` that exposes language pipelines and utilities through a single interface. The CLI is intentionally lightweight and dependency-free (stdlib only) to make it easy to adopt in Ruby, Crystal, and later Kotlin.

---

## Commands 🔧

- `wiregram list` — list available languages
- `wiregram <language> help` — language-specific help
- `wiregram <language> inspect [--pretty]` — run full pipeline (tokenize -> parse -> transform -> serialize) and show a detailed result
- `wiregram <language> tokenize` — show tokens (if supported)
- `wiregram <language> parse` — show AST (if supported)
- `wiregram server [--port 4567]` — start a tiny JSON HTTP server for programmatic access
- `wiregram snapshot --generate [--language <lang>]` — wrapper for Rake snapshot tasks

Global option: `--format json|text` or set `WIREGRAM_FORMAT=json` for machine-friendly output.

---

## Output format
- Human-readable text by default
- JSON (structured) when `--format json` or `WIREGRAM_FORMAT=json` is set
- Server returns JSON payloads at `/v1/process` with parameters `{ language, input, mode, pretty }`

Example server request:

POST /v1/process
{ "language": "json", "input": "{ \"a\": 1 }", "pretty": true }

Response: JSON object containing `tokens`, `ast`, `uom`, `output`, `errors` where available.

---

## Design goals & Portability 💡

1) Keep CLI as thin wrapper around language modules. Language modules already expose `process` / `process_pretty` / `tokenize` / `parse` where applicable. CLI should only parse args and call these methods.

2) Use JSON as the canonical interchange format between the CLI and other tools (server mode or subprocess JSON). This simplifies ports:
   - Crystal: code and stdlib are similar to Ruby. The CLI can be almost line-for-line ported (OptionParser → OptionParser, JSON output via `JSON` module).
   - Kotlin: implement a small CLI that follows the same subcommand structure and communicates with the Ruby server (or external `wiregram` binary) via HTTP/JSON or spawn the Ruby executable and parse JSON output.

3) Optional server mode (HTTP/JSON) lets other language implementations call the same core without porting the parsing stack — fast path for adopting in Kotlin.

---

## Porting suggestions (short list) and ratings ⭐️

1) Minimal port: implement CLI/shim in Crystal/Kotlin that shells out to `bin/wiregram` and parses JSON output. 
   - Effort: Low
   - Performance: Same as Ruby subprocess
   - Portability: Very High
   - Rating: 9/10 ✅

2) Server-first approach: run a long-lived `wiregram server` (Ruby), and implement lightweight client libraries in Crystal/Kotlin that call it over HTTP/JSON.
   - Effort: Medium
   - Performance: Good
   - Portability: High (clients are thin)
   - Rating: 8.5/10 ✅

3) Reimplement parsers & transformers in Crystal/Kotlin directly (native port). 
   - Effort: High
   - Performance: Best
   - Portability: Full native support, but maintenance-heavy
   - Rating: 6/10 ⚠️ (recommended only for heavy performance or native distribution needs)

4) Provide a single language-agnostic binary (e.g., rewrite core in Rust). 
   - Effort: Very High
   - Performance: Excellent
   - Portability: Excellent across ecosystems
   - Rating: 5/10 ⚠️ (big architectural project)

---

## Quick adoption checklist for Crystal/Kotlin

- Implement `list` + `<language> inspect` using option parsing + JSON formatting.
- Prefer server mode for early adoption: implement robust client libraries that call `/v1/process`.
- Add tests that assert on JSON schema returned by the server.

---

## Examples

Run basic inspect:

$ echo '{"a":1}' | wiregram json inspect --pretty

Start server:

$ wiregram server --port 4567

Call from another language over HTTP with the simple pattern shown above.

---

## Notes
- The CLI intentionally avoids extra dependencies to keep ports simple.
- Add new language-specific verbs as the language modules expose new methods.

