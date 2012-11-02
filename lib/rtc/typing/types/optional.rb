require_relative './type'

module Rtc::Types
  
    # An object used to wrap a type for an optional argument to a procedure.
    # This does not represent a node in the constraint graph; constraints should
    # be generated on the +type+ attribute.
    class OptionalArg < Type
        attr_accessor :type

      def each
        yield type
      end

        def initialize(type)
            @type = type
          super()
        end
        
        def map
          OptionalArg.new(yield type)
        end

        def to_s
            "?(#{type})"
        end

        def eql?(other)
            other.instance_of?(OptionalArg) and type.eql?(other.type)
        end

        def hash
            23 + type.hash
        end
    end
end
