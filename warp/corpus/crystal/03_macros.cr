# Crystal macros and meta-programming

# Basic macro definition
macro define_getter(name)
  def {{name}}
    @{{name}}
  end
end

# Macro with code generation
macro create_methods
  def foo_uppercase
    "foo".upcase
  end
  
  def bar_uppercase
    "bar".upcase
  end
  
  def baz_uppercase
    "baz".upcase
  end
end

create_methods

# Conditional macros
macro debug_log(value)
  {% if @type.has_constant?(:DEBUG) %}
    puts "Debug: #{{{value}}}"
  {% end %}
end

# Macro with expressions - simplified version
macro assert_type(var)
  {% if var.is_a?(String) %}
    true
  {% else %}
    false
  {% end %}
end
