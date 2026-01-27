# Minimal WEBrick stub to allow the CLI to compile in Crystal (PoC)

module WEBrick
  class Log
    def initialize(io = STDOUT)
    end
  end

  class HTTPServer
    def initialize(port : Int32 = 4567, logger : Log? = nil)
      @port = port
      @logger = logger
      @mounts = {} of String => Proc(String, String, Nil)
    end

    def mount_proc(path : String, &block)
      @mounts[path] = proc { |req, res| block.call(req, res); nil }
    end

    def shutdown
      # noop for stub
    end

    def start
      # noop for stub (not used in tokenize path)
    end
  end
end
