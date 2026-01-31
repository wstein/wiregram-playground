# Crystal -> Ruby type mapping utilities (Phase 2)

module Warp
  module Lang
    module Crystal
      module TypeMapping
        def self.to_rbs(type_str : String?) : String
          return "untyped" unless type_str
          t = type_str.strip

          # Nilable types: String? -> String?
          if t.ends_with?("?")
            inner = t[0...-1]
            return "#{to_rbs(inner)}?"
          end

          # Union types: A | B
          if t.includes?("|")
            parts = t.split("|").map(&.strip)
            return parts.map { |p| to_rbs(p) }.join(" | ")
          end

          # Generic types: Array(T), Hash(K, V), Set(T), Tuple(...)
          if (md = t.match(/^Array\((.+)\)$/))
            return "Array[#{to_rbs(md[1])}]"
          end

          if (md = t.match(/^Hash\((.+),\s*(.+)\)$/))
            return "Hash[#{to_rbs(md[1])}, #{to_rbs(md[2])}]"
          end

          if (md = t.match(/^Set\((.+)\)$/))
            return "Set[#{to_rbs(md[1])}]"
          end

          if (md = t.match(/^Tuple\((.+)\)$/))
            parts = md[1].split(",").map(&.strip).map { |p| to_rbs(p) }
            return "[#{parts.join(", ")}]"
          end

          if (md = t.match(/^NamedTuple\((.+)\)$/))
            return "{ #{md[1]} }"
          end

          case t
          when "Int32", "Int64", "UInt32", "UInt64"
            "Integer"
          when "Float32", "Float64"
            "Float"
          when "Bool"
            "bool"
          when "Nil"
            "nil"
          else
            t
          end
        end

        def self.to_sorbet(type_str : String?) : String
          return "T.untyped" unless type_str
          t = type_str.strip

          # Nilable types: String? -> T.nilable(String)
          if t.ends_with?("?")
            inner = t[0...-1]
            return "T.nilable(#{to_sorbet(inner)})"
          end

          # Union types: A | B -> T.any(A, B)
          if t.includes?("|")
            parts = t.split("|").map(&.strip)
            return "T.any(#{parts.map { |p| to_sorbet(p) }.join(", ")})"
          end

          # Generic types: Array(T), Hash(K, V), Set(T)
          if (md = t.match(/^Array\((.+)\)$/))
            return "T::Array[#{to_sorbet(md[1])}]"
          end

          if (md = t.match(/^Hash\((.+),\s*(.+)\)$/))
            return "T::Hash[#{to_sorbet(md[1])}, #{to_sorbet(md[2])}]"
          end

          if (md = t.match(/^Set\((.+)\)$/))
            return "T::Set[#{to_sorbet(md[1])}]"
          end

          case t
          when "Int32", "Int64", "UInt32", "UInt64"
            "Integer"
          when "Float32", "Float64"
            "Float"
          when "Bool"
            "T::Boolean"
          when "Nil"
            "NilClass"
          else
            t
          end
        end
      end
    end
  end
end
