# Control flow: if/unless, case/when, loops
if x > 10
  puts "big"
elsif x > 5
  puts "medium"
else
  puts "small"
end

puts "yes" unless false

case value
when 1, 2, 3
  puts "one to three"
when 4..6
  puts "four to six"
else
  puts "something else"
end

while counter < 10
  counter += 1
end

(1..5).each { |i| puts i }

x = 0
x += 1 until x == 10
