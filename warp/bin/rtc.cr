# Ruby -> Crystal transpiler CLI

require "option_parser"
require "../src/warp"

module Warp
  module Lang
    module Ruby
      module RTC
        struct Options
          getter emit : String
          getter dry_run : Bool
          getter diagnostics : Bool
          getter input_path : String?

          def initialize(@emit : String, @dry_run : Bool, @diagnostics : Bool, @input_path : String?)
          end
        end

        def self.run(argv : Array(String))
          emit = "crystal"
          dry_run = false
          diagnostics = false
          input_path = nil

          OptionParser.parse(argv) do |opts|
            opts.banner = "usage: rtc [options] [file]"
            opts.on("--emit TYPE", "ast|ir|crystal (default: crystal)") { |v| emit = v }
            opts.on("--dry-run", "Parse and validate without emitting code") { dry_run = true }
            opts.on("--diagnostics", "Print diagnostics to STDERR") { diagnostics = true }
            opts.on("-h", "--help", "Show help") do
              puts opts
              exit
            end
          end

          input_path = argv.first?
          source = read_input(input_path)
          bytes = source.to_slice

          if dry_run
            result = Parser.parse(bytes)
            unless result.error.success?
              STDERR.puts "rtc: parse error #{result.error}"
              exit 1
            end
            puts "rtc: parse ok"
            exit 0
          end

          case emit
          when "ast"
            result = Parser.parse(bytes)
            unless result.error.success?
              STDERR.puts "rtc: parse error #{result.error}"
              exit 1
            end
            puts result.node.not_nil!.to_h
          when "ir"
            result = Parser.parse(bytes)
            unless result.error.success?
              STDERR.puts "rtc: parse error #{result.error}"
              exit 1
            end
            ir = IR::Builder.from_ast(result.node.not_nil!)
            puts "#{ir.kind} (children=#{ir.children.size})"
          else
            transpiled = Transpiler.transpile(bytes)
            if diagnostics && !transpiled.diagnostics.empty?
              transpiled.diagnostics.each { |d| STDERR.puts("rtc: #{d}") }
            end
            puts transpiled.output
            exit 1 unless transpiled.error.success?
          end
        end

        private def self.read_input(path : String?) : String
          if path && File.file?(path)
            File.read(path)
          elsif STDIN.tty?
            ""
          else
            STDIN.gets_to_end
          end
        end
      end
    end
  end
end

Warp::Lang::Ruby::RTC.run(ARGV)
