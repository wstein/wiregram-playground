require "digest/sha256"
require "json"

module Warp::Incremental
  # Hash computation for source files and dependencies
  module Hasher
    extend self

    # Compute SHA256 hash of source file content
    def hash_file(path : String) : String
      Digest::SHA256.hexdigest(File.read(path))
    end

    # Compute SHA256 hash of bytes
    def hash_bytes(bytes : Bytes) : String
      Digest::SHA256.hexdigest(bytes)
    end

    # Compute composite hash including dependencies
    def composite_hash(
      source_hash : String,
      warp_version : String,
      config_hash : String,
      dependency_hashes : Array(String) = [] of String,
    ) : String
      components = [source_hash, warp_version, config_hash] + dependency_hashes
      Digest::SHA256.hexdigest(components.join(":"))
    end

    # Hash configuration for cache key
    def hash_config(config_path : String?) : String
      if config_path && File.exists?(config_path)
        hash_file(config_path)
      else
        # Default config hash
        Digest::SHA256.hexdigest("default")
      end
    end
  end
end
