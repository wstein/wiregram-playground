# frozen_string_literal: true
# typed: false

require 'sorbet-runtime'

# Regular expressions
T.let(/\d+/, Regexp)
T.let(%r{/path/to/file}, Regexp)
T.let(/(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/, Regexp)

def match_test(string)
  return unless string =~ /[0-9]+/

  puts 'Contains digits'
end

def gsub_example(text)
  text.gsub(/\s+/, '_')
end

# Ruby 3.4: Byte-based MatchData
match = 'foo'.match(/o/)
match.bytebegin(0) #=> 1
