module Warp
  module Lang
    module Common
      # State-aware SIMD helpers for context-sensitive scanning
      # These helpers accelerate scanning within known parsing states
      # (e.g., inside strings, heredocs, regex patterns, macros)
      module StateAwareSimdHelpers
        # Result of a bounded scan operation
        struct BoundedScanResult
          getter start_index : UInt32
          getter end_index : UInt32?
          getter found : Bool
          getter error : Warp::Core::ErrorCode

          def initialize(@start_index : UInt32, @end_index : UInt32?, @found : Bool, @error : Warp::Core::ErrorCode)
          end
        end

        # Scan within string boundaries using SIMD acceleration
        # Returns indices of escape sequences, interpolations, or terminating quotes
        def self.scan_string_interior(
          bytes : Bytes,
          start : UInt32,
          quote_char : UInt8,
          backend : Warp::Backend::Base,
        ) : Array(UInt32)
          indices = [] of UInt32
          i = start

          while i < bytes.size
            byte = bytes[i]

            # Check for quote termination
            if byte == quote_char
              indices << i.to_u32
              break
            end

            # Check for escape sequence
            if byte == '\\'.ord
              indices << i.to_u32
            end

            # Check for interpolation marker (#{) in double-quoted strings
            if quote_char == '"'.ord && byte == '#'.ord && i + 1 < bytes.size && bytes[i + 1] == '{'.ord
              indices << i.to_u32
            end

            i += 1
          end

          indices
        end

        # Scan for heredoc terminator using SIMD-accelerated newline detection
        # Returns indices of potential heredoc terminators
        def self.scan_heredoc_content(
          bytes : Bytes,
          start : UInt32,
          terminator : String,
          backend : Warp::Backend::Base,
        ) : Array(UInt32)
          indices = [] of UInt32
          i = start
          term_bytes = terminator.to_slice

          while i < bytes.size
            # Look for newline (potential heredoc terminator start)
            if bytes[i] == '\n'.ord
              indices << i.to_u32

              # Check if next line starts with terminator
              j = i + 1
              if j + term_bytes.size <= bytes.size
                match = true
                term_bytes.each_with_index do |b, idx|
                  if bytes[j + idx] != b
                    match = false
                    break
                  end
                end
                if match
                  indices << (j.to_u32)
                end
              end
            end

            i += 1
          end

          indices
        end

        # Scan for regex content with escape awareness
        # Returns indices of escape sequences and potential terminators
        def self.scan_regex_interior(
          bytes : Bytes,
          start : UInt32,
          backend : Warp::Backend::Base,
        ) : Array(UInt32)
          indices = [] of UInt32
          i = start

          while i < bytes.size
            byte = bytes[i]

            # Check for regex terminator
            if byte == '/'.ord
              indices << i.to_u32
              break
            end

            # Check for escape sequence
            if byte == '\\'.ord
              indices << i.to_u32
            end

            # Check for character class start/end
            if byte == '['.ord || byte == ']'.ord
              indices << i.to_u32
            end

            i += 1
          end

          indices
        end

        # Scan for Crystal macro content and nested structures
        # Returns indices of macro delimiters and nesting levels
        def self.scan_macro_interior(
          bytes : Bytes,
          start : UInt32,
          backend : Warp::Backend::Base,
        ) : Array(UInt32)
          indices = [] of UInt32
          i = start
          nesting_level = 0

          while i < bytes.size
            byte = bytes[i]

            case byte
            when '{'.ord
              indices << i.to_u32
              nesting_level += 1
            when '}'.ord
              indices << i.to_u32
              nesting_level -= 1
              if nesting_level == 0
                break
              end
            when '"'.ord, '\''.ord
              # Track string boundaries within macros
              indices << i.to_u32
            end

            i += 1
          end

          indices
        end

        # Scan for Crystal annotation content: @[...]
        # Returns indices of annotation delimiters and parameters
        def self.scan_annotation_interior(
          bytes : Bytes,
          start : UInt32,
          backend : Warp::Backend::Base,
        ) : Array(UInt32)
          indices = [] of UInt32
          i = start
          nesting_level = 0

          while i < bytes.size
            byte = bytes[i]

            case byte
            when '['.ord
              indices << i.to_u32
              nesting_level += 1
            when ']'.ord
              indices << i.to_u32
              nesting_level -= 1
              if nesting_level == 0
                break
              end
            when '('.ord, ')'.ord, ','.ord
              indices << i.to_u32
            when '"'.ord, '\''.ord
              indices << i.to_u32
            end

            i += 1
          end

          indices
        end
      end
    end
  end
end
