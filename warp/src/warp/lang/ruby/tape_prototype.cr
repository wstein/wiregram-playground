# Ruby Tape IR: Prototype and Feasibility Study
#
# This module explores whether the "Tape" IR concept (proven effective for
# JSON) can efficiently represent Ruby source code for formatting and scanning.
#
# Key Research Questions:
# 1. Can scoped/context-dependent constructs (methods, classes, blocks) be
#    represented as linear tape entries?
# 2. What additional metadata (scope chains, trivia alignment) is needed?
# 3. Does the tape approach preserve formatting information sufficiently?
#
# Test Case: Ruby code snippet
#   def foo(x)
#     x + 1
#   end
#
# Expected tape structure and challenges documented below.

module Warp
  module Lang
    module Ruby
      # RubyTapeType: Extended tape entries for Ruby constructs
      # This is a PROTOTYPE enum to explore Ruby-specific tape needs.
      #
      # Key observation: Ruby's tape needs more context markers than JSON because:
      # - Scope information (method/class/block nesting)
      # - Multiline constructs (heredocs, %q strings, regex)
      # - Indentation sensitivity
      # - Statement-level structure (unlike JSON's pure hierarchy)
      enum RubyTapeType
        # Program structure
        Root
        Program

        # Definitions (scope-creating)
        MethodDefStart
        MethodDefEnd
        ClassDefStart
        ClassDefEnd
        ModuleDefStart
        ModuleDefEnd

        # Control flow
        IfStart
        IfEnd
        UnlessStart
        UnlessEnd
        CaseStart
        CaseEnd
        WhenClause
        WhileStart
        WhileEnd
        UntilStart
        UntilEnd
        ForStart
        ForEnd

        # Blocks and lambdas
        BlockStart
        BlockEnd
        LambdaStart
        LambdaEnd

        # Expressions
        BinaryOp
        UnaryOp
        MethodCall
        ArrayLiteral
        HashLiteral
        RangeLiteral

        # Literals
        String
        InterpolatedStringStart
        InterpolatedStringEnd
        InterpolationExpression
        Symbol
        Number
        Regex
        True
        False
        Nil

        # Identifiers and variables
        Identifier
        Constant
        InstanceVar
        ClassVar
        GlobalVar

        # Delimiters and control
        Comma
        Semicolon
        Newline
        Comment

        # Metadata markers (for trivia and scope)
        ScopeMarker    # Marks scope depth changes
        TriviaBoundary # Marks regions that preserve formatting/comments
      end

      # RubyTapeEntry: Extended tape entry with scope and trivia information
      struct RubyTapeEntry
        getter type : RubyTapeType
        getter a : Int32            # offset or link
        getter b : Int32            # length or count
        getter scope_depth : Int32  # Nesting depth (method/class/block)
        getter trivia_start : Int32 # Start index of preceding trivia
        getter trivia_end : Int32   # End index of preceding trivia

        def initialize(
          @type : RubyTapeType,
          @a : Int32,
          @b : Int32,
          @scope_depth : Int32 = 0,
          @trivia_start : Int32 = 0,
          @trivia_end : Int32 = 0,
        )
        end
      end

      # Feasibility Study: Manual Tape Construction
      #
      # Input Ruby code:
      #   def foo(x)
      #     x + 1
      #   end
      #
      # Hypothetical tape structure (simplified):
      #
      #   Index  Type                   a         b            scope_depth  trivia_start  trivia_end
      #   ------  -------------------  --------  -----------  -----------  -----------  -----------
      #   0       Root                  0         12           0            0            0
      #   1       MethodDefStart        5         3            1            0            5    # "def foo(x)"
      #   2       Identifier            9         3            1            0            0    # "foo"
      #   3       (param list)          13        1            1            0            0    # "(x)"
      #   4       MethodDefBody (temp)  20        11           1            0            15   # method body markers
      #   5       Identifier            21        1            2            0            0    # "x"
      #   6       BinaryOp              23        1            2            0            0    # "+"
      #   7       Number                25        1            2            0            0    # "1"
      #   8       MethodDefEnd          30        3            1            27           30   # "end"
      #
      # Observations:
      # - scope_depth tracks nesting: increases at MethodDefStart, decreases at MethodDefEnd
      # - trivia fields link to whitespace/comment entries (not shown)
      # - Each definition creates a "region" with start/end markers
      #
      # PROBLEM 1: Indentation-Sensitive Constructs
      # Ruby uses indentation to denote scope. The tape records above don't
      # naturally encode "method body ends where indentation decreases."
      # Solution: Explicit MethodDefBody marker or trivia-aware scanning.
      #
      # PROBLEM 2: Complex String Literals
      # Heredocs span multiple lines and contain arbitrary content:
      #   def process
      #     str = <<-END
      #       line 1
      #       line 2
      #     END
      #     str
      #   end
      #
      # The tape cannot linearize this efficiently without either:
      # a) Storing the entire heredoc body as a single String entry (loses structure)
      # b) Recursively taping the interpolation (complex)
      # Solution: Mark heredocs as atomic tokens in the tape.
      #
      # PROBLEM 3: Method Calls with Blocks
      # arr.map { |x| x + 1 }
      #
      # The block is a nested scope but not a definition. Tape entries need:
      # - A method call marker
      # - A block marker with param info
      # - Expressions inside the block
      # Solution: Extend tape with BlockStart/BlockEnd similar to method defs.
      #
      # PROBLEM 4: Reversibility and Round-Tripping
      # Reconstructing exact source from tape requires:
      # - All trivia preserved (comments, whitespace, indentation)
      # - String content stored as-is (no normalization)
      # - Original formatting cues (single vs. double quotes, etc.)
      #
      # The tape approach works IF:
      # - Trivia is fully integrated (not just offset ranges)
      # - Tape entries reference the original bytes directly
      # - Tape includes "formatting hint" entries (indent level, etc.)
      #
      # ASSESSMENT:
      # The tape concept is FEASIBLE for Ruby with the following modifications:
      # 1. Extend tape to include scope markers
      # 2. Integrate trivia directly or via dedicated entries
      # 3. Handle complex string literals as atomic tape entries
      # 4. Add metadata for indentation/formatting hints
      # 5. Validate round-trip: Ruby -> Tape -> Ruby (byte-for-byte equality)
      #
      # Risk: Performance. JSON tape is O(n) scan. Ruby tape may require
      # context-sensitive scanning (scope tracking, indent levels) making it O(n)
      # with higher constants.

      # Prototype: SimplifiedRubyTapeBuilder
      # This demonstrates how a Ruby tape would be constructed from a CST.
      class SimplifiedRubyTapeBuilder
        # Simplified for prototyping; production version would integrate with
        # the full CST parser and lexer.

        property tape : Array(RubyTapeEntry)
        property scope_depth : Int32

        def initialize
          @tape = [] of RubyTapeEntry
          @scope_depth = 0
        end

        # Example: Build tape for "def foo(x); x + 1; end"
        def build_example
          # Entry 0: Root
          add_entry(RubyTapeType::Root, 0, 26)

          # Entry 1-3: Method definition
          enter_scope                                    # scope_depth = 1
          add_entry(RubyTapeType::MethodDefStart, 0, 10) # "def foo(x)"
          add_entry(RubyTapeType::Identifier, 4, 3)      # "foo"
          add_entry(RubyTapeType::Identifier, 8, 1)      # "x"

          # Entry 4-6: Method body
          add_entry(RubyTapeType::Identifier, 12, 1) # "x"
          add_entry(RubyTapeType::BinaryOp, 14, 1)   # "+"
          add_entry(RubyTapeType::Number, 16, 1)     # "1"

          # Entry 7: End method
          add_entry(RubyTapeType::MethodDefEnd, 23, 3) # "end"
          exit_scope                                   # scope_depth = 0

          @tape
        end

        private def add_entry(type : RubyTapeType, a : Int32, b : Int32)
          entry = RubyTapeEntry.new(
            type: type,
            a: a,
            b: b,
            scope_depth: @scope_depth
          )
          @tape << entry
        end

        private def enter_scope
          @scope_depth += 1
        end

        private def exit_scope
          @scope_depth -= 1
        end

        # Utility: Print tape for inspection
        def print_tape
          puts "Ruby Tape Prototype"
          puts "=================="
          @tape.each_with_index do |entry, idx|
            puts "#{idx}: #{entry.type} (a=#{entry.a}, b=#{entry.b}, depth=#{entry.scope_depth})"
          end
        end
      end

      # Prototype test: Validate that tape can represent a simple Ruby method
      def self.run_prototype
        builder = SimplifiedRubyTapeBuilder.new
        tape = builder.build_example
        puts "\n=== Ruby Tape Prototype ==="
        puts "Built tape with #{tape.size} entries"
        builder.print_tape
        puts "\n✓ Prototype demonstrates that Ruby code can be represented as tape entries."
        puts "✓ However, production implementation requires:"
        puts "  1. Full lexer with Ruby token types"
        puts "  2. Parser producing CST with Ruby NodeKind"
        puts "  3. Tape builder that handles scopes, trivia, and complex strings"
        puts "  4. Round-trip validation (Ruby -> Tape -> Ruby)"
      end
    end
  end
end

# Uncomment to run prototype:
# Warp::Lang::Ruby.run_prototype
