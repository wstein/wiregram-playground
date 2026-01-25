# WireGram CLI - Quick Reference

## Installation

```bash
# Make the CLI executable (already done)
chmod +x bin/wiregram

# Install dependencies
bundle install
```

## Commands

### List Languages
```bash
bin/wiregram list
```

### Inspect (Full Pipeline)
Runs: tokenize → parse → transform → serialize

```bash
# From stdin
echo '{"a":1}' | bin/wiregram json inspect

# With pretty output
echo '{"a":1}' | bin/wiregram json inspect --pretty

# From file
bin/wiregram json inspect config.json
```

### Tokenize
Shows the token stream. The CLI supports streaming token output (NDJSON) when available — this is ideal for large inputs.

```bash
# Basic (may stream tokens line-delimited JSON)
echo '{"a":1}' | bin/wiregram json tokenize

# Stream and pipe to jq (-c for compact JSON lines)
bin/wiregram json tokenize large.json | jq -c .

echo 'x = 1 + 2' | bin/wiregram expression tokenize
echo 'key = "value"' | bin/wiregram ucl tokenize
```

### Parse
Shows the abstract syntax tree (AST). For large arrays or streaming-capable languages, `parse` can stream nodes as NDJSON lines.

```bash
# Parse and print full AST (non-streaming)
echo '{"a":1}' | bin/wiregram json parse

# Stream array items as individual JSON node lines
bin/wiregram json parse large_array.json | jq -c .

echo 'x = 1 + 2' | bin/wiregram expression parse
echo 'key = "value"' | bin/wiregram ucl parse
```

### Help
```bash
bin/wiregram help
bin/wiregram json help
bin/wiregram expression help
bin/wiregram ucl help
```

## Output Formats

### Text (Default)
Human-readable with sections for tokens, AST, output, errors.

```bash
bin/wiregram json inspect < input.json
```

### JSON (Machine-Readable)
Structured JSON output for programmatic use.

```bash
# Via environment variable
WIREGRAM_FORMAT=json bin/wiregram json inspect < input.json

# Via global option
bin/wiregram --format json json inspect < input.json
```

## Server Mode

Start a long-running HTTP/JSON server for programmatic access.

```bash
bin/wiregram server --port 4567
```

### API Endpoint

**POST** `/v1/process`

Request body:
```json
{
  "language": "json",
  "input": "{\"a\": 1}",
  "pretty": true
}
```

Response:
```json
{
  "tokens": [...],
  "ast": {...},
  "uom": {...},
  "output": "...",
  "errors": []
}
```

Example with curl:
```bash
curl -X POST http://localhost:4567/v1/process \
  -H "Content-Type: application/json" \
  -d '{"language":"json","input":"{\"a\":1}","pretty":true}'
```

## Supported Languages

| Language | Status | tokenize | parse | inspect | pretty |
|----------|--------|----------|-------|---------|--------|
| **json** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **expression** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **ucl** | ✅ | ✅ | ✅ | ✅ | — |

## Examples

### JSON
```bash
# Tokenize
echo '{"name":"test"}' | bin/wiregram json tokenize

# Parse
echo '{"name":"test"}' | bin/wiregram json parse

# Full pipeline
echo '{"name":"test"}' | bin/wiregram json inspect --pretty

# From file
bin/wiregram json inspect large.json
```

### Expression
```bash
# Tokenize
echo 'x = 10 + 20' | bin/wiregram expression tokenize

# Parse
echo 'x = 10 + 20' | bin/wiregram expression parse

# Full pipeline
echo 'x = 10 + 20' | bin/wiregram expression inspect --pretty
```

### UCL
```bash
# Tokenize
echo 'server { port = 8080; }' | bin/wiregram ucl tokenize

# Parse
echo 'server { port = 8080; }' | bin/wiregram ucl parse

# Full pipeline
echo 'server { port = 8080; }' | bin/wiregram ucl inspect
```

## Integration from Other Languages

### Crystal
```crystal
# Shell out and parse JSON
Process.run("bin/wiregram", ["json", "inspect"], input: stdin, output: stdout)
```

### Kotlin
```kotlin
// Use ProcessBuilder
val process = ProcessBuilder("bin/wiregram", "json", "inspect")
  .redirectInput(ProcessBuilder.Redirect.PIPE)
  .redirectOutput(ProcessBuilder.Redirect.PIPE)
  .start()
```

### Python
```python
import subprocess
import json

result = subprocess.run(
  ["bin/wiregram", "json", "inspect"],
  input='{"a":1}',
  capture_output=True,
  text=True
)
output = json.loads(result.stdout)
```

### Node.js
```javascript
const { spawn } = require('child_process');

const child = spawn('bin/wiregram', ['json', 'inspect']);
let data = '';

child.stdout.on('data', (chunk) => {
  data += chunk;
});

child.on('close', () => {
  console.log(JSON.parse(data));
});
```

## Testing

Run the comprehensive test suite:

```bash
bundle exec rspec spec/cli_comprehensive_spec.rb
```

Quick verification:

```bash
ruby check_cli.rb
```

## Troubleshooting

**"Unknown command"**
- Check language name: `bin/wiregram list`
- Check action is valid: `inspect`, `tokenize`, `parse`, `help`

**"tokenize not supported"**
- Language module may not have implemented tokenize
- Check supported actions: `bin/wiregram <language> help`

**"undefined method 'process'"**
- Ruby CLI not loading language module
- Try: `bundle exec bin/wiregram list` to verify setup

**Server doesn't start**
- Port may be in use: try `--port 5000`
- Check Ruby version: requires 2.7+

## Documentation

- **CLI_SUMMARY.md** — Complete overview
- **CHANGES.md** — What changed and why
- **docs/cli.md** — Detailed CLI reference
- **docs/crystal_kotlin_port_guide.md** — How to port to other languages
- **docs/CLI_IMPLEMENTATION_STATUS.md** — Implementation details

## Performance Notes

- Tokenization: ~15-100ms per invocation
- Parsing: ~30-150ms per invocation
- Full pipeline: ~100-300ms per invocation

For high-throughput workloads, use server mode to avoid subprocess overhead.

## File Input

Any command can read from a file instead of stdin:

```bash
# These are equivalent:
bin/wiregram json inspect < config.json
bin/wiregram json inspect config.json

# With stdin:
echo '{}' | bin/wiregram json inspect
```

## License

See LICENSE file for details.
