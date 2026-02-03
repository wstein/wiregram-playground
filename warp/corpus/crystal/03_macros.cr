# Crystal macros and meta-programming

# Basic macro definition
macro define_getter(name)
  def {{name}}
    @{{name}}
  end
end

# Macro with code generation
macro create_methods(names)
  {% for name in names %}
    def {{name}}_uppercase
      "{{name}}".upcase
    end
  {% end %}
end

create_methods(["foo", "bar", "baz"])

# Conditional macros
macro debug_log(value)
  {% if @type.has_constant?(:DEBUG) %}
    puts "Debug: #{{{value}}}"
  {% end %}
end

# Macro with expressions
macro assert_type(var, type)
  {% if {{var}}.is_a?({{type}}) %}
    true
  {% else %}
    raise "Type mismatch"
  {% end %}
end
