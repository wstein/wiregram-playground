# frozen_string_literal: true
# typed: false

require 'sorbet-runtime'

# Methods with various signatures
sig { params(a: Integer, b: Integer).returns(Integer) }
def add(a, b)
  a + b
end

sig { params(name: String).returns(String) }
def greet(name = 'World')
  "Hello, #{name}!"
end

def sum(*args)
  args.reduce(0, :+)
end

def process(**kwargs)
  kwargs.each { |k, v| puts "#{k}: #{v}" }
end

# Ruby 3.4: Method Forwarding (including leading args)
def delegate(a, b, c)
  other_method(a, b, c)
end

def wrapper(_leading, a, b, c)
  delegate(a, b, c)
end
