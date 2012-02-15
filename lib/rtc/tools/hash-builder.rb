# A builder class to help create composite hash codes. Idea taken from
# HashCodeBuilder in the Apache Commons library.
#
# Author:: Ryan W Sims (rwsims@umd.edu)

module Rtc

    # A builder for creating hash codes for classes with internal state that
    # needs to influence the hash.
    class HashBuilder

        # Initializer.
        #
        # [+initial+] The initial value for the hash, should be prime and
        #             different for every class. Must be non-zero.
        # [+constant+] The constant use to "fold" each value into the hash;
        #              should be prime and different for every class. Must be
        #              non-zero.
        def initialize(initial, constant)
            if initial == 0
                raise(ArgumentError, "Initial value must be nonzero.")
            end
            if constant == 0
                raise(ArgumentError, "Initial value must be nonzero.")
            end
            @hash = initial
            @constant = constant
        end

        # Includes +field+ in the hash code.
        def include(field)
            @hash += @constant * field.hash
        end

        # Returns the computed hash.
        def get_hash
            @hash
        end
    end
end  # module Rtc
