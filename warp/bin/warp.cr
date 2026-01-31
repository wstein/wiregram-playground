#!/usr/bin/env crystal
require "../src/warp"
require "../src/warp/cli/config"
require "../src/warp/cli/runner"
require "../src/warp/lang/ruby/annotations/annotation_extractor"
require "../src/warp/lang/ruby/annotations/sorbet_rbs_parser"
require "../src/warp/lang/ruby/annotations/rbs_generator"
require "../src/warp/lang/ruby/annotations/sorbet_rbi_generator"
require "../src/warp/lang/ruby/annotations/inline_rbs_injector"
require "../src/warp/lang/ruby/annotations/annotation_store"
require "../src/warp/lang/ruby/annotations/rbs_file_parser"
require "../src/warp/lang/ruby/annotations/rbi_file_parser"
require "../src/warp/lang/ruby/annotations/inline_rbs_parser"

exit Warp::CLI::Runner.run(ARGV)
