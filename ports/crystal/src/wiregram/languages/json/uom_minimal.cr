require "json"

module WireGram
  module Languages
    module Json
      # Minimal UOM implementation to avoid compiler issues
      class Uom
        property root : Nil = nil
      end

      class ValueBase
      end

      class StringValue < ValueBase
      end

      class NumberValue < ValueBase
      end

      class BooleanValue < ValueBase
      end

      class NullValue < ValueBase
      end

      class ObjectValue < ValueBase
      end

      class ArrayValue < ValueBase
      end

      class ObjectItem
      end
    end
  end
end
