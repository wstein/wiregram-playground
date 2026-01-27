require "../spec_helper"

describe "Expression language integration" do
  it "processes basic expressions" do
    examples = [
      {"input" => "42", "output" => "42"},
      {"input" => "x", "output" => "x"},
      {"input" => "\"hello\"", "output" => "\"hello\""},
      {"input" => "1 + 2", "output" => "1 + 2"},
      {"input" => "1 + 2 * 3", "output" => "1 + 2 * 3"},
      {"input" => "(1 + 2) * 3", "output" => "(1 + 2) * 3"},
      {"input" => "let x = 42", "output" => "let x = 42"}
    ]

    examples.each do |example|
      result = WireGram::Languages::Expression.process(example["input"])

      expect(result.has_key?(:tokens)).to be_true
      expect(result.has_key?(:ast)).to be_true
      expect(result.has_key?(:uom)).to be_true
      expect(result.has_key?(:output)).to be_true

      expect(result[:output].as(String)).to eq(example["output"])
    end
  end

  it "processes complex programs" do
    input = <<-EXPR
let x = 42
let y = x + 1
x * y
EXPR

    result = WireGram::Languages::Expression.process(input)

    expect(result[:output].as(String)).to eq(input)
  end

  it "reports errors for invalid expressions" do
    examples = [
      {"input" => "let x =", "error_type" => "unexpected_token"},
      {"input" => "1 + + 2", "error_type" => "unexpected_token"},
      {"input" => "\"unclosed string", "error_type" => "unexpected_token"}
    ]

    examples.each do |example|
      result = WireGram::Languages::Expression.process(example["input"])
      errors = result[:errors].as(Array(Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil)))
      expect(errors.any? { |err| err[:type] == example["error_type"] }).to be_true
    end
  end

  it "processes valid fixtures" do
    fixtures_dir = File.expand_path("../../../../spec/languages/expression/fixtures/valid", __DIR__)

    simple = File.read(File.join(fixtures_dir, "simple.txt"))
    expect(WireGram::Languages::Expression.process(simple)[:output].as(String)).to eq("42")

    identifiers = File.read(File.join(fixtures_dir, "identifiers.txt"))
    expect(WireGram::Languages::Expression.process(identifiers)[:output].as(String)).to eq("x\nvariable_name\nresult")

    strings = File.read(File.join(fixtures_dir, "strings.txt"))
    expect(WireGram::Languages::Expression.process(strings)[:output].as(String)).to eq("\"hello\"\n\"world\"\n\"test string\"")

    arithmetic = File.read(File.join(fixtures_dir, "arithmetic.txt"))
    expect(WireGram::Languages::Expression.process(arithmetic)[:output].as(String)).to eq("1 + 2\nx * y\na - b\nresult / 2\n1 + 2 * 3\n(1 + 2) * 3")

    assignments = File.read(File.join(fixtures_dir, "assignments.txt"))
    expect(WireGram::Languages::Expression.process(assignments)[:output].as(String)).to eq("let x = 42\nlet result = x + y\nlet message = \"hello\"\nlet value = 1 * 2 + 3")

    complex = File.read(File.join(fixtures_dir, "complex.txt"))
    expect(WireGram::Languages::Expression.process(complex)[:output].as(String)).to eq(complex)
  end

  it "reports errors for invalid fixtures" do
    fixtures_dir = File.expand_path("../../../../spec/languages/expression/fixtures/invalid", __DIR__)
    ["incomplete.txt", "malformed.txt"].each do |name|
      input = File.read(File.join(fixtures_dir, name))
      result = WireGram::Languages::Expression.process(input)
      errors = result[:errors].as(Array(Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil)))
      expect(errors.any? { |err| err[:type] == "unexpected_token" }).to be_true
    end
  end

  it "provides core API methods" do
    input = "1 + 2"

    tokens = WireGram::Languages::Expression.tokenize(input)
    expect(tokens).to be_a(Array(WireGram::Core::Token))
    expect(tokens.first[:type]).to be_a(Symbol)

    ast = WireGram::Languages::Expression.parse(input)
    expect(ast).to be_a(WireGram::Core::Node)
    expect(ast.type).to eq(WireGram::Core::NodeType::Program)

    uom = WireGram::Languages::Expression.transform(input)
    expect(uom).to be_a(WireGram::Languages::Expression::UOM)
    expect(uom.root).not_to be_nil

    serialized = WireGram::Languages::Expression.serialize(input)
    expect(serialized).to eq("1 + 2")

    output = WireGram::Languages::Expression.process(input)[:output].as(String)
    expect(output).to eq("1 + 2")
  end

  it "provides pretty and simple processing" do
    input = "1 + 2"

    pretty = WireGram::Languages::Expression.process_pretty(input)[:output].as(String)
    expect(pretty).to eq("1 + 2")

    simple = WireGram::Languages::Expression.process_simple(input)[:output].as(String)
    expect(simple).to eq("1 + 2")
  end
end
