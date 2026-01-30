module Warp
  module Format
    def self.pretty(value : DOM::Value, indent : Int32 = 2, newline : String = "\n") : String
      build(value, pretty: true, indent: indent, newline: newline)
    end

    def self.minify(value : DOM::Value) : String
      build(value, pretty: false, indent: 0, newline: "")
    end

    private def self.build(value : DOM::Value, pretty : Bool, indent : Int32, newline : String) : String
      builder = String::Builder.new
      write_value(builder, value, pretty, indent, newline, 0)
      builder.to_s
    end

    private def self.write_value(
      io : String::Builder,
      value : DOM::Value,
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      case value
      when Nil
        io << "null"
      when Bool
        io << (value ? "true" : "false")
      when Int64
        io << value.to_s
      when Float64
        io << value.to_s
      when String
        io << '"'
        io << escape_string(value)
        io << '"'
      when Array
        write_array(io, value, pretty, indent, newline, level)
      when Hash
        write_object(io, value, pretty, indent, newline, level)
      end
    end

    private def self.write_array(
      io : String::Builder,
      value : Array(DOM::Value),
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      if value.empty?
        io << "[]"
        return
      end

      io << '['
      if pretty
        io << newline
      end

      value.each_with_index do |entry, idx|
        if pretty
          io << (" " * ((level + 1) * indent))
        end
        write_value(io, entry, pretty, indent, newline, level + 1)
        if idx < value.size - 1
          io << ','
          io << newline if pretty
        end
      end

      if pretty
        io << newline
        io << (" " * (level * indent))
      end
      io << ']'
    end

    private def self.write_object(
      io : String::Builder,
      value : Hash(String, DOM::Value),
      pretty : Bool,
      indent : Int32,
      newline : String,
      level : Int32
    ) : Nil
      if value.empty?
        io << "{}"
        return
      end

      io << '{'
      if pretty
        io << newline
      end

      entries = value.to_a
      entries.each_with_index do |(key, val), idx|
        if pretty
          io << (" " * ((level + 1) * indent))
        end
        io << '"'
        io << escape_string(key)
        io << '"'
        io << (pretty ? ": " : ":")
        write_value(io, val, pretty, indent, newline, level + 1)
        if idx < entries.size - 1
          io << ','
          io << newline if pretty
        end
      end

      if pretty
        io << newline
        io << (" " * (level * indent))
      end
      io << '}'
    end

    private def self.escape_string(value : String) : String
      builder = String::Builder.new
      value.each_char do |ch|
        case ch
        when '"'
          builder << "\\\""
        when '\\'
          builder << "\\\\"
        when '\b'
          builder << "\\b"
        when '\f'
          builder << "\\f"
        when '\n'
          builder << "\\n"
        when '\r'
          builder << "\\r"
        when '\t'
          builder << "\\t"
        else
          if ch.ord < 0x20
            builder << "\\u%04X" % ch.ord
          else
            builder << ch
          end
        end
      end
      builder.to_s
    end
  end
end
