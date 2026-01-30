# Heredoc string literals (edge case!)
def heredoc_simple
  text = <<-HEREDOC
    This is a heredoc
    with multiple lines
    and indentation
  HEREDOC
  text
end

def heredoc_with_interpolation
  name = "World"
  greeting = <<-GREETING
    Hello, #{name}!
    Welcome to Ruby.
  GREETING
  greeting
end

def heredoc_squiggly
  text = <<~HEREDOC
    Squiggly heredoc
    removes leading whitespace
    automatically
  HEREDOC
end

# Ruby 3.4: Complex Rescue Targets
# Rescue into an array index
begin
  raise
rescue => array
end

# Rescue into a zero-arity method call on an object
obj = Object.new
def obj.[]=(val); end
begin
  raise
rescue => obj[]
end
