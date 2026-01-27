# frozen_string_literal: true

module WireGram
  module Core
    # Lightweight scanner backed by byte slices (StringScanner replacement).
    class Scanner
      getter pos : Int32
      getter matched : String?

      def initialize(@source : String)
        @bytes = @source.to_slice
        @pos = 0
        @matched = nil
        @match_options = @source.valid_encoding? ? Regex::MatchOptions::NO_UTF_CHECK : Regex::MatchOptions::None
      end

      def pos=(value : Int32)
        @pos = value
      end

      def scan(regex : Regex) : String?
        options = @match_options | Regex::MatchOptions::ANCHORED
        match = regex.match_at_byte_index(@source, @pos, options: options)
        return nil unless match

        @matched = match[0]
        @pos = match.byte_end
        @matched
      end

      def check(regex : Regex) : String?
        options = @match_options | Regex::MatchOptions::ANCHORED
        match = regex.match_at_byte_index(@source, @pos, options: options)
        return nil unless match

        @matched = match[0]
      end

      def skip(regex : Regex) : Int32?
        matched = scan(regex)
        matched ? matched.bytesize : nil
      end

      def scan_until(regex : Regex) : String?
        match = regex.match_at_byte_index(@source, @pos, options: @match_options)
        return nil unless match

        @matched = match[0]
        start = @pos
        @pos = match.byte_end
        @source.byte_slice(start, @pos - start)
      end
    end
  end
end
