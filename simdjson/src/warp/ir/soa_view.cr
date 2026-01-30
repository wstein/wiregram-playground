module Warp
  module IR
    # SoA view over the tape for hot scanning paths.
    struct SoAView
      getter types : Array(TapeType)
      getter a : Array(Int32)
      getter b : Array(Int32)

      def initialize(@types : Array(TapeType), @a : Array(Int32), @b : Array(Int32))
      end

      def self.from(doc : Document) : SoAView
        tape = doc.tape
        size = tape.size
        types = Array(TapeType).new(size)
        a = Array(Int32).new(size)
        b = Array(Int32).new(size)
        tape.each do |entry|
          types << entry.type
          a << entry.a
          b << entry.b
        end
        new(types, a, b)
      end
    end

    class Document
      def soa_view : SoAView
        SoAView.from(self)
      end
    end
  end
end
