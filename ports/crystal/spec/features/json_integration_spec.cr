require "../spec_helper"

private def json_any_from(value : WireGram::Languages::Json::UOM::SimpleJson)
  JSON.parse(value.to_json)
end

describe "JSON language integration" do
  it "processes JSON through the pipeline" do
    examples = [
      {"input" => "{\"name\": \"John\", \"age\": 30}", "output" => "{\"name\": \"John\", \"age\": 30}"},
      {"input" => "{\"user\": {\"name\": \"John\", \"address\": {\"city\": \"NYC\"}}, \"active\": true}", "output" => "{\"user\": {\"name\": \"John\", \"address\": {\"city\": \"NYC\"}}, \"active\": true}"},
      {"input" => "[1, \"hello\", true, null]", "output" => "[1, \"hello\", true, null]"},
      {"input" => "{\"users\": [{\"name\": \"John\", \"age\": 30}, {\"name\": \"Jane\", \"age\": 25}], \"count\": 2}", "output" => "{\"users\": [{\"name\": \"John\", \"age\": 30}, {\"name\": \"Jane\", \"age\": 25}], \"count\": 2}"}
    ]

    examples.each do |example|
      result = WireGram::Languages::Json.process(example["input"])

      expect(result.has_key?(:tokens)).to be_true
      expect(result.has_key?(:ast)).to be_true
      expect(result.has_key?(:uom)).to be_true
      expect(result.has_key?(:output)).to be_true

      expect(result[:output].as(String)).to eq(example["output"])
      expect(result[:errors].as(Array(Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil)))).to be_empty
    end
  end

  it "handles pretty formatting" do
    input = "{\"name\":\"John\",\"age\":30}"
    result = WireGram::Languages::Json.process_pretty(input)

    output = result[:output].as(String)
    expect(output.includes?("\"name\": \"John\"")).to be_true
    expect(output.includes?("\"age\": 30")).to be_true
    expect(output.includes?("\n")).to be_true
    expect(result[:errors].as(Array(Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil)))).to be_empty
  end

  it "handles simple Ruby structure conversion" do
    input = "{\"name\": \"John\", \"age\": 30}"
    result = WireGram::Languages::Json.process_simple(input)

    expected = JSON.parse("{\"name\": \"John\", \"age\": 30}")
    actual = result[:output].as(WireGram::Languages::Json::UOM::SimpleJson)
    expect(json_any_from(actual)).to eq(expected)
    expect(result[:errors].as(Array(Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil)))).to be_empty
  end

  it "handles malformed JSON" do
    input = "{\"name\": \"John\", \"age\":}"
    result = WireGram::Languages::Json.process(input)

    expect(result[:errors].as(Array(Hash(Symbol, String | Int32 | WireGram::Core::TokenType | Symbol | Nil)))).not_to be_empty
    expect(result[:output]).to be_a(String)
  end

  it "converts UOM to simple JSON" do
    input = "{\"name\": \"John\", \"age\": 30, \"active\": true, \"tags\": [\"developer\", \"ruby\"]}"
    result = WireGram::Languages::Json.process(input)

    expected = JSON.parse("{\"name\": \"John\", \"age\": 30, \"active\": true, \"tags\": [\"developer\", \"ruby\"]}")
    uom = result[:uom].as(WireGram::Languages::Json::UOM)
    actual = json_any_from(uom.to_simple_json)

    expect(actual).to eq(expected)
  end
end
