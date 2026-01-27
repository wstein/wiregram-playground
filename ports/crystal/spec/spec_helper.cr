require "spec"
require "../src/wiregram"
require "./support/snapshot_helper"

struct ExpectationWrapper(T)
  def initialize(@value : T)
  end

  def to(matcher)
    @value.should matcher
  end

  def not_to(matcher)
    @value.should_not matcher
  end
end

def expect(value)
  ExpectationWrapper.new(value)
end
