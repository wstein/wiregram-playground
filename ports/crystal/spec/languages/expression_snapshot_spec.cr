require "../spec_helper"

describe "Expression Language Snapshots" do
  describe "tokenization snapshots" do
    it "snapshots tokens for simple number" do
      input = "42"
      lexer = WireGram::Languages::Expression::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      SnapshotHelper.assert_snapshot("simple_expression_tokens", token_strings.join("\n"), "expression")
    end

    it "snapshots tokens for arithmetic expression" do
      input = "1 + 2"
      lexer = WireGram::Languages::Expression::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      SnapshotHelper.assert_snapshot("arithmetic_expression_tokens", token_strings.join("\n"), "expression")
    end

    it "snapshots tokens for assignment" do
      input = "let x = 42"
      lexer = WireGram::Languages::Expression::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      SnapshotHelper.assert_snapshot("assignment_expression_tokens", token_strings.join("\n"), "expression")
    end

    it "snapshots tokens for complex expression" do
      input = "let result = (x + y) * 2"
      lexer = WireGram::Languages::Expression::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      SnapshotHelper.assert_snapshot("complex_expression_tokens", token_strings.join("\n"), "expression")
    end
  end

  describe "AST snapshots" do
    it "snapshots AST for simple number" do
      input = "42"
      result = WireGram::Languages::Expression.process(input)

      ast_string = result[:ast].as(WireGram::Core::Node).to_json

      SnapshotHelper.assert_snapshot("simple_expression_ast", ast_string, "expression")
    end

    it "snapshots AST for arithmetic expression" do
      input = "1 + 2"
      result = WireGram::Languages::Expression.process(input)

      ast_string = result[:ast].as(WireGram::Core::Node).to_json

      SnapshotHelper.assert_snapshot("arithmetic_expression_ast", ast_string, "expression")
    end

    it "snapshots AST for assignment" do
      input = "let x = 42"
      result = WireGram::Languages::Expression.process(input)

      ast_string = result[:ast].as(WireGram::Core::Node).to_json

      SnapshotHelper.assert_snapshot("assignment_expression_ast", ast_string, "expression")
    end

    it "snapshots AST for complex expression" do
      input = "let result = (x + y) * 2"
      result = WireGram::Languages::Expression.process(input)

      ast_string = result[:ast].as(WireGram::Core::Node).to_json

      SnapshotHelper.assert_snapshot("complex_expression_ast", ast_string, "expression")
    end
  end

  describe "UOM snapshots" do
    it "snapshots UOM for simple number" do
      input = "42"
      result = WireGram::Languages::Expression.process(input)

      uom = result[:uom].as(WireGram::Languages::Expression::UOM)
      uom_pretty = uom.root.not_nil!.to_json

      SnapshotHelper.assert_snapshot("simple_expression_input", input, "expression")
      SnapshotHelper.assert_snapshot("simple_expression_uom", uom_pretty, "expression")
    end

    it "snapshots UOM for arithmetic expression" do
      input = "1 + 2"
      result = WireGram::Languages::Expression.process(input)

      uom = result[:uom].as(WireGram::Languages::Expression::UOM)
      uom_pretty = uom.root.not_nil!.to_json

      SnapshotHelper.assert_snapshot("arithmetic_expression_input", input, "expression")
      SnapshotHelper.assert_snapshot("arithmetic_expression_uom", uom_pretty, "expression")
    end

    it "snapshots UOM for assignment" do
      input = "let x = 42"
      result = WireGram::Languages::Expression.process(input)

      uom = result[:uom].as(WireGram::Languages::Expression::UOM)
      uom_pretty = uom.root.not_nil!.to_json

      SnapshotHelper.assert_snapshot("assignment_expression_input", input, "expression")
      SnapshotHelper.assert_snapshot("assignment_expression_uom", uom_pretty, "expression")
    end

    it "snapshots UOM for complex expression" do
      input = "let result = (x + y) * 2"
      result = WireGram::Languages::Expression.process(input)

      uom = result[:uom].as(WireGram::Languages::Expression::UOM)
      uom_pretty = uom.root.not_nil!.to_json

      SnapshotHelper.assert_snapshot("complex_expression_input", input, "expression")
      SnapshotHelper.assert_snapshot("complex_expression_uom", uom_pretty, "expression")
    end
  end

  describe "output snapshots" do
    it "snapshots normalized output for simple number" do
      input = "42"
      result = WireGram::Languages::Expression.process(input)

      SnapshotHelper.assert_snapshot("simple_expression_output", result[:output], "expression")
    end

    it "snapshots normalized output for arithmetic expression" do
      input = "1 + 2"
      result = WireGram::Languages::Expression.process(input)

      SnapshotHelper.assert_snapshot("arithmetic_expression_output", result[:output], "expression")
    end

    it "snapshots normalized output for assignment" do
      input = "let x = 42"
      result = WireGram::Languages::Expression.process(input)

      SnapshotHelper.assert_snapshot("assignment_expression_output", result[:output], "expression")
    end

    it "snapshots normalized output for complex expression" do
      input = "let result = (x + y) * 2"
      result = WireGram::Languages::Expression.process(input)

      SnapshotHelper.assert_snapshot("complex_expression_output", result[:output], "expression")
    end
  end

  describe "complete pipeline snapshots" do
    it "snapshots complete pipeline for simple expression" do
      input = "42"

      result = WireGram::Languages::Expression.process(input)

      tokens_block = result[:tokens].as(Array(WireGram::Core::Token)).map do |t|
        "{type: #{t[:type]}, value: #{t[:value].inspect}, position: #{t[:position]}}"
      end.join("\n")

      uom = result[:uom].as(WireGram::Languages::Expression::UOM)

      snapshot_content = <<-SNAPSHOT
=== INPUT ===
#{input}

=== TOKENS ===
#{tokens_block}

=== AST ===
#{result[:ast].as(WireGram::Core::Node).to_json}

=== UOM ===
#{uom.root.not_nil!.to_json}

=== OUTPUT ===
#{result[:output]}

=== ERRORS ===
#{result[:errors].inspect}
SNAPSHOT

      SnapshotHelper.assert_snapshot("simple_expression_complete", snapshot_content, "expression")
    end

    it "snapshots complete pipeline for complex expression" do
      input = <<-EXPR
let x = 42
let y = x + 1
let result = (x * y) / 2
EXPR
      input = "#{input}\n"

      result = WireGram::Languages::Expression.process(input)

      tokens_block = result[:tokens].as(Array(WireGram::Core::Token)).map do |t|
        "{type: #{t[:type]}, value: #{t[:value].inspect}, position: #{t[:position]}}"
      end.join("\n")

      uom = result[:uom].as(WireGram::Languages::Expression::UOM)

      snapshot_content = <<-SNAPSHOT
=== INPUT ===
#{input}

=== TOKENS ===
#{tokens_block}

=== AST ===
#{result[:ast].as(WireGram::Core::Node).to_json}

=== UOM ===
#{uom.root.not_nil!.to_json}

=== OUTPUT ===
#{result[:output]}

=== ERRORS ===
#{result[:errors].inspect}
SNAPSHOT

      SnapshotHelper.assert_snapshot("complex_expression_complete", snapshot_content, "expression")
    end
  end
end
