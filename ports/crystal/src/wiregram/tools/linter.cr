# frozen_string_literal: true

require_relative '../engines/analyzer'

module WireGram
  module Tools
    # Linter - Declarative code linter
    class Linter
      attr_reader :rules, :results

      def initialize(&block)
        @rules = []
        @results = []
        instance_eval(&block) if block_given?
      end

      # Define a linting rule
      def rule(name, severity: :warning, &block)
        @rules << { name: name, severity: severity, check: block }
      end

      # Lint a fabric
      def lint(fabric)
        @results = []

        @rules.each do |rule|
          violations = rule[:check].call(fabric)
          violations = [violations] unless violations.is_a?(Array)

          violations.compact.each do |violation|
            @results << {
              rule: rule[:name],
              severity: rule[:severity],
              message: violation[:message] || "Violation of rule '#{rule[:name]}'",
              node: violation[:node],
              position: violation[:position]
            }
          end
        end

        @results
      end

      # Format results for display
      def format_results
        return 'No issues found!' if @results.empty?

        output = []
        output << "Found #{@results.length} issue(s):\n"

        @results.each_with_index do |result, i|
          output << "#{i + 1}. [#{result[:severity].upcase}] #{result[:rule]}"
          output << "   #{result[:message]}"
        end

        output.join("\n")
      end
    end
  end
end
