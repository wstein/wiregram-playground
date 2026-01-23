Parser Prototype (RD parsers)

Purpose: Minimal recursive-descent parser prototypes for a small expression language that preserve concrete syntax and attach trivia from tokens.

Paths:
- Ruby prototype: `parser.rb` (+ `spec/parser_spec.rb`)
- Crystal prototype: `parser.cr` (+ `spec/parser_spec.cr`)

Goals:
- Demonstrate error recovery and round-trip parse → print → parse equivalence.

Run:
- Ruby: `ruby parser.rb specs/001-wiregram-framework/research/corpus/sample.minilang`
- Crystal: `crystal run parser.cr -- specs/001-wiregram-framework/research/corpus/sample.minilang`