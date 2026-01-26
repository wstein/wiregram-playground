# frozen_string_literal: true

Given('a json input {string}') do |input|
  @input = input
end

Given('a json input:') do |input|
  @input = input
end

When('I process the json input') do
  @result = WireGram::Languages::Json.process(@input)
  @last_output = @result[:output]
end

When('I pretty process the json input') do
  @result = WireGram::Languages::Json.process_pretty(@input)
  @last_output = @result[:output]
end

When('I simple process the json input') do
  @result = WireGram::Languages::Json.process_simple(@input)
  @last_output = @result[:output]
end

When('I convert the json UOM to simple JSON') do
  @simple_output = @result[:uom].to_simple_json
end

Then('the json result should include tokens, ast, uom, output') do
  expect(@result).to have_key(:tokens)
  expect(@result).to have_key(:ast)
  expect(@result).to have_key(:uom)
  expect(@result).to have_key(:output)
  expect(@result[:tokens]).to be_a(Array)
  expect(@result[:ast]).to be_a(WireGram::Core::Node)
  expect(@result[:uom]).to be_a(WireGram::Languages::Json::UOM)
end

Then('the json output should be {string}') do |expected|
  expect(@last_output).to eq(expected)
end

Then('the json output should include:') do |table|
  table.raw.flatten.each do |fragment|
    expect(@last_output).to include(fragment)
  end
end

Then('the json output should include a newline') do
  expect(@last_output).to include("\n")
end

Then('the json errors should be empty') do
  expect(@result[:errors]).to be_empty
end

Then('the json errors should be present') do
  expect(@result[:errors]).to be_a(Array)
  expect(@result[:errors]).not_to be_empty
end

Then('the json output should be a string') do
  expect(@last_output).to be_a(String)
end

Then('the json simple output should equal:') do |doc_string|
  expected = JSON.parse(doc_string)
  actual = @simple_output || @last_output
  expect(actual).to eq(expected)
end
