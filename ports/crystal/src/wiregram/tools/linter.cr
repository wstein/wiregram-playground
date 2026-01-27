# frozen_string_literal: true

require "../engines/analyzer"

module WireGram
  module Tools
    alias Violation = Hash(Symbol, String | WireGram::Core::Node | Int32 | Nil)
    alias ViolationResult = Violation | Array(Violation) | Nil

    # Linter - Declarative code linter
    class Linter
      struct Rule
        getter name : String
        getter severity : Symbol
        getter check : Proc(WireGram::Core::Fabric, ViolationResult)

        def initialize(@name : String, @severity : Symbol, @check : Proc(WireGram::Core::Fabric, ViolationResult))
        end
      end

      getter rules : Array(Rule)
      getter results : Array(Hash(Symbol, String | WireGram::Core::Node | Int32 | Symbol | Nil))

      def initialize
        @rules = [] of Rule
        @results = [] of Hash(Symbol, String | WireGram::Core::Node | Int32 | Symbol | Nil)
      end

      def initialize(&block : Linter -> Nil)
        @rules = [] of Rule
        @results = [] of Hash(Symbol, String | WireGram::Core::Node | Int32 | Symbol | Nil)
        block.call(self)
      end

      # Define a linting rule
      def rule(name : String, severity : Symbol = :warning, &block : WireGram::Core::Fabric -> ViolationResult)
        @rules << Rule.new(name, severity, block)
      end

      # Lint a fabric
      def lint(fabric : WireGram::Core::Fabric)
        @results = [] of Hash(Symbol, String | WireGram::Core::Node | Int32 | Symbol | Nil)

        @rules.each do |rule|
          violations = rule.check.call(fabric)
          items = case violations
                  when Array
                    violations
                  when Nil
                    [] of Violation
                  else
                    [violations] of Violation
                  end

          items.compact.each do |violation|
            @results << {
              rule: rule.name,
              severity: rule.severity,
              message: violation[:message] || "Violation of rule '#{rule.name}'",
              node: violation[:node],
              position: violation[:position]
            }
          end
        end

        @results
      end

      # Format results for display
      def format_results
        return "No issues found!" if @results.empty?

        output = [] of String
        output << "Found #{@results.size} issue(s):\n"

        @results.each_with_index do |result, i|
          output << "#{i + 1}. [#{result[:severity].to_s.upcase}] #{result[:rule]}"
          output << "   #{result[:message]}"
        end

        output.join("\n")
      end
    end
  end
end
