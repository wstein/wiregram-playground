# frozen_string_literal: true

require_relative '../engines/transformer'

module WireGram
  module Tools
    # AutoFixer - Automatic code fixes
    class AutoFixer
      attr_reader :fixes

      def initialize(&block)
        @fixes = []
        instance_eval(&block) if block_given?
      end

      # Define a fix
      def fix(name, &block)
        @fixes << { name: name, apply: block }
      end

      # Apply all fixes to a fabric
      def apply_fixes(fabric)
        result_fabric = fabric
        
        @fixes.each do |fix|
          result_fabric = fix[:apply].call(result_fabric)
        end

        result_fabric
      end

      # Apply a specific fix by name
      def apply_fix(fabric, fix_name)
        fix = @fixes.find { |f| f[:name] == fix_name }
        return fabric unless fix

        fix[:apply].call(fabric)
      end
    end
  end
end
