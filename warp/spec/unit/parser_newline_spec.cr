require "../spec_helper"

describe Simdjson::Parser do
  it "emits Newline tokens for newline characters and preserves existing tokens" do
    json = "{\n\"a\":1\n}"
    bytes = json.to_slice
    parser = Simdjson::Parser.new
    types = [] of Simdjson::TokenType

    err = parser.each_token(bytes) do |tok|
      types << tok.type
    end

    err.success?.should be_true
    # Use textual index checks to avoid any possible `includes?` issues across test runtime
    names = types.map { |t| t.to_s }
    STDERR.puts "DEBUG tokens: #{names.join(", ")}" if ENV["SIMDJSON_TEST_DEBUG"]?
    names.index("Newline").not_nil!
    # Ensure other core token types still appear
    names.index("StartObject").not_nil!
    names.index("EndObject").not_nil!
    names.index("String").not_nil!
    names.index("Number").not_nil!

    # Check ordering: StartObject, Newline, String, Colon, Number, Newline, EndObject
    # We'll map to a short list of token names for simple matching.
    names = types.map { |t| t.to_s }
    start_idx = names.index("StartObject").not_nil!
    newline_idx = names.index("Newline").not_nil!
    string_idx = names.index("String").not_nil!
    number_idx = names.index("Number").not_nil!

    start_idx.should be < newline_idx
    newline_idx.should be < string_idx
    string_idx.should be < number_idx
  end
end
