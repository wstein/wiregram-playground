require "json"
require "file_utils"
require "./hasher"

module Warp::Incremental
  # Cache entry metadata
  struct CacheEntry
    include JSON::Serializable

    property source_path : String
    property source_hash : String
    property composite_hash : String
    property output_path : String
    property timestamp : Int64
    property warp_version : String
    property dependencies : Array(String)

    def initialize(
      @source_path,
      @source_hash,
      @composite_hash,
      @output_path,
      @timestamp = Time.utc.to_unix,
      @warp_version = Warp::VERSION,
      @dependencies = [] of String,
    )
    end

    def expired?(current_hash : String) : Bool
      @composite_hash != current_hash
    end
  end

  # Incremental cache manager
  class Cache
    CACHE_DIR     = ".warp/cache"
    METADATA_FILE = ".warp/cache/metadata.json"

    getter cache_dir : String
    getter metadata : Hash(String, CacheEntry)
    getter hits : Int32 = 0
    getter misses : Int32 = 0

    def initialize(@cache_dir : String = CACHE_DIR)
      @metadata = load_metadata
    end

    # Check if source file has cached output
    def lookup(source_path : String, composite_hash : String) : CacheEntry?
      if entry = @metadata[source_path]?
        if entry.expired?(composite_hash)
          @misses += 1
          return nil
        end

        # Verify cached output exists
        if File.exists?(entry.output_path)
          @hits += 1
          return entry
        end
      end

      @misses += 1
      nil
    end

    # Store transpiled output in cache
    def store(
      source_path : String,
      source_hash : String,
      composite_hash : String,
      output_content : String,
      dependencies : Array(String) = [] of String,
    ) : String
      # Create cache directory structure
      FileUtils.mkdir_p(cache_dir)

      # Use hash-based path for output
      output_path = cache_output_path(composite_hash)
      FileUtils.mkdir_p(File.dirname(output_path))

      # Write cached output
      File.write(output_path, output_content)

      # Store metadata
      entry = CacheEntry.new(
        source_path,
        source_hash,
        composite_hash,
        output_path,
        dependencies: dependencies
      )

      @metadata[source_path] = entry
      save_metadata

      output_path
    end

    # Invalidate cache entry
    def invalidate(source_path : String)
      if entry = @metadata.delete(source_path)
        File.delete(entry.output_path) if File.exists?(entry.output_path)
        save_metadata
      end
    end

    # Clear entire cache
    def clear
      @metadata.clear
      FileUtils.rm_rf(cache_dir) if File.exists?(cache_dir)
      FileUtils.mkdir_p(cache_dir)
      save_metadata
    end

    # Get cache statistics
    def stats : String
      total = @hits + @misses
      hit_rate = total > 0 ? (@hits.to_f / total * 100).round(1) : 0.0

      "Cache: #{@hits} hits, #{@misses} misses (#{hit_rate}% hit rate)"
    end

    # Detect vendor branch and adjust cache strategy
    def in_vendor_branch? : Bool
      if File.exists?(".git")
        branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
        branch.starts_with?("vendor/")
      else
        false
      end
    end

    private def cache_output_path(hash : String) : String
      # Store in hash-based directory structure (git-like)
      prefix = hash[0..1]
      suffix = hash[2..3]
      File.join(cache_dir, "sha256", prefix, suffix, hash)
    end

    private def load_metadata : Hash(String, CacheEntry)
      return {} of String => CacheEntry unless File.exists?(METADATA_FILE)

      json = File.read(METADATA_FILE)
      Hash(String, CacheEntry).from_json(json)
    rescue
      {} of String => CacheEntry
    end

    private def save_metadata
      FileUtils.mkdir_p(File.dirname(METADATA_FILE))
      File.write(METADATA_FILE, @metadata.to_json)
    end
  end
end
