# frozen_string_literal: true

Given('an expression input {string}') do |input|
  @input = input
end

Given('an expression input:') do |input|
  @input = input
end

Given('I load the expression fixture {string}') do |filename|
  @input = load_fixture('expression', filename).strip
end

When('I process the expression input') do
  @result = WireGram::Languages::Expression.process(@input)
  @last_output = @result[:output]
end

When('I tokenize the expression input') do
  @tokens = WireGram::Languages::Expression.tokenize(@input)
end

When('I parse the expression input') do
  @ast = WireGram::Languages::Expression.parse(@input)
end

When('I transform the expression input') do
  @uom = WireGram::Languages::Expression.transform(@input)
end

When('I serialize the expression input') do
  @last_output = WireGram::Languages::Expression.serialize(@input)
end

When('I pretty process the expression input with indent {int}') do |indent|
  @result = WireGram::Languages::Expression.process_pretty(@input, indent)
  @last_output = @result[:output]
end

When('I simple process the expression input') do
  @result = WireGram::Languages::Expression.process_simple(@input)
  @last_output = @result[:output]
end

Then('the expression result should include tokens, ast, uom, output') do
  expect(@result).to have_key(:tokens)
  expect(@result).to have_key(:ast)
  expect(@result).to have_key(:uom)
  expect(@result).to have_key(:output)
  expect(@result[:tokens]).to be_a(Array)
  expect(@result[:tokens]).not_to be_empty
  expect(@result[:ast]).to be_a(WireGram::Core::Node)
  expect(@result[:uom]).to be_a(WireGram::Languages::Expression::UOM)
  expect(@result[:uom].root).not_to be_nil
  expect(@result[:output]).to be_a(String)
  expect(@result[:output]).not_to be_empty
end

Then('the expression output should be {string}') do |expected|
  expect(@last_output).to eq(expected)
end

Then('the expression output should be:') do |expected|
  expect(@last_output).to eq(expected)
end

Then('the expression output should match the fixture input') do
  expect(@last_output).to eq(@input)
end

Then('the expression errors should include:') do |table|
  errors = @result[:errors] || []
  types = errors.map { |error| error[:type] }
  table.hashes.each do |row|
    expect(types).to include(row.fetch('type').to_sym)
  end
end

Then('the expression tokens should include type and value fields') do
  expect(@tokens).to be_a(Array)
  expect(@tokens).not_to be_empty
  expect(@tokens.first).to have_key(:type)
  expect(@tokens.first).to have_key(:value)
end

Then('the expression AST should be a program node') do
  expect(@ast).to be_a(WireGram::Core::Node)
  expect(@ast.type).to eq(:program)
end

Then('the expression UOM should have a root') do
  expect(@uom).to be_a(WireGram::Languages::Expression::UOM)
  expect(@uom.root).not_to be_nil
end
