# Simple Crystal code examples
# Tests basic literals, variables, and method calls

x = 42
y = "hello"
z = [1, 2, 3]

def greet(name : String) : String
  "Hello, #{name}!"
end

puts greet("World")

# Constants
MAGIC_NUMBER =   42
MAX_SIZE     = 1000
