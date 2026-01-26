# frozen_string_literal: true

Given('a ucl input:') do |input|
  @input = input
end

When('I process the ucl input') do
  @result = WireGram::Languages::Ucl.process(@input)
  @last_output = @result[:output]
end

Then('the ucl output should include:') do |table|
  table.raw.flatten.each do |fragment|
    expect(@last_output).to include(fragment)
  end
end
