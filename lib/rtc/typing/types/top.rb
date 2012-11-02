require_relative './type'
require_relative './terminal'

module Rtc::Types
    class TopType < Type
      include TerminalType
      def initialize()
        super()
      end

      def to_s
        "t"
      end
      
      def self.instance
        return @@instance || (@@instance = TopType.new)
      end
      
      def eql?(other)
        other.instance_of?(TopType)
      end
      
      def map
        return self
      end

      def each
        yield self
      end

      def ==(other)
        eql?(other)
      end
      
      def hash
        17
      end
      
      def <=(other)
        if other.instance_of?(TopType)
          true
        else
          false
        end
      end

      @@instance = nil
    end
end
