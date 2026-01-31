# typed: false
# frozen_string_literal: true

# Various comment styles
# Single line comment
require 'sorbet-runtime'

def foo
  # Comment inside method
  bar # Inline comment
end

#   Multi-line comment
#   using =begin/=end
#   blocks

def process
  # Comments help document code
  42 # Answer to everything
end

# Ruby 3.4: Incomplete Flip-Flops (commented out for Sorbet)
# if 1.. # Left side only
# end
#
# if ..1 # Right side only
# end
