require "./cpu_detector"

module Warp::Parallel
  # Work item to be processed by worker pool
  struct WorkItem(T, R)
    getter data : T
    getter processor : Proc(T, R)
    getter is_simd_heavy : Bool

    def initialize(@data : T, @processor : Proc(T, R), @is_simd_heavy : Bool = false)
    end

    def process : R
      processor.call(data)
    end
  end

  # Result from worker pool processing
  struct WorkResult(R)
    getter result : R
    getter error : Exception?
    getter worker_id : Int32
    getter duration : Time::Span

    def initialize(@result : R, @error : Exception? = nil, @worker_id : Int32 = 0, @duration : Time::Span = Time::Span.zero)
    end

    def success? : Bool
      @error.nil?
    end
  end

  # SIMD-aware worker pool for parallel transpilation
  class WorkerPool(T, R)
    getter worker_count : Int32
    getter simd_capability : SIMDCapability

    private property workers : Array(Fiber)
    private property work_queue : Channel(WorkItem(T, R)?)
    private property simd_queue : Channel(WorkItem(T, R)?)
    private property result_queue : Channel(WorkResult(R))
    private property running : Bool

    def initialize(@worker_count : Int32 = CPUDetector.cpu_count)
      @simd_capability = CPUDetector.detect_simd
      @workers = [] of Fiber
      @work_queue = Channel(WorkItem(T, R)?).new(@worker_count * 2)
      @simd_queue = Channel(WorkItem(T, R)?).new(@worker_count)
      @result_queue = Channel(WorkResult(R)).new(@worker_count * 2)
      @running = false
    end

    # Start worker pool
    def start
      return if @running
      @running = true

      # Create workers with different capabilities
      @worker_count.times do |worker_id|
        # Determine if this worker should handle SIMD work
        # Workers 0 to N/2 handle SIMD, rest handle scalar
        can_simd = (worker_id < @worker_count / 2) && @simd_capability != SIMDCapability::None

        fiber = spawn do
          worker_loop(worker_id, can_simd)
        end

        @workers << fiber
      end
    end

    # Stop worker pool
    def stop
      return unless @running
      @running = false

      # Send shutdown signals
      @worker_count.times do
        @work_queue.send(nil)
        @simd_queue.send(nil)
      end

      @workers.clear
    end

    # Submit work to the pool
    def submit(data : T, simd_heavy : Bool = false, &block : T -> R)
      work_item = WorkItem.new(data, block, simd_heavy)

      if simd_heavy && @simd_capability != SIMDCapability::None
        @simd_queue.send(work_item)
      else
        @work_queue.send(work_item)
      end
    end

    # Get next result (blocking)
    def next_result : WorkResult(R)?
      @result_queue.receive?
    end

    # Process batch of items
    def process_batch(items : Array(T), simd_heavy : Bool = false, &block : T -> R) : Array(WorkResult(R))
      start

      # Submit all work
      items.each do |item|
        submit(item, simd_heavy, &block)
      end

      # Collect results
      results = [] of WorkResult(R)
      items.size.times do
        if result = next_result
          results << result
        end
      end

      stop
      results
    end

    private def worker_loop(worker_id : Int32, can_simd : Bool)
      loop do
        # Try SIMD queue first if capable
        work_item = if can_simd
                      @simd_queue.receive? || @work_queue.receive?
                    else
                      @work_queue.receive?
                    end

        break if work_item.nil? # Shutdown signal

        start_time = Time.monotonic

        begin
          result = work_item.process
          duration = Time.monotonic - start_time
          @result_queue.send(WorkResult.new(result, nil, worker_id, duration))
        rescue ex
          duration = Time.monotonic - start_time
          # Return error result with nil value (using default value for R)
          default_result = uninitialized R
          @result_queue.send(WorkResult.new(default_result, ex, worker_id, duration))
        end
      end
    end
  end
end
