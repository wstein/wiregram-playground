# Crystal class definitions and instantiation

class Person
  @name : String
  @age : Int32

  def initialize(name : String, age : Int32)
    @name = name
    @age = age
  end

  def name : String
    @name
  end

  def age : Int32
    @age
  end

  def introduce
    "Hi, I'm #{@name}, #{@age} years old"
  end
end

# Inheritance
class Employee < Person
  @company : String

  def initialize(name : String, age : Int32, company : String)
    super(name, age)
    @company = company
  end

  def work
    "Working at #{@company}"
  end
end

# Module mixins
module Drawable
  def draw
    "Drawing..."
  end
end

class Shape
  include Drawable
end
