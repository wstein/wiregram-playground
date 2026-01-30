# String literals and interpolation
single_quoted = 'single quoted string'
double_quoted = "double quoted string"
interpolated = "Value: #{1 + 2}"
escaped = "Escaped: \n\t\""

percent_string = %q(percent quoted)
percent_interpolated = %Q(percent #{1 + 1})

symbol = :symbol_literal
symbol_interpolated = :"symbol_#{42}"
