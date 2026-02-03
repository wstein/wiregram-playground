# Complex Crystal code with multiple features

require "json"

module API
  class Request
    @method : String
    @url : String
    @headers : Hash(String, String)
    @body : String?

    def initialize(method : String, url : String)
      @method = method
      @url = url
      @headers = {} of String => String
    end

    def add_header(key : String, value : String)
      @headers[key] = value
      self
    end

    def with_body(body : String?)
      @body = body
      self
    end

    def send(&block : Response -> Void) : Void
      response = Response.new(200, "{}")
      yield response
    end
  end

  class Response
    @status : Int32
    @body : String

    def initialize(status : Int32, body : String)
      @status = status
      @body = body
    end

    def status : Int32
      @status
    end

    def json : JSON::Any
      JSON.parse(@body)
    end
  end
end

# Usage
request = API::Request.new("GET", "https://api.example.com/data")
request.add_header("Authorization", "Bearer token")
request.add_header("Content-Type", "application/json")

request.send do |response|
  if response.status == 200
    puts "Success: #{response.json}"
  end
end

# Pattern matching
case 42
when Int32
  puts "Integer"
when String
  puts "String"
end
