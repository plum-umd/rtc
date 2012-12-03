require 'set'
require_relative './type'

module Rtc::Types
    # Type that represents the intersection of two other types. The intersection
    # of two types is the type that supports all of the operations of both
    # types.
    class IntersectionType < Type
        # Return a type representing the intersection of all the types in
        # +types+. Handles some special cases to simplify the resulting type:
        # 1. If +a+ and +b+ are both in +types+ and +a+ <= +b+, only +a+ will
        #    remain in the returned type.
        # 2. If after removing supertypes as in 1 there is only one type left in
        #    the list, it is returned unchanged.
        def self.of(types)
            return types[0] if types.size == 1
            pairs = types.product(types)
            pairs.each do |t, u|
                # pairs includes [t, t] and [u, u], and since t <= t, skip
                # these.
                next if t.equal?(u)
                # pairs includes [t, u] and [u, t], so we don't do symmetric
                # checks.
                if t <= u
                    types.delete(u)
                end
            end
            return types[0] if types.size == 1
            return IntersectionType.new(types)
        end

        def contains_free_variables?
          types.reduce(false) { |r, t| r |= t.contains_free_variables?  }
        end

        def map
          IntersectionType.new(types.map {
            |t|
            yield t
          })
        end

        def each
          types.each {
            |t|
            yield t
          }
        end

        # The set of all the types intersected in this instance.
        attr_accessor :types

        # Returns +true+ if +self+ subtypes +other+. Other than TopType, an
        # IntersectionType can only subtype another IntersectionType. For two
        # IntersectionTypes +t+ and +u+, +t <= u+ iff for all +a+ in +u+, there
        # exists +b+ in +t+ such that +b <= a+.
        #
        # Note that this function is not precise: there could be types A, B and
        # C such that Intersection(A, B) < C, but neither A nor B <= C. This
        # implementation is conservative: if it returns +true+, then subtyping
        # definitely holds, but if it returns +false+, it only probably does not
        # hold.
        def <=(other)
            case other
            when IntersectionType
                other.types.all? do |t|
                    @types.any? do |u|
                        u <= t
                    end
                end
            else
                @types.all? do |t|
                    t <= other
                end
            end
        end

        def to_s  # :nodoc:
            "(#{@types.to_a.join(' and ')})"
        end

        def eql?(other)  # :nodoc:
            return false unless other.instance_of?(IntersectionType)
            return false unless other.types == @types
            true
        end

        def hash  # :nodoc:
            @types.hash
        end

        protected

        def can_subtype?(other)
            true
        end

        private

        # Create a new IntersectionType that is the intersection of all the
        # types in +types+. The initializer is private since IntersectionTypes
        # should be created via the IntersectionType#of method.
        def initialize(types)
            @types = Set.new(types)
            super()
        end
    end
end
