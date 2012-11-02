require_relative './type'
require_relative './terminal'

module Rtc::Types
    class SymbolType < Type
      include TerminalType
      attr_reader :symbol
      def initialize(sym)
        @symbol = sym
        super()
      end

      def has_method?(method)
        Symbol.method_defined?(method)
      end
      
      def eql?(other)
        other.instance_of?(SymbolType) and other.symbol == symbol
      end

      def map
        return self
      end
      
      def ==(other)
        eql?(other)
      end
      
      def hash
        symbol.to_s.hash
      end

      def each
        yield self
      end

      def to_s
        ":#{@symbol}"
      end
      
      def <=(other)
        if other.instance_of?(SymbolType)
          return eql?(other)
        elsif other.instance_of?(NominalType) and other.klass == Symbol
          return true
        else
          super
        end
      end
    end
end
