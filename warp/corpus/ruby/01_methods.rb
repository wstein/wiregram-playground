# Methods with various signatures
def add(a, b)
  a + b
end

def greet(name = "World")
  "Hello, #{name}!"
end

def sum(*args)
  args.reduce(0, :+)
end

def process(**kwargs)
  kwargs.each { |k, v| puts "#{k}: #{v}" }
end
