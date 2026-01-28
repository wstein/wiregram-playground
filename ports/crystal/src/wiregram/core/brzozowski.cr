# frozen_string_literal: true

module WireGram
  module Core
    # Brzozowski Derivatives Engine for high-performance regex matching.
    # It allows matching without building a full DFA upfront, by calculating
    # derivatives of the regular expression for each input byte.
    module Brzozowski
      abstract class Expression
        abstract def nullable? : Bool
        abstract def derive(char : UInt8) : Expression
      end

      class BEmpty < Expression
        def nullable? : Bool; false; end
        def derive(char : UInt8) : Expression; self; end
      end

      class BEpsilon < Expression
        def nullable? : Bool; true; end
        def derive(char : UInt8) : Expression; EMPTY; end
      end

      class BChar < Expression
        getter byte : UInt8
        def initialize(@byte : UInt8); end
        def nullable? : Bool; false; end
        def derive(char : UInt8) : Expression
          char == @byte ? EPSILON : EMPTY
        end
      end

      class BCharRange < Expression
        getter start_byte : UInt8
        getter end_byte : UInt8
        def initialize(@start_byte : UInt8, @end_byte : UInt8); end
        def nullable? : Bool; false; end
        def derive(char : UInt8) : Expression
          (char >= @start_byte && char <= @end_byte) ? EPSILON : EMPTY
        end
      end

      class BAlternation < Expression
        getter left : Expression, right : Expression
        def initialize(@left, @right); end
        def nullable? : Bool; @left.nullable? || @right.nullable?; end
        def derive(char : UInt8) : Expression
          BAlternation.new(@left.derive(char), @right.derive(char)).simplify
        end

        def simplify : Expression
          return @right if @left.is_a?(BEmpty)
          return @left if @right.is_a?(BEmpty)
          self
        end
      end

      class BConcatenation < Expression
        getter left : Expression, right : Expression
        def initialize(@left, @right); end
        def nullable? : Bool; @left.nullable? && @right.nullable?; end
        def derive(char : UInt8) : Expression
          d_left = BConcatenation.new(@left.derive(char), @right)
          if @left.nullable?
            BAlternation.new(d_left, @right.derive(char)).simplify
          else
            d_left
          end
        end
      end

      class BKleeneStar < Expression
        getter inner : Expression
        def initialize(@inner); end
        def nullable? : Bool; true; end
        def derive(char : UInt8) : Expression
          BConcatenation.new(@inner.derive(char), self)
        end
      end

      EMPTY = BEmpty.new
      EPSILON = BEpsilon.new

      # Simplified engine that uses the derivatives to match a pattern.
      class Engine
        property root : Expression

        def initialize(@root); end

        def match?(bytes : Slice(UInt8)) : Bool
          current = @root
          bytes.each do |b|
            current = current.derive(b)
            return false if current.is_a?(BEmpty)
          end
          current.nullable?
        end

        # GPU acceleration placeholder: On M4, we could theoretically batch match
        # many inputs against the same derivatives if we represented the engine as a
        # state-transition table computed on the fly.
      end
    end
  end
end
