# frozen_string_literal: true

Given('a temp file with content:') do |content|
  tempfile = Tempfile.new('wiregram_cli')
  tempfile.write(content)
  tempfile.flush
  @tempfile = tempfile
  @tempfile_path = tempfile.path
end

When('I run the CLI with args:') do |table|
  args = table.raw.flatten.map do |arg|
    arg == '<tempfile>' ? @tempfile_path : arg
  end
  run_cli(args)
end

Then('the CLI exit status should be {int}') do |status|
  expect(@cli_exit_status).to eq(status)
end

Then('the CLI stdout should include:') do |table|
  table.raw.flatten.each do |fragment|
    expect(@cli_stdout).to include(fragment)
  end
end

Then('the CLI stderr should include:') do |table|
  table.raw.flatten.each do |fragment|
    expect(@cli_stderr).to include(fragment)
  end
end

When('I query available CLI languages') do
  @available_languages = WireGram::CLI::Languages.available
end

Then('the available CLI languages should include:') do |table|
  expected = table.raw.flatten
  expected.each do |lang|
    expect(@available_languages).to include(lang)
  end
end

When('I resolve the CLI language module {string}') do |language|
  @cli_language = language
  @cli_language_module = WireGram::CLI::Languages.module_for(language)
end

Then('the resolved module should be the {string} language module') do |language|
  expect(@cli_language_module).to eq(language_module(language))
end

When('I process {string} with the CLI language module') do |input|
  @cli_result = @cli_language_module.process(input)
end

Then('the CLI language process result should include tokens, ast, output') do
  expect(@cli_result).to have_key(:tokens)
  expect(@cli_result).to have_key(:ast)
  expect(@cli_result).to have_key(:output)
end

When('I tokenize {string} with the CLI language module') do |input|
  @cli_tokens = @cli_language_module.tokenize(input)
end

Then('the CLI language tokens should be an array') do
  expect(@cli_tokens).to be_a(Array)
end

When('I parse {string} with the CLI language module') do |input|
  @cli_ast = @cli_language_module.parse(input)
end

Then('the CLI language AST should be a node') do
  expect(@cli_ast).to be_a(WireGram::Core::Node)
end
