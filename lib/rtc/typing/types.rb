# Classes for representing the various types recognized by rtc.
#
# Author:: Ryan W Sims (rwsims@umd.edu)

require 'set'
require 'singleton'

require 'rtc/tools/hash-builder.rb'

module Rtc::Types

    # Abstract base class for all types. Takes care of assigning unique ids to
    # each type instance and maintains sets of constraint edges. This class
    # should never be instantiated directly.
    class Type
        @@next_id = 1
        @@instances = []

        # Set of all Type instances created, useful for iterating over all
        # vertices (types) in the constraint graph.
        def self.instances
            @@instances
        end

        # Reset type ID counter and list of instances.
        def self.reset
            @@instances = []
            @@next_id = 1
        end

        # The unique id of this Type instance.
        attr_reader :id

        # Create a new Type instance.
        #
        # [+position+] the file & line where this type was instantiated.
        def initialize()
            @id = @@next_id
            @@next_id += 1
            @@instances << self
        end

        # Return true if +self+ is a subtype of +other+. Implemented in
        # subclasses.
        def <=(other)
            case other
            when UnionType
              other.types.any? do |a|
                self <= a
              end
            when IntersectionType
              others.types.any? do |a|
                self <= a
              end
            when TypeVariable
              #TODO: constrain type variables
            when TopType
              true
            else
              false
            end
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


    
    # A type defined by a collection of named fields and methods. Supertype of all objects
    class StructuralType < Type
        # Create a new StructuralType.
        #
        # [+field_types+] Map from field names as symbols to their types.
        # [+method_types+] Map from method names as symbols to their types.
        def initialize(field_types, method_types)
            @field_types = field_types
            @method_types = method_types
            super()
        end

        def field_names
          @field_types.keys
        end
        
        def method_names
          @method_types.keys
        end

        # Return +true+ if +self+ is a subtype of +other+. This follows the
        # usual semantics of BottomType and TopType; if +other+ is another
        # StructralType, all of the following must be true:
        # 1. +self+ has at least all the fields and methods in +other+.
        # 2. Corresponding field types in +self+ and +other+ must be the same
        #    type.
        # 3. The method types in +self+ and +other+ are covariant (the types in
        #    +self+ are subtypes of the types with the same key in +other+).
        def <=(other)
            case other
            when StructuralType
                other.field_names do |f_name|
                  return false unless @field_types.has_key?(f_name)
                  mine = get_field(f_name)
                  return false unless mine <= theirs and theirs <= mine 
                end
                
                other.method_names do |m_name|
                  return false unless @method_types.has_key?(m_name)
                  mind = get_method(m_name)
                  return false unless mine <= theirs
                end
                return true
            else
                super(other)
            end
        end

        def to_s  # :nodoc:
            fields = map_to_string(@field_types)
            methods = map_to_string(@method_types)
            "{ #{fields} | #{methods} }"
        end

        def eql?(other)  # :nodoc:
            return false unless other.instance_of?(StructuralType)

            return false unless type_map_eql?(@field_types, other.field_types)
            return false unless type_map_eql?(@method_types, other.method_types)
            true
        end

        def hash  # :nodoc:
            hash = type_map_hash(@field_types)
            hash += 23 * type_map_hash(@method_types)
        end
        
        # can be overriden in subclasses
        def get_method(name)
          return @method_types[name]
        end
        
        # can be overriden in subclasses
        def get_field(name)
          return @field_types[name]
        end
        
        protected

        def can_subtype?(other)
            (other.instance_of?(StructuralType) or
                    other.instance_of?(NominalType))
        end
        
        
        private

        # Compute a hash code for a symbol-to-type map.
        def type_map_hash(map)
            builder = Rubydust::HashBuilder.new(19, 313)
            map.each_pair do |sym, type|
                builder.include(sym)
                builder.include(type)
            end
            builder.get_hash
        end

        # Return +true+ if +left+ and +right+ have the same set of symbols and
        # have equal types for corresponding symbols.
        def type_map_eql?(left, right)
            return false unless left.size == right.size
            left.each_pair do |sym, left_type|
                return false unless right.has_key?(sym)
                right_type = right[sym]
                return false unless right_type == left_type
            end
        end

        # Return a string representation of a symbol-to-type map.
        def map_to_string(type_map)
            if type_map.empty?
                return ""
            end
            pairs = type_map.each_pair.map do |symbol, type|
                "#{symbol}: #{type}"
            end
            pairs.join(", ")
        end
    end

    # The simplest kind of type, where the name is the same as the type, such as
    # Fixnum, String, Object, etc.
    class NominalType < StructuralType
        # A cache of NominalType instances, keyed by Class constants.
        @@cache = Hash.new

        # The constant Class instance for this type.
        attr_reader :klass
        # Return a NominalType instance of type +klass+. Multiple calls with the
        # same +klass+ will return the same instance.
        #
        # The field and method maps will be stored as accessors in the wrapped
        # Class instance. This will clobber any existing attributes named
        # +field_types+ or +method_types+ in the instance.
        def self.of(klass)
            t = @@cache[klass]
            if not t
                t = NominalType.new(klass)
                @@cache[klass] = t
            end
            return t
        end
        
        attr_accessor :type_parameters

        # Return +true+ if +self+ represents a subtype of +other+.
        def <=(other)
            case other
            when NominalType
                return true if other.klass.name == @klass.name
                other_class = other.klass
                it_class = @klass.superclass
                #TODO(jtoman): memoize this lookup for fast access?
                while it_class != nil
                  return true if other_class == it_class
                  it_class = it_class.superclass 
                end
                return false
            else
              super(other)
            end
        end

        def to_s # :nodoc:
            return "NominalType<#{@klass}>"
        end

        # Return +true+ if +other+ is a NominalType with the same +klass+ as
        # +self.
        def eql?(other)
            return false unless other.instance_of?(NominalType)
            return false unless other.klass == @klass
            true
        end

        def hash # :nodoc:
            return @klass.name.hash
        end
        
        # jtoman: is this necessary? can't we transform add_field into
        # add_method(name,() -> type) and add_method(name=,type -> type)?
        def add_field(name,type)
          # TODO(jtoman): generate an intersection type?
          @field_types[name] = type
        end
        
        def add_method(name, type)
          # TODO(jtoman): generate an intersection type?
          @method_types[name] = type
        end

        protected

        def can_subtype?(other)
            (other.instance_of?(StructuralType) or
                    other.instance_of?(NominalType))
        end

        private

        # Create a new NominalType.
        #
        # +initialize+ is private since NominalTypes should only be created
        # through the NominalType.of method.
        #
        # [+klass+] The constant Class instance of this type, i.e. Fixnum,
        #           String, etc.
        def initialize(klass)
            super({},{})
            @klass = klass
            @type_parameters = []
        end
    end
    
    
    # A type that is parameterized on one or more other types. The base type
    # must be a NominalType, while the parameters can be any type.
    class ParameterizedType < StructuralType
        # The NominalType that is being parameterized.
        attr_accessor :nominal
        # The list of type parameters, in order.
        attr_accessor :parameters
        
        # Creates a new ParameterizedType, parameterizing +nominal+ with
        # +parameters+. Note that +parameters+ must be listed in order.
        def initialize(nominal, parameters)
            raise Exception.new("Type parameter mismatch") unless parameters.size == nominal.type_parameters.length
            @nominal = nominal
            @parameters = parameters
            @_method_cache = {}
            super({},{})
        end

        def <=(other)
            case other
            when ParameterizedType
                return false unless (@nominal <= other.nominal and
                                     other.nominal <= @nominal)
                zipped = @parameters.zip(other.parameters)
                return false unless zipped.all? do |t, u|
                    t <= u and u <= t
                end
                true
            else
                false
            end
        end

        def hash
            builder = Rubydust::HashBuilder.new(23, 41)
            builder.include(@nominal)
            @parameters.each do |p|
                builder.include(p)
            end
            builder.get_hash
        end

        def eql?(other)
            return false unless other.instance_of?(ParameterizedType)
            return false unless other.nominal.eql?(@nominal)
            return false unless other.parameters.eql?(@parameters)
            true
        end
        
        def type_of_param(p_name)
          ind = @nominal.type_parameters.index(p_name)
          @parameters[ind]
        end

        #TODO: implement me
        def get_field(name)
          raise Exception.new("Not yet implemented")
        end
        
        def get_method(name)
          return @_method_cache[name] if @_method_cache.has_key?(name)
          @_method_cache[name] = replace_type(@nominal.get_method(name),@parameters)
        end
        
        private
        # perform type replacement recursively
        def replace_type(type, formal_type_parameters)
          case type
          when TypeParameter
            t_ind = @nominal.type_parameters.index(type)
            raise Exception.new("Unknown type id #{type}") if t_ind == nil
            formal_type_parameters[t_ind]
          when OptionalArg
            OptionalArg.new(replace_type(type.type,formal_type_parameters))
          when Vararg
            Vararg.new(replace_type(type.type, formal_type_parameters))
          when ParameterizedType
            ParameterizedType.new(
              type.nominal,
              type.parameters.map do |t_param|
                replace_type(TypeParameter.new(t_param), formal_type_parameters)
              end
            )
          when StructuralType
            type
          when NominalType
            type
          when ProceduralType
            block = nil
            if type.block_type != nil
              block = replace_type(type.block_type, formal_type_parameters)
            end
            ProceduralType.new(
              replace_type(type.return_type,formal_type_parameters),
              (type.arg_types.map do |t|
                replace_type(t,formal_type_parameters)
              end),
              block)
          when SymbolType
            type
          when UnionType
            UnionType.of(
              type.types.map do |t|
                replace_type(t,formal_type_parameters)
              end
            )
          when IntersectionType
            IntersectionType.of(
              type.types.map do |t|
                replace_type(t,formal_type_parameters)
              end
            )
          else
            puts type.class.name
          end
        end
        
        def to_s
          "#{@nominal.klass.name}<#{parameters.join(", ")}>"
        end
    end

    # A type representing some method or block. ProceduralType has subcomponent
    # types for arguments (zero or more), block (optional) and return value
    # (exactly one).
    class ProceduralType < Type
        attr_reader :return_type
        attr_reader :arg_types
        attr_reader :block_type

        # Create a new ProceduralType.
        #
        # [+return_type+] The type that the procedure returns.
        # [+arg_types+] List of types of the arguments of the procedure.
        # [+block_type+] The type of the block passed to this method, if it
        #                takes one.
        def initialize(return_type, arg_types=[], block_type=nil)
            @return_type = return_type
            @arg_types = arg_types
            @block_type = block_type
            super()
        end

        # Return true if +self+ is a subtype of +other+. This follows the usual
        # semantics of TopType and BottomType. If +other+ is also an instance of
        # ProceduralType, return true iff all of the following hold:
        # 1. +self+'s return type is a subtype of +other+'s (covariant).
        # 2. +other+'s block type is a subtype of +self+'s (contravariant.
        # 3. Both types have blocks, or neither type does.
        # 4. Both types have the same number of arguments, and +other+'s
        #    arguments are subtypes of +self+'s (contravariant).
        def <=(other)
            case other
            when ProceduralType
                # Check number of arguments, presence of blocks, etc.
                return false unless compatible_with?(other)

                # Return types are covariant.
                return false unless @return_type <= other.return_type
                # Block types must both exist and are contravariant.
                if @block_type
                    return false unless other.block_type <= @block_type
                end

                # Arguments are contravariant.
                @arg_types.zip(other.arg_types).each do |a, b|
                    return false unless b <= a
                end
                return true
            else
                return false
            end
        end

        def to_s  # :nodoc:
            if @block_type
                "[ (#{@arg_types.join(', ')}) " \
                "{#{@block_type}} -> #{@return_type} ]"
            else
                "[ (#{@arg_types.join(', ')}) -> #{@return_type} ]"
            end
        end

        # Return true if all of the following are true:
        # 1. +other+ is a ProceduralType instance.
        # 2. Return types compare equal.
        # 3. Either neither +self+ nor +other+ have block types or they both do,
        #    in which case the block types compare equal.
        # 4. +other+ has the same number of arguments as +self+.
        # 5. Respective argument types, if any, compare equal.
        def eql?(other)
            return false unless compatible_with?(other)
            return false unless @return_type == other.return_type
            if @block_type
                return false unless @block_type == other.block_type
            end
            @arg_types.zip(other.arg_types).each do |a, b|
                return false unless a == b
            end
            true
        end

        def hash  # :nodoc:
            builder = Rubydust::HashBuilder.new(17, 31)
            builder.include(@return_type)
            if @block_type
                builder.include(@block_type)
            end
            @arg_types.each do |arg|
                builder.include(arg)
            end
            builder.get_hash
        end

        protected

        def can_subtype?(other)
            other.instance_of?(ProceduralType)
        end

        private

        # Return true iff all of the following are true:
        # 1. +other+ is a ProceduralType.
        # 2. +other+ has the same number of arguments as +self+.
        # 3. +self+ and +other+ both have a block type, or neither do.
        def compatible_with?(other)
            return false unless other.instance_of?(ProceduralType)
            return false unless @arg_types.size() == other.arg_types.size()
            if @block_type
                return false unless other.block_type
            else
                return false if other.block_type
            end
            return true
        end
    end

    # An object used to represent a variable number of arguments of a single type.
    # This doesn't represent a node in the constraint graph; constraints
    # should be generated on the +type+ attribute.
    class Vararg
        attr_accessor :type

        def initialize(type)
            @type = type
        end

        def to_s
            "*(#{type})"
        end

        def eql?(other)
            other.instanceof?(VarargType) and type.eql?(other.type)
        end

        def hash
            31 + type.hash
        end
    end

    # An object used to wrap a type for an optional argument to a procedure.
    # This does not represent a node in the constraint graph; constraints should
    # be generated on the +type+ attribute.
    class OptionalArg
        attr_accessor :type

        def initialize(type)
            @type = type
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


    class SymbolType < Type
      attr_reader :symbol
      def initialize(sym)
        @symbol = sym
        super()
      end
      
      def eql?(other)
        other.instance_of?(SymbolType) and other.symbol == @symbol
      end
      
      def ==(other)
        eql?(other)
      end
      
      def hash
        symbol.to_s.hash
      end
      
      def <=(other)
        # should a symbol be a subtype of a variant?
        # that is, should :a <= [ :a | :b | :c ]
        # my intuition is yes as an :a can be used anywhere where the type
        # [:a | :b | :c ] is exptected
        return true if other.instance_of?(VariantType) && other.variant_members.include?(@symbol)
        eql?(other)
      end
    end
    
    class VariantType < Type
      attr_reader :variant_members
      def initialize(variants_in)
        @variant_members = Set.new
        variants_in.each do |var|
          @variant_members << var.to_sym
        end
      end
      
      def hash
        builder = Rtc::HashBuilder.new(29, 71)
        @variant_members.each do
          |m|
          builder.include(m)
        end
        builder.get_hash
      end
      
      def <=(other)
        if other.instanceof?(VariantType)
          @variant_members.subset?(other.variant_members)
        else
          false
        end
      end
      
      def eql?(other)
        if other.instanceof?(VariantType)
          other.variant_members.eql?(@variant_members)
        else
          false
        end
      end
      
      def ==(other)
        eql?(other)
      end
    end
    
    

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
            pairs = types.product(types)
            pairs.each do |t, u|
                # pairs includes [t, t] and [u, u], and since t <= t, skip
                # these.
                next if t.equal?(u)
                # pairs includes [t, u] and [u, t], so we don't do symmetric
                # checks.
                if t <= u
                    types.delete(t)
                end
            end
            return types[0] if types.size == 1
            return UnionType.new(types)
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

        # Return true if self is a subtype of other.
        #--
        # TODO(rwsims): Refine this as use cases become clearer.
        def <=(other)
            return other.instance_of?(TopType)
        end
        
        def to_s
          "TParam<#{symbol.to_s}>"
        end
        
        def eql?(other)
          other.symbol.eql?(@symbol)
        end
        
    end
    class TopType < Type
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
      
      def ==(other)
        eql?(other)
      end
      
      def hash
        17
      end
      
      def <=(other)
        false
      end

      @@instance = nil
    end
end  # module Rtc::Types
