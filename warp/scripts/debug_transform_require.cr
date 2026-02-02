s = File.read("src/warp.cr")

s = s.gsub(/\brequire(?!_relative)\s+(['"])\.\.\//, "require_relative \\1../")
s = s.gsub(/\brequire(?!_relative)\s+(['"])\./, "require_relative \\1./")

puts s.lines[20..60].join
