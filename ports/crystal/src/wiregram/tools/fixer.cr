# frozen_string_literal: true

require "../engines/transformer"

module WireGram
  module Tools
    # AutoFixer - Automatic code fixes
    class AutoFixer
      struct Fix
        getter name : String
        getter apply : Proc(WireGram::Core::Fabric, WireGram::Core::Fabric)

        def initialize(@name : String, @apply : Proc(WireGram::Core::Fabric, WireGram::Core::Fabric))
        end
      end

      getter fixes : Array(Fix)

      def initialize
        @fixes = [] of Fix
      end

      def initialize(&block : AutoFixer -> Nil)
        @fixes = [] of Fix
        block.call(self)
      end

      # Define a fix
      def fix(name : String, &block : WireGram::Core::Fabric -> WireGram::Core::Fabric)
        @fixes << Fix.new(name, block)
      end

      # Apply all fixes to a fabric
      def apply_fixes(fabric : WireGram::Core::Fabric)
        result_fabric = fabric

        @fixes.each do |fix|
          result_fabric = fix.apply.call(result_fabric)
        end

        result_fabric
      end

      # Apply a specific fix by name
      def apply_fix(fabric : WireGram::Core::Fabric, fix_name : String)
        fix = @fixes.find { |f| f.name == fix_name }
        return fabric unless fix

        fix.apply.call(fabric)
      end
    end
  end
end
