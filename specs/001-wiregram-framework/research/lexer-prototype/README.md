Lexer Prototype (Ruby & Crystal)

Purpose: Minimal regex-based tokenizers that preserve leading/trailing trivia (comments/whitespace) and provide micro-benchmarks for throughput.

Paths:
- Ruby prototype: `lexer.rb` (+ `spec/lexer_spec.rb`)
- Crystal prototype: `lexer.cr` (+ `spec/lexer_spec.cr`)

Goals:
- Demonstrate that runtime builtin regex can tokenize sample corpora and preserve trivia.
- Provide simple micro-benchmarks and a sample corpus.

Run:
- Ruby: `ruby lexer.rb specs/001-wiregram-framework/research/corpus/sample.rb`
- Crystal: `crystal run lexer.cr -- specs/001-wiregram-framework/research/corpus/sample.cr`