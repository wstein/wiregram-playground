# Blocks and Procs in Crystal

# Basic block
[1, 2, 3].each do |x|
  puts x * 2
end

# Block with inline syntax
[1, 2, 3].map { |x| x * 2 }

# Yield in methods
def with_timer(&)
  start = Time.local
  yield
  elapsed = Time.local - start
  puts "Took #{elapsed.total_seconds}s"
end

with_timer do
  puts "Doing something"
end

# Proc literals
add = ->(x : Int32, y : Int32) { x + y }
result = add.call(5, 3)

# Block parameters
def apply_twice(&block : -> Int32)
  block.call
  block.call
end

apply_twice { 42 }

# Enumerator methods
arr = [1, 2, 3, 4, 5]
evens = arr.select { |x| x.even? }
doubled = arr.map { |x| x * 2 }
sum = arr.reduce(0) { |acc, x| acc + x }
