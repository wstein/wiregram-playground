module Warp
  module DOM
    class Builder
      alias ErrorCode = Core::ErrorCode
      alias TapeType = IR::TapeType

      private class Frame
        getter kind : Symbol
        getter object : Hash(String, Value)?
        getter array : Array(Value)?
        property pending_key : String?

        def self.object(obj : Hash(String, Value)) : Frame
          new(:object, obj, nil)
        end

        def self.array(arr : Array(Value)) : Frame
          new(:array, nil, arr)
        end

        private def initialize(@kind : Symbol, @object : Hash(String, Value)?, @array : Array(Value)?)
        end
      end

      private struct ValueResult
        getter value : Value?
        getter error : ErrorCode

        def initialize(@value : Value?, @error : ErrorCode)
        end
      end

      private struct StringResult
        getter value : String?
        getter error : ErrorCode

        def initialize(@value : String?, @error : ErrorCode)
        end
      end

      def self.build(doc : IR::Document) : Result
        iter = doc.iterator
        frames = [] of Frame
        root : Value? = nil

        while (entry = iter.next_entry)
          case entry.type
          when TapeType::Root
            next
          when TapeType::StartObject
            obj = Hash(String, Value).new
            root_result = attach_value(obj, frames, root)
            return Result.new(nil, root_result.error) unless root_result.error.success?
            root = root_result.value
            frames << Frame.object(obj)
          when TapeType::EndObject
            return Result.new(nil, ErrorCode::TapeError) if frames.empty?
            frame = frames.pop
            return Result.new(nil, ErrorCode::TapeError) unless frame.kind == :object
            return Result.new(nil, ErrorCode::TapeError) if frame.pending_key
          when TapeType::StartArray
            arr = [] of Value
            root_result = attach_value(arr, frames, root)
            return Result.new(nil, root_result.error) unless root_result.error.success?
            root = root_result.value
            frames << Frame.array(arr)
          when TapeType::EndArray
            return Result.new(nil, ErrorCode::TapeError) if frames.empty?
            frame = frames.pop
            return Result.new(nil, ErrorCode::TapeError) unless frame.kind == :array
          when TapeType::Key
            return Result.new(nil, ErrorCode::TapeError) if frames.empty?
            frame = frames.last
            return Result.new(nil, ErrorCode::TapeError) unless frame.kind == :object
            slice = iter.slice(entry)
            return Result.new(nil, ErrorCode::TapeError) unless slice
            key_result = unescape_string(slice)
            return Result.new(nil, key_result.error) unless key_result.error.success?
            frame.pending_key = key_result.value
          when TapeType::String
            slice = iter.slice(entry)
            return Result.new(nil, ErrorCode::TapeError) unless slice
            str_result = unescape_string(slice)
            return Result.new(nil, str_result.error) unless str_result.error.success?
            root_result = attach_value(str_result.value.not_nil!, frames, root)
            return Result.new(nil, root_result.error) unless root_result.error.success?
            root = root_result.value
          when TapeType::Number
            slice = iter.slice(entry)
            return Result.new(nil, ErrorCode::TapeError) unless slice
            num_result = parse_number(slice)
            return Result.new(nil, num_result.error) unless num_result.error.success?
            root_result = attach_value(num_result.value.not_nil!, frames, root)
            return Result.new(nil, root_result.error) unless root_result.error.success?
            root = root_result.value
          when TapeType::True
            root_result = attach_value(true, frames, root)
            return Result.new(nil, root_result.error) unless root_result.error.success?
            root = root_result.value
          when TapeType::False
            root_result = attach_value(false, frames, root)
            return Result.new(nil, root_result.error) unless root_result.error.success?
            root = root_result.value
          when TapeType::Null
            root_result = attach_value(nil, frames, root)
            return Result.new(nil, root_result.error) unless root_result.error.success?
            root = root_result.value
          end
        end

        return Result.new(root, ErrorCode::Success) if root
        Result.new(nil, ErrorCode::TapeError)
      end

      private def self.attach_value(value : Value, frames : Array(Frame), root : Value?) : ValueResult
        if frames.empty?
          return ValueResult.new(value, ErrorCode::Success)
        end

        frame = frames.last
        case frame.kind
        when :array
          frame.array.not_nil! << value
          ValueResult.new(root, ErrorCode::Success)
        when :object
          key = frame.pending_key
          return ValueResult.new(root, ErrorCode::TapeError) unless key
          frame.object.not_nil![key] = value
          frame.pending_key = nil
          ValueResult.new(root, ErrorCode::Success)
        else
          ValueResult.new(root, ErrorCode::TapeError)
        end
      end

      private def self.parse_number(slice : Bytes) : ValueResult
        text = String.new(slice)
        if text.includes?('.') || text.includes?('e') || text.includes?('E')
          ValueResult.new(text.to_f64, ErrorCode::Success)
        else
          int_val = text.to_i64?
          return ValueResult.new(int_val, ErrorCode::Success) if int_val
          ValueResult.new(text.to_f64, ErrorCode::Success)
        end
      end

      private def self.unescape_string(bytes : Bytes) : StringResult
        unless bytes.includes?('\\'.ord)
          return StringResult.new(String.new(bytes), ErrorCode::Success)
        end

        builder = String::Builder.new
        i = 0
        while i < bytes.size
          c = bytes[i]
          if c != '\\'.ord
            builder << c.chr
            i += 1
            next
          end

          i += 1
          return StringResult.new(nil, ErrorCode::StringError) if i >= bytes.size
          esc = bytes[i]

          case esc
          when '"'.ord
            builder << '"'
            i += 1
          when '\\'.ord
            builder << '\\'
            i += 1
          when '/'.ord
            builder << '/'
            i += 1
          when 'b'.ord
            builder << '\b'
            i += 1
          when 'f'.ord
            builder << '\f'
            i += 1
          when 'n'.ord
            builder << '\n'
            i += 1
          when 'r'.ord
            builder << '\r'
            i += 1
          when 't'.ord
            builder << '\t'
            i += 1
          when 'u'.ord
            code = read_hex4(bytes, i + 1)
            return StringResult.new(nil, ErrorCode::StringError) if code < 0
            i += 5
            if code >= 0xDC00 && code <= 0xDFFF
              return StringResult.new(nil, ErrorCode::StringError)
            elsif code >= 0xD800 && code <= 0xDBFF
              return StringResult.new(nil, ErrorCode::StringError) if i + 1 >= bytes.size
              return StringResult.new(nil, ErrorCode::StringError) unless bytes[i] == '\\'.ord && bytes[i + 1] == 'u'.ord
              low = read_hex4(bytes, i + 2)
              return StringResult.new(nil, ErrorCode::StringError) if low < 0
              return StringResult.new(nil, ErrorCode::StringError) unless low >= 0xDC00 && low <= 0xDFFF
              code = 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00)
              i += 6
            end
            return StringResult.new(nil, ErrorCode::StringError) if code > 0x10FFFF
            builder << code.chr
          else
            return StringResult.new(nil, ErrorCode::StringError)
          end
        end

        StringResult.new(builder.to_s, ErrorCode::Success)
      end

      private def self.read_hex4(bytes : Bytes, start : Int32) : Int32
        return -1 if start + 3 >= bytes.size
        code = 0
        4.times do |offset|
          value = hex_value(bytes[start + offset])
          return -1 if value < 0
          code = (code << 4) | value
        end
        code
      end

      private def self.hex_value(byte : UInt8) : Int32
        case byte
        when '0'.ord..'9'.ord
          (byte - '0'.ord).to_i
        when 'a'.ord..'f'.ord
          (10 + byte - 'a'.ord).to_i
        when 'A'.ord..'F'.ord
          (10 + byte - 'A'.ord).to_i
        else
          -1
        end
      end
    end
  end
end
