require "./cpu_detector"
require "./worker_pool"

module Warp::Parallel
  # Simplified parallel file processor for CLI
  class FileProcessor
    getter worker_count : Int32
    
    def initialize(@worker_count : Int32 = CPUDetector.cpu_count)
    end
    
    # Process files in parallel
    def process_files(files : Array(String), &block : String -> Nil) : Nil
      return files.each(&block) if @worker_count == 1
      
      completed = Channel(String?).new(@worker_count)
      work_queue = Channel(String?).new(files.size + @worker_count)
      
      # Enqueue all files
      files.each { |file| work_queue.send(file) }
      
      # Send shutdown signals
      @worker_count.times { work_queue.send(nil) }
      
      # Spawn workers
      @worker_count.times do |worker_id|
        spawn do
          loop do
            file = work_queue.receive
            break if file.nil?
            
            begin
              block.call(file)
            rescue ex
              # Log error but continue
              STDERR.puts "Worker #{worker_id} error processing #{file}: #{ex.message}"
            end
            
            completed.send(file)
          end
          
          completed.send(nil)  # Worker finished
        end
      end
      
      # Wait for all files to complete
      files.size.times do
        completed.receive
      end
      
      # Wait for all workers to finish
      @worker_count.times do
        completed.receive
      end
    end
  end
end
