require_relative './type'

module Rtc::Types
  
    # Represents a type parameter, for example, in Array<t>, t is a type
    # parameter.
    class TypeParameter < Type

        # The symbol used to define the type parameter.
        attr_accessor :symbol

        # Create a new type parameter with the given symbol.
        def initialize(symbol)
            @symbol = symbol
            super()
        end
        
        def is_terminal
          true
        end

        def replace_parameters(type_vars)
          if type_vars.has_key? symbol
            return type_vars[symbol]
          end
          self
        end

        def _to_actual_type
          self
        end

        def each
          yield self
        end

        # Return true if self is a subtype of other.
        #--
        # TODO(rwsims): Refine this as use cases become clearer.
        def <=(other)
          return other.instance_of?(TopType)
        end

        def map
          return self
        end

        def to_s
          "TParam<#{symbol.to_s}>"
        end
        
        def eql?(other)
          other.is_a?(TypeParameter) and other.symbol.eql?(@symbol)
        end        
    end
end
