module Rtc::Types
    # Abstract base class for all types. Takes care of assigning unique ids to
    # each type instance and maintains sets of constraint edges. This class
    # should never be instantiated directly.
    class Type
        @@next_id = 1

        # The unique id of this Type instance.
        attr_reader :id

        # Create a new Type instance.
        #
        # [+position+] the file & line where this type was instantiated.
        def initialize()
            @id = @@next_id
            @@next_id += 1
        end

        # Return true if +self+ is a subtype of +other+. Implemented in
        # subclasses.
        def <=(other)
            case other
            when UnionType
              if other.has_variables
                solution_found = false
                for i in other.types
                  if self <= i
                    raise Rtc::AmbiguousUnionException, "Ambiguous union detected" if solution_found
                    solution_found = true
                  end
                end
                solution_found
              else
                other.types.any? do |a|
                self <= a
              end
              end
            when IntersectionType
              others.types.any? do |a|
              self <= a
            end
            when TypeVariable
              return self <= other.get_type if other.instantiated
              return false unless other.solving             
              other.add_constraint(self)
              true
            when TopType
              true
            when TupleType
              raise Exception, '<= TupleType NOT implemented'
            else
              false
            end
        end

        def parameterized?
          false
        end

        def contains_free_variables?
          false
        end

        def free_vars
          []
        end

        def is_tuple
          false
        end

        def ==(other)  # :nodoc:
            eql?(other)
        end

        def eql?(other)  # :nodoc:
            return false unless other.instance_of?(Type)
            return @id == other.id
        end

        def hash  # :nodoc:
            @id
        end

        def to_s  # :nodoc:
            "Type #{@id}"
        end
        
        def inspect()
          "#{self.class.name}(#{@id}): #{to_s}" 
        end

        def replace_parameters(type_vars)
          map {
            |t|
            t.replace_parameters(type_vars)
          }
        end
        
        def has_variables
          self.each {
            |t|
            return true if t.is_a?(TypeVariable) and t.solving?
            t.has_variables unless t.is_terminal
          }
          false
        end
        
        def is_terminal
          false
        end

        def each
          raise "you must implement this method"
        end

        def map
          raise "you must implement this method"
        end

        def to_actual_type
          if not defined?(@actual_type)
            @actual_type = _to_actual_type
          end
          @actual_type
        end

        def _to_actual_type
          map {
            |t|
            t.to_actual_type
          }
        end

        # Used to simplify the type when proxying an object.  Namely removing
        # NilClass or FalseClass from unions, since nil and false cannot be
        # proxied.
        def proxy_simplify
          self
        end

        protected

        # Returns +true+ if +self+ could possibly be a subtype of +other+. It
        # need not be the case that +self+ *is* a subtype. This is used as a
        # heuristic when propagating constraints into an IntersectionType or out
        # of a Uniontype.
        #
        # By default, this just checks if +other+ is the same type as +self+.
        # Subclasses can override for more nuanced checking.
        def can_subtype?(other)
            other.instance_of?(self.class)
        end

    end




    
end  # module Rtc::Types
