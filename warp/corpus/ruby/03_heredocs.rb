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
