module Warp
  VERSION = "0.1.0"

  # Returns the full version string including Crystal compiler version
  def self.version_string : String
    "Warp #{VERSION} (Crystal #{Crystal::VERSION})"
  end
end
