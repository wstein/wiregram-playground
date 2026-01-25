# frozen_string_literal: true

# Enable coverage for test runs by default. Set NO_COVERAGE=1 to disable.
unless ENV['NO_COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_group 'Libraries', 'lib'
  end
  SimpleCov.at_exit do
    SimpleCov.result.format!
  end
end

require 'bundler/setup'
require 'rspec'

# Add lib to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Require the main module
require 'wiregram'
require 'wiregram/languages/ucl'

# Load support files
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  require 'timeout'

  # Fail fast on tests that hang — set per-example timeout (seconds)
  default_timeout = (ENV['SPEC_TIMEOUT'] || 60).to_i
  config.around(:each) do |ex|
    Timeout.timeout(default_timeout) { ex.run }
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
