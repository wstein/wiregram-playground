# frozen_string_literal: true
# typed: false

require 'sorbet-runtime'

# Class definitions
class Person
  sig { params(name: String, age: Integer).void }
  def initialize(name, age)
    @name = name
    @age = age
    @email = nil
  end

  sig { returns(String) }
  attr_accessor :name

  sig { params(name: String).void }

  sig { returns(Integer) }
  attr_reader :age

  sig { params(email: String).void }
  attr_writer :email

  sig { returns(String) }
  def greet
    "Hello, I'm #{@name}"
  end
end

class Employee < Person
  sig { params(name: String, age: Integer, salary: Integer).void }
  def initialize(name, age, salary)
    super(name, age)
    @salary = salary
  end

  sig { returns(Integer) }
  attr_accessor :salary

  sig { params(salary: Integer).void }
end

# Ruby 3.4: Reserved Constants Warning
# Emits warning in 3.4
module Ruby; end
