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
