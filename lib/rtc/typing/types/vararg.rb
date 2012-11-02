require_relative './type'

module Rtc::Types
      # An object used to represent a variable number of arguments of a single type.
    # This doesn't represent a node in the constraint graph; constraints
    # should be generated on the +type+ attribute.
    class Vararg < Type
        attr_accessor :type

        def initialize(type)
            @type = type
          super()
        end

        def to_s
            "*(#{type})"
        end

        def eql?(other)
            other.instanceof?(VarargType) and type.eql?(other.type)
        end

        def hash
            31 + type.hash
        end
        
        def each
          yield type
        end
        
        def map
          Vararg.new(yield type)
        end

        def <=(other)
          if other.instance_of(Vararg)
            type <= other.type
          else
            super(other)
          end
        end
    end
end
