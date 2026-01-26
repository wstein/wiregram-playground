# frozen_string_literal: true

# Enable SimpleCov for Cucumber (feature) runs unless NO_COVERAGE is set
unless ENV['NO_COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    # Enable branch coverage reporting
    enable_coverage :branch

    add_filter '/features/'
    add_filter '/spec/'
    add_group 'Libraries', 'lib'
  end
end

require 'bundler/setup'
require 'json'
require 'rspec/expectations'
require 'stringio'
require 'tempfile'

$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)
require 'wiregram'
require 'wiregram/cli'
require 'wiregram/languages/expression'
require 'wiregram/languages/json'
require 'wiregram/languages/ucl'

World(RSpec::Matchers)
