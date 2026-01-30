# Complex real-world Ruby snippet
require 'json'

module DataProcessor
  class Pipeline
    def initialize(config = {})
      @config = config
      @data = []
    end

    def process(input)
      input.each do |item|
        transformed = transform(item)
        @data << transformed if valid?(transformed)
      end
      @data
    end

    private

    def transform(item)
      {
        id: item[:id],
        name: item[:name]&.upcase,
        active: item[:status] == 'active',
        metadata: JSON.parse(item[:meta])
      }
    end

    def valid?(item)
      item[:id] && item[:name]
    end
  end

  def self.run(data)
    pipeline = Pipeline.new
    pipeline.process(data)
  end
end

# Ruby 3.4: Ambiguous Syntax
# 'a' is a local variable, so 'puts a' is variable access
a = 0; puts a

# 'a' is unknown, parsed as method call `self.a`
puts a
