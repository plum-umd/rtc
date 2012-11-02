require_relative './type'
require 'rtc/tools/hash-builder.rb'

module Rtc::Types
    class TupleType < Type
      attr_reader :ordered_params
      attr_reader :size
      
      def initialize(arr)
        @ordered_params = arr
        @size = arr.size
        super()
      end

      def map
        TupleType.new(ordered_params.map {
                        |p|
                        yield p
                      })
      end

      def is_tuple
        true
      end

      def to_s
        "Tuple<[#{ordered_params.join(", ")}]>"
      end
      
      def inspect
        "#{self.class.name}(#{@id}): #{@ordered_params.inspect}" 
      end

      def each
        @ordered_params.each {
          |p|
          yield p
        }
      end

      def <=(other)
        case other
        when TupleType
          return false unless self.size == other.size
          
          i = 0
          
          for t in self.ordered_params
            return false if not t <= other.ordered_params[i]
            i += 1
          end
          
          true
        else
          super
        end
      end
      
      def hash
        builder = Rtc::HashBuilder.new(107, 157)
        builder.include("tuple")
        @ordered_params.each do |p|
          builder.include(p)
        end
        builder.get_hash
      end
    end
end
