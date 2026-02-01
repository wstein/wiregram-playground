module Warp::CLI
  # Progress indicator for multi-file transpilation operations
  class ProgressBar
    getter total : Int32
    getter current : Int32
    getter current_file : String?
    getter start_time : Time

    private property width : Int32 = 50
    private property last_render : String = ""

    def initialize(@total : Int32)
      @current = 0
      @current_file = nil
      @start_time = Time.utc
    end

    def update(current : Int32, file : String? = nil)
      @current = current
      @current_file = file
      render
    end

    def increment(file : String? = nil)
      @current += 1
      @current_file = file
      render
    end

    def finish
      @current = @total
      render
      puts "" # New line after completion
    end

    private def render
      return if ENV["CI"]? || ENV["NO_PROGRESS"]? # Skip in CI or when disabled
      return if @total == 0

      percentage = (@current.to_f / @total * 100).to_i
      filled = (width * @current / @total).to_i
      empty = width - filled

      bar = "[#{"=" * filled}#{" " * empty}]"
      status = "#{@current}/#{@total} (#{percentage}%)"

      elapsed = Time.utc - start_time
      rate = @current.to_f / elapsed.total_seconds
      eta_seconds = rate > 0 ? (@total - @current).to_f / rate : 0.0
      eta = format_duration(eta_seconds)

      line = "\r\e[KTranspiling #{bar} #{status}"
      line += " | ETA: #{eta}" if @current < @total && eta_seconds > 0

      if file = @current_file
        # Truncate long paths
        display_file = file.size > 60 ? "...#{file[-57..-1]}" : file
        line += "\n  Current: #{display_file}"
      end

      # Only print if changed to avoid flicker
      if line != @last_render
        print line
        print "\e[A" if @current_file # Move cursor up if we printed file name
        STDOUT.flush
        @last_render = line
      end
    end

    private def format_duration(seconds : Float64) : String
      return "0s" if seconds < 1

      minutes = (seconds / 60).to_i
      remaining_seconds = (seconds % 60).to_i

      if minutes > 0
        "#{minutes}m #{remaining_seconds}s"
      else
        "#{remaining_seconds}s"
      end
    end
  end
end
