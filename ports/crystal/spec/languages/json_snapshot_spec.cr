require "../spec_helper"

private def snapshot_section(name, section, language = "json")
  path = SnapshotHelper.snapshot_path(name, language)
  unless File.exists?(path)
    raise "Snapshot missing: #{path}."
  end

  sections = {} of String => String
  current = nil
  buffer = [] of String

  File.read(path).each_line(chomp: false) do |line|
    if (match = line.match(/^=== (.+) ===\s*$/))
      if current
        sections[current] = buffer.join
      end
      current = match[1]
      buffer.clear
    else
      buffer << line
    end
  end

  sections[current] = buffer.join if current

  content = sections[section]?
  raise "Snapshot section missing: #{section} in #{path}." unless content

  content.rstrip
end

describe "JSON Language Snapshots" do
  describe "tokenization snapshots" do
    it "snapshots tokens for simple JSON" do
      input = "{\"name\": \"John\", \"age\": 30}"
      lexer = WireGram::Languages::Json::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      SnapshotHelper.assert_snapshot("simple_json_tokens", token_strings.join("\n"), "json")
    end

    it "snapshots tokens for nested JSON" do
      fixture_path = File.expand_path("../../../../spec/languages/json/fixtures/valid/nested.json", __DIR__)
      input = File.read(fixture_path)
      lexer = WireGram::Languages::Json::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      expected = snapshot_section("nested_complete", "TOKENS", "json")
      expect(token_strings.join("\n").rstrip).to eq(expected)
    end

    it "snapshots tokens for arrays" do
      fixture_path = File.expand_path("../../../../spec/languages/json/fixtures/valid/arrays.json", __DIR__)
      input = File.read(fixture_path)
      lexer = WireGram::Languages::Json::Lexer.new(input)
      tokens = lexer.tokenize

      token_strings = tokens.map do |token|
        "{type: #{token[:type]}, value: #{token[:value].inspect}, position: #{token[:position]}}"
      end

      expected = snapshot_section("arrays_complete", "TOKENS", "json")
      expect(token_strings.join("\n").rstrip).to eq(expected)
    end
  end

  describe "AST snapshots" do
    it "snapshots AST for simple JSON" do
      input = "{\"name\": \"John\", \"age\": 30}"
      result = WireGram::Languages::Json.process(input)

      ast_string = result[:ast].as(WireGram::Core::Node).to_json

      SnapshotHelper.assert_snapshot("simple_json_ast", ast_string, "json")
    end

    it "snapshots AST for nested JSON" do
      fixture_path = File.expand_path("../../../../spec/languages/json/fixtures/valid/nested.json", __DIR__)
      input = File.read(fixture_path)
      result = WireGram::Languages::Json.process(input)

      ast_string = result[:ast].as(WireGram::Core::Node).to_json

      expected = snapshot_section("nested_complete", "AST", "json")
      expect(ast_string.rstrip).to eq(expected)
    end
  end

  describe "UOM snapshots" do
    it "snapshots UOM for simple JSON" do
      input = "{\"name\": \"John\", \"age\": 30}"
      result = WireGram::Languages::Json.process(input)

      uom = result[:uom].as(WireGram::Languages::Json::UOM)
      uom_pretty = uom.root.not_nil!.to_pretty_json

      SnapshotHelper.assert_snapshot("simple_json_input", input, "json")
      SnapshotHelper.assert_snapshot("simple_json_uom", uom_pretty, "json")
    end

    it "snapshots UOM for complex JSON" do
      input = "{\"users\": [{\"name\": \"John\", \"age\": 30}, {\"name\": \"Jane\", \"age\": 25}], \"count\": 2}"
      result = WireGram::Languages::Json.process(input)

      uom = result[:uom].as(WireGram::Languages::Json::UOM)
      uom_pretty = uom.root.not_nil!.to_pretty_json

      SnapshotHelper.assert_snapshot("complex_json_input", input, "json")
      SnapshotHelper.assert_snapshot("complex_json_uom", uom_pretty, "json")
    end
  end

  describe "output snapshots" do
    it "snapshots normalized output for simple JSON" do
      input = "{\"name\": \"John\", \"age\": 30}"
      result = WireGram::Languages::Json.process(input)

      SnapshotHelper.assert_snapshot("simple_json_output", result[:output], "json")
    end

    it "snapshots pretty output for simple JSON" do
      input = "{\"name\":\"John\",\"age\":30}"
      result = WireGram::Languages::Json.process_pretty(input)

      SnapshotHelper.assert_snapshot("simple_json_pretty", result[:output], "json")
    end

    it "snapshots simple Ruby structure for simple JSON" do
      input = "{\"name\": \"John\", \"age\": 30}"
      result = WireGram::Languages::Json.process_simple(input)

      ruby_string = result[:output].inspect

      SnapshotHelper.assert_snapshot("simple_json_ruby", ruby_string)
    end
  end

  describe "fixture-based snapshots" do
    fixtures_dir = File.expand_path("../../../../spec/languages/json/fixtures/valid/*.json", __DIR__)
    Dir.glob(fixtures_dir).each do |fixture_file|
      fixture_name = File.basename(fixture_file, ".json")

      it "snapshots complete pipeline for #{fixture_name} fixture" do
        input = File.read(fixture_file)

        result = WireGram::Languages::Json.process(input)

        tokens_block = result[:tokens].as(Array(WireGram::Core::Token)).map do |t|
          "{type: #{t[:type]}, value: #{t[:value].inspect}, position: #{t[:position]}}"
        end.join("\n")

        uom = result[:uom].as(WireGram::Languages::Json::UOM)

        snapshot_content = <<-SNAPSHOT
=== INPUT ===
#{input}

=== TOKENS ===
#{tokens_block}

=== AST ===
#{result[:ast].as(WireGram::Core::Node).to_json}

=== UOM ===
#{uom.root.not_nil!.to_pretty_json}

=== OUTPUT ===
#{result[:output]}

=== ERRORS ===
#{result[:errors].inspect}
SNAPSHOT

        SnapshotHelper.assert_snapshot("#{fixture_name}_complete", snapshot_content, "json")
      end
    end
  end
end
