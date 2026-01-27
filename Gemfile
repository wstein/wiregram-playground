# frozen_string_literal: true

source 'https://rubygems.org'

gem 'webrick', '~> 1.9'

# Development & test dependencies
group :development, :test do
  gem 'rake', '~> 13.0'
  gem 'tapioca', require: false
  gem 'sorbet', '~> 0.6.12897'
  gem 'sorbet-runtime', '~> 0.6.12897'

  # Testing
  gem 'cucumber', '~> 10.2'
  gem 'rspec', '~> 3.13'
  gem 'simplecov', '~> 0.22.0'

  # Tooling / linting / language server
  gem 'rbs', '~> 3.10'
  gem 'rubocop', '~> 1.82'
  gem 'ruby-lsp', '~> 0.26.5'

  # Runtime helpers required for some dev tooling and generators
  gem 'sexp_processor'
  gem 'drb', require: false

  # Docs
  gem 'yard', '~> 0.9.38'
end
