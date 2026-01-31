# typed: false
# frozen_string_literal: true

require 'sorbet-runtime'

# Heredoc string literals (edge case!)
def heredoc_simple
  <<-HEREDOC
    This is a heredoc
    with multiple lines
    and indentation
  HEREDOC
end

def heredoc_with_interpolation
  name = 'World'
  <<-GREETING
    Hello, #{name}!
    Welcome to Ruby.
  GREETING
end

def heredoc_squiggly
  <<~HEREDOC
    Squiggly heredoc
    removes leading whitespace
    automatically
  HEREDOC
end

# Ruby 3.4: Complex Rescue Targets
# Rescue into an array index
begin
  raise
rescue StandardError
end

# Rescue into a zero-arity method call on an object
obj = Object.new
def obj.[]=(val); end
begin
  raise
rescue StandardError => obj[]
end
