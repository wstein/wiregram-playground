# Control flow structures in Crystal

# If/elsif/else
value = 42
if value > 100
  puts "Large"
elsif value > 50
  puts "Medium"
else
  puts "Small"
end

# Unless
unless value < 0
  puts "Non-negative"
end

# Case/when
case value
when 0
  puts "Zero"
when 1..50
  puts "Low"
when 51..100
  puts "Medium"
else
  puts "High"
end

# Loops
i = 0
while i < 3
  puts i
  i += 1
end

# Until
until i == 0
  puts i
  i -= 1
end

# For loop
for x in [1, 2, 3]
  puts x
end

# Break and next
[1, 2, 3, 4, 5].each do |x|
  next if x == 2
  break if x == 4
  puts x
end

# Ternary operator
status = value > 50 ? "High" : "Low"

# Logical operators
if value > 10 && value < 100
  puts "In range"
end
