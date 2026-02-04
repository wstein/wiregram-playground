# Crystal annotations for type checking and documentation

@[Deprecated("Use new_method instead")]
def old_method
  "deprecated"
end

@[Link("m")]
lib LibM
  fun sqrt(x : Float64) : Float64
end

@[Extern]
class ExternalClass
end

# Platform-specific code would need ifdef
# ifdef windows
#   fun windows_only
#     puts "Windows only"
#   end
# end

@[Raises(ArgumentError)]
def may_raise
  raise ArgumentError.new("error")
end

@[AlwaysInline]
def inline_method
  42
end

# Documented class with annotations
class AnnotatedClass
  def to_s
    "Annotated class"
  end
end
