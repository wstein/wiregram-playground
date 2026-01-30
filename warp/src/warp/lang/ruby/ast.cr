# Ruby AST: semantic nodes for transpilation

module Warp
  module Lang
    module Ruby
      module AST
        struct Node
          getter kind : NodeKind
          getter children : Array(Node)
          getter value : String?
          getter start : Int32
          getter length : Int32
          getter meta : Hash(String, String)?

          def initialize(
            @kind : NodeKind,
            @children : Array(Node) = [] of Node,
            @value : String? = nil,
            @start : Int32 = 0,
            @length : Int32 = 0,
            @meta : Hash(String, String)? = nil,
          )
          end

          def span_end : Int32
            @start + @length
          end

          def to_h
            {
              "kind"     => @kind.to_s,
              "value"    => @value,
              "start"    => @start,
              "length"   => @length,
              "meta"     => @meta,
              "children" => begin
                children = [] of String
                @children.each { |c| children << c.to_h.to_s }
                children
              end,
            }
          end
        end

        struct Result
          getter node : Node?
          getter error : Warp::Core::ErrorCode

          def initialize(@node : Node?, @error : Warp::Core::ErrorCode)
          end
        end
      end
    end
  end
end
