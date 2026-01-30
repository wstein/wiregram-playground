# Sorbet Type Annotations Corpus

# Basic method signatures
sig { params(x: Integer, y: String).returns(Integer) }
def basic_method(x, y)
  x + y.to_i
end

# Keyword arguments
sig { params(x: Integer, y: Integer).returns(Integer) }
def keyword_method(x:, y:)
  x + y
end

# Void return type
sig { params(name: String).void }
def log_name(name)
  puts name
end

# Optional parameters
sig { params(x: Integer, y: T.nilable(Integer)).returns(Integer) }
def optional_math(x, y = nil)
  x + (y || 0)
end

# Multi-line signature
sig do
  params(
    str: String,
    num: T.nilable(Integer)
  )
  .returns(String)
end
def complex_sig(str, num)
  "#{str}: #{num}"
end

# Class methods
sig { params(x: Integer).returns(String) }
def self.static_method(x)
  x.to_s
end

# Block parameters
sig { params(blk: T.proc.params(x: Integer).returns(String)).void }
def with_block(&blk)
  yield(1)
end

# Block that returns void
sig { params(blk: T.proc.void).void }
def run_block(&blk)
  blk.call
end

# Binding context for DSLs
sig { params(blk: T.proc.bind(Integer).void).void }
def dsl_runner(&blk)
  1.instance_eval(&blk)
end

# Instance variables
class MyObject
  extend T::Sig

  sig { params(name: String).void }
  def initialize(name)
    @name = T.let(name, String)
    @items = T.let([], T::Array[Integer])
  end
end

# Lazy initialization
sig { returns(String) }
def current_user
  @user ||= T.let(ENV['USER'], T.nilable(String))
end

# Constants
MAX_RETRIES = T.let(5, Integer)
NAMES = T.let(["a", "b"].freeze, T::Array[String])

# Class variables
class Counter
  @@count = T.let(0, Integer)
end

# Local variables
x = T.let(nil, T.nilable(Integer))
(1..5).each do |i|
  x = i if i.even?
end

# Abstract methods and interfaces
module Runnable
  extend T::Sig
  extend T::Helpers
  interface!

  sig { abstract.void }
  def run; end
end

class Task
  extend T::Sig
  include Runnable

  sig { override.void }
  def run
    puts "Running"
  end
end

class BaseJob
  extend T::Sig
  extend T::Helpers
  abstract!

  sig { abstract.returns(Integer) }
  def priority; end

  sig { overridable.void }
  def setup
    puts "Default setup"
  end
end

# Standard and collection types
T::Array[String]
T::Hash[Symbol, Integer]
T::Set[Integer]
T::Range[Integer]
T::Enumerator[String]

# Union and intersection types
sig { params(x: T.any(Integer, String)).void }
def print_value(x); end

sig { params(x: T.all(InterfaceA, InterfaceB)).void }
def process(x); end

# Type aliases
JsonType = T.type_alias { T.any(String, Integer, Float, T::Boolean, NilClass) }

sig { params(data: JsonType).void }
def process_json(data); end

# Generics
class Box
  extend T::Sig
  extend T::Generic

  Elem = type_member

  sig { params(val: Elem).void }
  def initialize(val)
    @val = val
  end
end

# Escape hatches
sig { params(x: T.untyped).returns(T.untyped) }
def dynamic_method(x)
  x.undefined_method
end

# Runtime assertions
x = T.must(maybe_nil_value)
y = T.cast(x, Integer)
z = T.unsafe(x).do_something

# Exhaustiveness
case type
when :a then 1
when :b then 2
else
  T.absurd(type)
end
