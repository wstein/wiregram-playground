# Various comment styles
# Single line comment

def foo
  # Comment inside method
  bar  # Inline comment
end

=begin
  Multi-line comment
  using =begin/=end
  blocks
=end

def process
  # Comments help document code
  value = 42  # Answer to everything
  value
end

# Ruby 3.4: Incomplete Flip-Flops
if (1..) # Left side only
end

if (..1) # Right side only
end
