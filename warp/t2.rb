def basic_method(x, y) : Int32
  x + y.to_i
end
def keyword_method(x, y) : Int32
  x + y
end
def log_name(name) : Nil
    puts(name)
end
def optional_math(x, y) : Int32
  x + y || 0
end
def complex_sig(str, num) : String
  "#{str}: #{num}"
end
def self.static_method(x) : String
    x.to_s
end
def with_block(blk) : Nil
    yield(1)
end
def run_block(blk) : Nil
    blk.call
end
def dsl_runner(blk) : Nil
    1.instance_eval(&(blk))
end
class MyObject
    extend(T::Sig)
  def initialize(name) : Nil
    @name = name
    @items = []
  end
end
def current_user : String
  @user || =(ENV)
end
MAX_RETRIES = 5
NAMES = ["a", "b"].freeze
class Counter
  @@count = 0
end
x = nil
1.<missing>.<missing>
5
each()) do |i|
  x = i
    if i.even?
    # empty
  end
    module Runnable
        extend(T::Sig)
    extend(T::Helpers)
interface!
    def run : Nil
      ;
    end
  end
    class Task
        extend(T::Sig)
    include(Runnable)
    def run : Nil
            puts("Running")
    end
  end
    class BaseJob
        extend(T::Sig)
    extend(T::Helpers)
abstract!
    def priority : Int32
      ;
    end
    def setup : Nil
            puts("Default setup")
    end
  end
  T::Array
  [String]
  T::Hash
  [Symbol, Integer]
  T::Set
  [Integer]
  T::Range
  [Integer]
  T::Enumerator
  [String]
    def print_value(x) : Nil
    ;
  end
    def process(x) : Nil
    ;
  end
  JsonType = type_alias(T) do
    T.any(String, Integer, Float, T::Boolean, NilClass)
end
    def process_json(data) : Nil
    ;
  end
    class Box
        extend(T::Sig)
    extend(T::Generic)
Elem = type_member
    def initialize(val) : Nil
      @val = val
    end
  end
    def dynamic_method(x) : T
        x.undefined_method
  end
  x = T.must(maybe_nil_value)
  y = T.cast(x, Integer)
  z = T.unsafe(x).do_something
    case(type)
    when(:a, then(1))
    when(:b, then(2))
  else
    T.absurd(type)
end
