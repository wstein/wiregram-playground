# Blocks, lambdas, procs
[1, 2, 3].each { |n| puts n }

[1, 2, 3].map do |n|
  n * 2
end

add = lambda { |a, b| a + b }
add_proc = Proc.new { |a, b| a + b }

def yield_example
  yield(1, 2) if block_given?
end

yield_example { |a, b| puts a + b }

# Ruby 3.4: The 'it' Parameter
['a', 'b'].map { it.upcase }

# Ruby 3.4: Relaxed Float Parsing
val1 = 1.        #=> 1.0
val2 = 1.E-1     #=> 0.1

# Ruby 3.4: Large Integer Exponents
big_num = 10**10_000_000
