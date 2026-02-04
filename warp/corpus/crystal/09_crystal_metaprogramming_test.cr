# Source: Metaprogramming Help - Crystal,,,

# Test Case 1: Overriding #new via extend and macro hooks
module ClassMethods
  macro extended
    def self.new(number : Int32)
      puts "Calling overridden new added from extend hook, arg is #{number}"
      instance = allocate
      instance.initialize(number)
      instance
    end
  end
end

class Foo
  extend ClassMethods
  @number : Int32

  def initialize(number)
    puts "Foo.initialize called with number #{number}"
    @number = number
  end
end

# Test Case 2: Generating Methods via method_missing Macro
class Hashr
  getter obj

  def initialize(json : Hash(String, JSON::Any) | JSON::Any)
    @obj = json
  end

  macro method_missing(key)
    def {{key.id}}
      value = obj[{{key.id.stringify}}]
      Hashr.new(value)
    end
  end

  def ==(other)
    obj == other
  end
end

# Test Case 3: Using previous_def for alias chaining
class Klass
  def salute
    puts "Calling method..."
    previous_def
  end
end
