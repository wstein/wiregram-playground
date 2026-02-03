#!/usr/bin/env crystal

# Example: Require Path Transformation
# This demonstrates how the transpiler transforms Crystal require statements
# into Ruby require_relative statements with proper path mappings

require "../src/warp"

# Nested modules
require "../src/warp/cli/config"
require "../src/warp/cli/runner"

# Single quotes
require '../src/warp/lang/ruby'
require '../src/warp/lang/crystal'

# Different nesting levels
require "../../src/warp/backend"

# Non-src paths (also transformed but path unchanged)
require "../models/user"
require "../lib/helpers"

# Already correct (left as-is)
require_relative "./local_module"
require_relative "../lib/existing"

# Absolute paths (unchanged)
require "json"
require "logger"

puts "This Crystal file would be transpiled to Ruby with:"
puts "- All 'require' → 'require_relative'"
puts "- All '../src/' → '../lib/'"
puts "- Quote styles preserved (single/double)"
puts "- Non-src paths left as-is"
puts "- Absolute paths unchanged"
