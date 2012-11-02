require 'set'
require_relative './type'

module Rtc::Types

    # A type that is the union of a set of types. Values of a union type may be
    # of the type of any type in the set.
    class UnionType < Type
        # Returns a type representing the union of all the types in +types+.
        # Handles some special cases to simplify the resulting type:
        # 1. If +a+ and +b+ are both in +types+ and +a+ <= +b+, only +b+ will
        # remain in the returned type.
        # 2. If after removing supertypes as in 1 there is only one type left in
        # the list, it is returned directly.
        def self.of(types)
            return types[0] if types.size == 1

            t0 = types[0]
            types.each{|t| types.delete(t) if t.instance_of?(BottomType)}
            pairs = types.product(types)

            pairs.each do |t, u|
                # pairs includes [t, t] and [u, u], and since t <= t, skip
                # these.
                #  next if t.eql?(u) 
                next if t <= u and u <= t

                # pairs includes [t, u] and [u, t], so we don't do symmetric
                # checks.
                if t <= u
                    types.delete(t)
                end
            end

            return t0 if types == []
            return types[0] if types.size == 1
            return UnionType.new(types)
        end

        def each
          types.each {
            |t|
            yield t
          }
        end

        def has_method?(method)
          @types.all? {|t| t.has_method?(method)}
        end

        def map
          UnionType.of(types.map { |t| yield t })
        end

        # The set of all types in the union.
        attr_accessor :types

        def to_s  # :nodoc:
            "(#{@types.to_a.join(' or ')})"
        end

        def eql?(other)  # :nodoc:
            return false unless other.instance_of?(UnionType)
            return false unless other.types == @types
            true
        end
        def hash  # :nodoc:
            @types.hash
        end

        # Returns +true+ if +self+ subtypes +other+. A UnionType subtypes
        # another type if all the values in the union are subtypes of +other+.
        #--
        # This has the effect of deferring dealing with unions on the rhs of a
        # relation into the Type class. There may be better ways of doing this.
        def <=(other)
            @types.all? do |t|
                t <= other
            end
        end

        private

        # Creates a new UnionType that is the union of all the types in +type+.
        # The initializer is private since UnionTypes should be created via the
        # UnionType#of method.
        def initialize(types)
            @types = Set.new(types)
            super()
        end
    end
end
