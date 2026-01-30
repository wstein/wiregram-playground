module Warp
  module DOM
    # Bare DOM value types for JSON.
    alias Value = Nil | Bool | Int64 | Float64 | String | Array(Value) | Hash(String, Value)

    struct Result
      getter value : Value?
      getter error : Core::ErrorCode

      def initialize(@value : Value?, @error : Core::ErrorCode)
      end
    end
  end
end
