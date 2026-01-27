# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'wiregram'
  spec.version = '0.1.0'
  spec.authors = ['Werner Stein']
  spec.email = ['werner.stein@gmail.com']
  spec.summary = 'WireGram - A universal, declarative framework for code analysis and transformation'
  spec.description = <<~DESC
    WireGram treats source code as a reversible digital fabric, providing a high-fidelity
    engine for processing any structured language. It includes lexers, parsers, and
    transformation engines for multiple languages (Expression, JSON, UCL).
  DESC
  spec.homepage = 'https://github.com/wstein/wiregram-playground'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.files = Dir[
    'lib/**/*.rb',
    'sig/**/*.rbs',
    'LICENSE',
    'README.md',
    'Rakefile'
  ]

  spec.executables = ['wiregram']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rbs', '~> 3.10'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'cucumber', '~> 10.2'
  spec.add_development_dependency 'rubocop', '~> 1.82'
  spec.add_development_dependency 'rubocop-ast', '~> 1.49'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'simplecov', '~> 0.22.0'
  spec.add_development_dependency 'yard', '~> 0.9.38'
end
