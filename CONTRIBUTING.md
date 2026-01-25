# Contributing

Thanks for contributing! A few notes to help you run the test suite and update snapshots.

## Running tests with coverage
By default test runs enable SimpleCov and write HTML coverage results to `coverage/`.

- Run full test suite and generate coverage:

  ```bash
  bundle exec rspec
  # Coverage report: open coverage/index.html
  ```

- To disable coverage for a quick run:

  ```bash
  NO_COVERAGE=1 bundle exec rspec
  ```

## Snapshots
We use snapshot tests for CLI and language outputs.

- If a test fails because a snapshot is missing or intentionally changed, update snapshots by re-running the failing spec(s) with `UPDATE_SNAPSHOTS=1`:

  ```bash
  UPDATE_SNAPSHOTS=1 bundle exec rspec spec/integration/cli_integration_spec.rb
  ```

- Inspect the generated snapshot in `spec/snapshots/<language>/` and commit it with a clear message.

## CLI Integration tests
- Integration tests shell out to the `bin/wiregram` binary. Ensure `bin/wiregram` is executable:

  ```bash
  chmod +x bin/wiregram
  ```

- By default CLI integration tests set `WIREGRAM_FORMAT=json` to capture machine-readable output.

## CI
- Coverage is generated during test runs. Optionally, we can enforce a minimum coverage threshold in CI if desired.

Thanks again — contributions are welcome!