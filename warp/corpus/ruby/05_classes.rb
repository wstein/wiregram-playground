# typed: strict
# Class definitions
class Person
  attr_accessor :name
  attr_reader :age
  attr_writer :email

  sig { params(name: String, age: Integer).void }
  def initialize(name, age)
    @name = name
    @age = age
  end

  sig { returns(String) }
  def greet
    "Hello, I'm #{@name}"
  end
end

class Employee < Person
  def initialize(name, age, salary)
    super(name, age)
    @salary = salary
  end
end

# Ruby 3.4: Reserved Constants Warning
module Ruby; end  # Emits warning in 3.4
