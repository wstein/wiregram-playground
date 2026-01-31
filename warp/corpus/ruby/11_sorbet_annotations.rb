# typed: false
# frozen_string_literal: true

require 'sorbet-runtime'

# Sorbet Type Annotations Corpus

module SorbetExamples
  extend T::Sig

  # Basic method signatures
  sig { params(x: Integer, y: String).returns(Integer) }
  def self.basic_method(x, y)
    x + y.to_i
  end

  # Keyword arguments
  sig { params(x: Integer, y: Integer).returns(Integer) }
  def self.keyword_method(x:, y:)
    x + y
  end

  # Void return type
  sig { params(name: String).void }
  def self.log_name(name)
    puts name
  end

  # Optional parameters
  sig { params(x: Integer, y: T.nilable(Integer)).returns(Integer) }
  def self.optional_math(x, y = nil)
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
  def self.complex_sig(str, num)
    "#{str}: #{num}"
  end

  # Class methods
  sig { params(x: Integer).returns(String) }
  def self.static_method(x)
    x.to_s
  end

  # Block parameters
  sig { params(blk: T.proc.params(x: Integer).void).void }
  def self.with_block
    yield(1)
  end

  # Block that returns void
  sig { params(blk: T.proc.void).void }
  def self.run_block(&blk)
    blk.call
  end

  # Binding context for DSLs
  sig { params(blk: T.proc.void).void }
  def self.dsl_runner(&blk)
    blk.call
  end

  # Instance variables
  class MyObject
    extend T::Sig

    sig { params(name: String).void }
    def initialize(name)
      @name = T.let(name, String)
      @items = T.let([], T::Array[Integer])
    end

    sig { returns(String) }
    attr_reader :name
  end

  # Lazy initialization
  sig { returns(T.nilable(String)) }
  def self.current_user
    @current_user ||= T.let(ENV['USER'], T.nilable(String))
  end

  # Constants
  MAX_RETRIES = T.let(5, Integer)
  NAMES = T.let(%w[a b].freeze, T::Array[String])

  # Class variables
  class Counter
    @@count = T.let(0, Integer)

    sig { returns(Integer) }
    def self.count
      @@count
    end

    sig { params(value: Integer).void }
    def self.count=(value)
      @@count = value
    end
  end

  # Local variables
  def self.local_variables_demo
    x = T.let(nil, T.nilable(Integer))
    (1..5).each do |i|
      x = i if i.even?
    end
    x
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
      puts 'Running'
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
      puts 'Default setup'
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
  def self.print_value(x); end

  sig { params(x: T.all(InterfaceA, InterfaceB)).void }
  def self.process(x); end

  # Type aliases
  JsonType = T.type_alias { T.any(String, Integer, Float, T::Boolean, NilClass) }

  sig { params(data: JsonType).void }
  def self.process_json(data); end

  # Generics
  class Box
    extend T::Sig
    extend T::Generic

    # Using untyped here to avoid duplicate type_member in this demo
    sig { params(val: T.untyped).void }
    def initialize(val)
      @val = val
    end

    sig { returns(T.untyped) }
    def value
      @val
    end
  end

  # Escape hatches
  sig { params(x: T.untyped).returns(T.untyped) }
  def self.dynamic_method(x)
    x
  end

  # Runtime assertions
  # Example with actual values
  x = T.must(5)
  T.cast(x, Integer)
  T.unsafe(x).to_s

  # Exhaustiveness
  symbol = :a
  case symbol
  when :a then 1
  when :b then 2
  end

  # Main method to demonstrate all functionality
  def self.main
    puts '=== Sorbet Type Annotations Demo ==='

    # Basic method signatures
    puts "\nBasic method signatures:"
    result = SorbetExamples.basic_method(5, '10')
    puts "basic_method(5, '10') = #{result} (#{result.class})"

    # Keyword arguments
    puts "\nKeyword arguments:"
    result = SorbetExamples.keyword_method(x: 3, y: 4)
    puts "keyword_method(x: 3, y: 4) = #{result} (#{result.class})"

    # Void return type
    puts "\nVoid return type:"
    SorbetExamples.log_name('John Doe')

    # Optional parameters
    puts "\nOptional parameters:"
    result = SorbetExamples.optional_math(5)
    puts "optional_math(5) = #{result} (#{result.class})"
    result = SorbetExamples.optional_math(5, 3)
    puts "optional_math(5, 3) = #{result} (#{result.class})"

    # Multi-line signature
    puts "\nMulti-line signature:"
    result = SorbetExamples.complex_sig('Hello', 42)
    puts "complex_sig('Hello', 42) = #{result} (#{result.class})"

    # Class methods
    puts "\nClass methods:"
    result = SorbetExamples.static_method(123)
    puts "static_method(123) = #{result} (#{result.class})"

    # Block parameters
    puts "\nBlock parameters:"
    SorbetExamples.with_block { |x| puts "Block received: #{x}" }

    # Block that returns void
    puts "\nBlock that returns void:"
    SorbetExamples.run_block { puts 'Running block' }

    # Binding context for DSLs
    puts "\nBinding context for DSLs:"
    SorbetExamples.dsl_runner { puts "DSL context: #{self}" }

    # Instance variables
    puts "\nInstance variables:"
    obj = SorbetExamples::MyObject.new('Test')
    puts "MyObject created with name: #{obj.name}"

    # Lazy initialization
    puts "\nLazy initialization:"
    result = SorbetExamples.current_user
    puts "current_user = #{result} (#{result.class})"

    # Constants
    puts "\nConstants:"
    puts "MAX_RETRIES = #{MAX_RETRIES} (#{MAX_RETRIES.class})"
    puts "NAMES = #{NAMES} (#{NAMES.class})"

    # Class variables
    puts "\nClass variables:"
    Counter.count = 10
    puts "Counter count = #{Counter.count}"

    # Local variables
    puts "\nLocal variables:"
    x = SorbetExamples.local_variables_demo
    (1..5).each do |i|
      puts "Local variable x = #{x} (#{x.class})" if i.even?
    end

    # Abstract methods and interfaces
    puts "\nAbstract methods and interfaces:"
    task = Task.new
    task.run

    # Standard and collection types
    puts "\nStandard and collection types:"
    array = T::Array[String].new
    array << 'Hello'
    array << 'World'
    puts "Array: #{array} (#{array.class})"

    hash = T::Hash[Symbol, Integer].new
    hash[:a] = 1
    hash[:b] = 2
    puts "Hash: #{hash} (#{hash.class})"

    # Union and intersection types
    puts "\nUnion and intersection types:"
    SorbetExamples.print_value(42)
    SorbetExamples.print_value('Hello')

    # Type aliases
    puts "\nType aliases:"
    SorbetExamples.process_json('Hello')
    SorbetExamples.process_json(42)

    # Generics
    puts "\nGenerics:"
    box = Box.new('Hello')
    puts "Box contains: #{box.value}"

    # Escape hatches
    puts "\nEscape hatches:"
    begin
      SorbetExamples.dynamic_method('test')
    rescue NoMethodError => e
      puts "Caught expected error: #{e.message[0..50]}..."
    end

    # Runtime assertions
    puts "\nRuntime assertions:"
    puts "T.must(5) = #{T.must(5)}"
    puts "T.cast(5, Integer) = #{T.cast(5, Integer)}"
    puts "T.unsafe(5).to_s = #{T.unsafe(5)}"

    # Exhaustiveness
    puts "\nExhaustiveness:"
    symbol = :a
    puts "case symbol = #{case symbol when :a then 1 when :b then 2 end}"

    puts "\n=== Demo completed ==="
  end
end

# Run the main method
SorbetExamples.main if __FILE__ == $PROGRAM_NAME
