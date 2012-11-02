require_relative './type'
require_relative './terminal'


module Rtc::Types    
    class BottomType < Type
      include TerminalType
      def hash
        13
      end

      def initialize()
        super()
      end

      def map
        return self
      end
      
      def each
        yield self
      end

      def has_method?(m)
        nil.respond_to?(m)
      end

      def to_s
        "b"
      end

      def eql?(other)
        other.instance_of?(BottomType)
      end

      def <=(other)
        # eql?(other)
        true
      end

      def self.instance
        return @@instance || (@@instance = BottomType.new)
      end
      
      @@instance = nil
    end
end
