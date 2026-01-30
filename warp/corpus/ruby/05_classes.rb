# Class definitions
class Person
  attr_accessor :name
  attr_reader :age
  attr_writer :email

  def initialize(name, age)
    @name = name
    @age = age
  end

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
