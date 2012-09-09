# Classes for representing the various types recognized by rtc.
#
# Author:: Ryan W Sims (rwsims@umd.edu)

require 'set'
require 'singleton'

require 'rtc/tools/hash-builder.rb'
require 'rtc/runtime/class_loader'

class Rtc::GlobalCache
  @@cache = {}
  def self.cache
    @@cache
  end
end

class Object
  def rtc_meta
    if defined? @_rtc_meta
      @_rtc_meta
    else
      if frozen? and Rtc::GlobalCache.cache[object_id] 
        return Rtc::GlobalCache.cache[object_id]
      end
      to_return = {
        :annotated => false,
        :no_subtype => false,
        :iterators => {},
        :_type => nil
      }
      if frozen?
        Rtc::GlobalCache.cache[object_id] = to_return
      else
        @_rtc_meta = to_return
      end
    end
  end
  
  def rtc_gc
    Rtc::GlobalCache.cache[object_id] = nil
  end
  
  @@old_freeze_meth = Object.instance_method(:freeze)
  
  def freeze
    # force the meta property to be intialized
    if not frozen?
      rtc_meta
    end
    @@old_freeze_meth.bind(self).call()
  end
  
  def rtc_type
#    return self.proxy_types if not self.proxy_types == nil

    meta_hash = rtc_meta
    if meta_hash[:_type]
      meta_hash[:_type]
    else

      meta_hash[:_type] = rtc_get_type
    end
  end
  
  def rtc_typeof(name, which_class = nil)
    name = name.to_s
    if name[0] == "@"
      self.rtc_type.get_field(name[1..-1], which_class)
    else
      self.rtc_type.get_method(name, which_class)
    end
  end
  
  protected
  
  def rtc_get_type
    if self.class.name == "Symbol"
      Rtc::Types::SymbolType.new(self)
    else
      class_obj = Rtc::Types::NominalType.of(self.class)

      if class_obj.type_parameters.size == 0
          class_obj
      elsif class_obj.klass == Array
          Rtc::Types::ParameterizedType.new(class_obj, [Rtc::Types::TypeVariable.create(self.each)])
      elsif class_obj.klass == Hash
          Rtc::Types::ParameterizedType.new(class_obj, [Rtc::Types::TypeVariable.create(self.each_key),
            Rtc::Types::TypeVariable.create(self.each_value)])
      else
          lst = []
          
          self.get_parameters.each {|t|
            lst.push(Rtc::Types::TypeVariable.create([t].each))
          }

          Rtc::Types::ParameterizedType.new(class_obj, lst)
#      else
#          #user defined parameterized classes
#        tv = class_obj.type_parameters.map {
#          |param|
#          Rtc::Types::TypeVariable.create(self.send(class_obj.klass.rtc_meta[:iterators][param.symbol]))
#        }

#        Rtc::Types::ParameterizedType.new(class_obj, tv)
      end
    end
  end
end

class Class
  def rtc_instance_typeof(name, include_super = true)
    my_type = Rtc::Types::NominalType.of(self)
    name = name.to_s
    if name[0] == "@"
      my_type.get_field(name[1..-1], include_super ? nil : self)
    else
      my_type.get_method(name, include_super ? nil : self)
    end
  end
  
  def rtc_get_type
    return Rtc::Types::NominalType.of(class << self; self; end)
  end
end

class Rtc::TypeNarrowingError < StandardError; end

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

#        def has_parameterized
#        end

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
              if other.dynamic
                true
              else
                typ = other.wrapped_type
                self <= typ
              end
            when TopType
              true
            when TupleType
              raise Exception, '<= TupleType NOT implemented'
            else
              false
            end
        end

        def le_poly(other, h)
          case other
          when UnionType
            sol_found = false
            nh = {}

            for o in other.types
              if o.has_parameterized and self.le_poly(o, nh)
                if sol_found == true 
                  raise Rtc::AmbiguousUnionException
                else
                  sol_found = true
                end
              else
                if self <= o
                  if sol_found == true 
                    raise Rtc::AmbiguousUnionException
                  else
                    sol_found = true
                  end
                end
              end
            end

            if nh.size == 1
              h.merge!(nh)
              return true
            else
              return false
            end
          when IntersectionType
            others.types.any? do |a|
              self <= a
            end
          when TypeVariable
            if other.dynamic
              true
            else
              typ = other.wrapped_type
              self <= typ
            end
          when TopType
            true
          else
            if h.keys.include?(other.symbol)
              if h[other.symbol].instance_of?(UnionType)
                h[other.symbol] = UnionType.of(h[other.symbol].types.to_a + [self])
              else
                h[other.symbol] = UnionType.of([h[other.symbol], self])
              end
            else
              h[other.symbol] = self
            end
            
            true
          end
        end

        def parameterized?
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
            when TupleType
                false
            when StructuralType
                other.method_names.each do |m_name|
                  return false unless method_names.include?(m_name)
                  mine = get_method(m_name)
                  theirs = other.get_method(m_name)
                  return false unless mine <= theirs
                end
                return true
            else
                super(other)
            end
        end

        def le_poly(other, h)
            case other
            when StructuralType
                other.method_names.each do |m_name|
                  return false unless method_names.include?(m_name)
                  mine = get_method(m_name)
                  theirs = other.get_method(m_name)
                  #return false unless mine <= theirs
                  return false unless mine.le_poly(theirs, h)
                end
                return true
            else
                super(other, h)
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
            builder = Rtc::HashBuilder.new(19, 313)
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

    class TupleType < Type
      attr_reader :ordered_params
      attr_reader :size
      
      def initialize(arr)
        @ordered_params = arr
        @size = arr.size
        super()
      end

      def has_parameterized
        self.ordered_params.any? do |i|
          i.has_paramterized
        end
      end

      def replace_constraints(c)
        np = []

        for p in @ordered_params
          np.push(p.replace_constraints(c))
        end

        TupleType.new(np)
      end

      def to_s
        "Tuple<[#{ordered_params.join(", ")}]>"
      end
      
      def inspect
        "#{self.class.name}(#{@id}): #{@ordered_params.inspect}" 
      end

      def le_poly(other, h)
        case other
          when TupleType
            return false unless self.size == other.size

            i = 0

            for t in self.ordered_params
              return false if not t.le_poly(other.ordered_params[i], h)
              i += 1
            end

            true
          when ParameterizedType
            return false if other.nominal.klass != Array

            other_parameters = other.parameters[0].wrapped_type

            self.ordered_params.all? do |s|
              s.le_poly(other_parameters, h)
            end
          when UnionType
            other.types.any? do |a|
              self.le_poly(a, h)
            end
          when IntersectionType
            other.types.any? do |a|
              self.le_poly(a, h)
            end
          when TypeVariable
            if other.dynamic
              true
            else
              typ = other.wrapped_type
              self.le_poly(typ, h)
            end
          when TopType
            true
          else
            false
        end
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
          when ParameterizedType
            return false if other.nominal.klass != Array

            other_parameters = other.parameters[0].wrapped_type

            self.ordered_params.all? do |s|
              s <= other_parameters
            end
          when UnionType
            other.types.any? do |a|
              self <= a
            end
          when IntersectionType
            other.types.any? do |a|
              self <= a
            end
          when TypeVariable
            if other.dynamic
              true
            else
              typ = other.wrapped_type
              self <= typ
            end
          when TopType
            true
          else
            false
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

    # The simplest kind of type, where the name is the same as the type, such as
    # Fixnum, String, Object, etc.
    class NominalType < StructuralType
        class InheritanceChainIterator
          #TODO(jtoman): add support for Enumerators?
          def initialize(class_obj)
            @it_class = class_obj
          end

          def next
            return nil if @it_class.nil?
            to_return = @it_class
            if @it_class.rtc_meta[:no_subtype]
              @it_class = nil
            else
              @it_class = @it_class.superclass
            end
            to_return
          end
        end
      
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

        def replace_constraints(c)
          self
        end

        def has_parameterized
          false
        end

        def has_method?(method)
          method = method.to_sym
          methods = self.klass.instance_methods(false) + [:initialize]
          methods.include?(method)
        end
        
        def type_parameters
          @type_parameters
        end
        
        def superclass
          if @klass.rtc_meta[:no_subtype] or not @klass.superclass
            nil
          else
            NominalType.of(@klass.superclass)
          end
        end
        
        def type_parameters=(t_params)
          @type_parameters = t_params.each {
            |t_param|
            if t_param.instance_of?(Symbol)
              TypeParameter.new(t_param)
            elsif t_param.instance_of?(TypeParameter)
              t_param
            else
              raise "invalid type parameter specified"
            end
          }
        end

        # Return +true+ if +self+ represents a subtype of +other+.
        def <=(other)
            case other
            when ParameterizedType
              false
            when TupleType
              false
            when TopType
              true
            when NominalType
              if other.klass.respond_to?(:name) and @klass.respond_to?(:name) and @klass.name != nil
                return true if other.klass.name == @klass.name
              #else
              #  if self.klass.class < other.klass.class or self.klass.class == other.klass.class
              #    return true
              #  else
              #    return false
              #  end
              end

              other_class = other.klass
              it = InheritanceChainIterator.new(@klass)

               #TODO(jtoman): memoize this lookup for fast access?
              while (it_class = it.next)
                return true if other_class == it_class 
              end
              return false
            else
              super(other)
            end
        end

        def le_poly(other, h)
            case other
            when ParameterizedType
              false
            when NominalType
                return true if other.klass.name == @klass.name
                other_class = other.klass
                it = InheritanceChainIterator.new(@klass)
                #TODO(jtoman): memoize this lookup for fast access?

                while (it_class = it.next)
                  return true if other_class == it_class 
                end
                return false
            else
              super(other, h)
            end
        end

        def to_s # :nodoc:
            return @klass.to_s
        end
        
        def inspect
          return "NominalType(#{id})<#{@klass}>"
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
        
        def add_field(name,type)
          if extant_type = @field_types[name]
            if extant_type.instance_of?(UnionType)
              @field_types[name] = UnionType.of(extant_type.types + [type])
            else
              @field_types[name] = UnionType.of([extant_type, type])
            end
          else
            @field_types[name] = type
          end
        end
        
        def add_method(name, type)
          if @method_types[name]
            extant_type = @method_types[name]
            if extant_type.instance_of?(IntersectionType)
              type = [type] + extant_type.types.to_a
            else
              type = [type, extant_type]
            end
            type = IntersectionType.of(type)
          end

          @method_types[name] = type
        end
        def get_method(name, which = nil)
          if @method_types[name] && (which.nil? or which == @klass)
            @method_types[name]
          else
            (sc = superclass) ? sc.get_method(name, which) : nil
          end
        end
        
        def get_field(name, which = nil)
          if @field_types[name] && (which.nil? or which == @klass)
            @field_types[name]
          else
            (sc = superclass) ? sc.get_field(name) : nil
          end
        end
        
        def method_names
          super + ((sc = superclass) ? sc.method_names : [])
        end
        
        def field_names
          super + ((sc = superclass) ? sc.field_names : [])
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
    
    #this class still has a lot of limitations. For a list of the limitations
    # see the comment on commit a8c57329554a8616f2f1a742275d66bbc6424923
    class LazyNominalType < NominalType
      proxied_methods = (NominalType.instance_methods(false) + [:method_names, :field_names]) - [:to_s, :inspect, :eql?, :==, :hash]
      proxied_methods.each do
        |proxied_mname|
        define_method(proxied_mname, lambda {
          |*args|
          concrete_obj.send(proxied_mname, *args)
        })
      end
      
      def to_s
        if @concrete_obj
          @concrete_obj.to_s
        else
          internal_repr
        end
      end
      
      def inspect
        if @concrete_obj
          @concrete_obj.inspect
        else
          internal_repr
        end
      end
      
      def eql?(other)
        if other.instance_of?(NominalType)
          return @concrete_obj == other if has_obj
          false
        elsif other.instance_of?(LazyNominalType)
          if other.has_obj and self.has_obj
            @concrete_obj == other.concrete_obj
          elsif not other.has_obj and not self.has_obj
            @context == other.context and @ident == other.ident
          else
            false
          end
        else
          false
        end
      end
      
      def hash
        hash_builder = Rtc::HashBuilder.new(1009,1601)
        hash_builder.include(@context)
        hash_builder.include(@ident)
        hash_builder.get_hash
      end
      
      def initialize(ident, context)
        @ident = ident
        @context = context
        @concrete_obj = nil
        super(nil)
      end
      
      protected
      
      def has_obj
        @concrete_obj != nil
      end
      
      attr_reader :ident, :context
      
      def internal_repr
        "LazyNominalClass(#{id})<#{Rtc::ClassLoader.ident_to_s(@ident)},#{@context}"
      end
      
      def concrete_obj
        if @concrete_obj
          @concrete_obj
        else
          @concrete_obj = NominalType.of(Rtc::ClassLoader.load_class(@ident, @context))
        end
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
            if nominal.type_parameters.size > 0
              raise Exception.new("Type parameter mismatch") unless parameters.size == nominal.type_parameters.length
            end

            @nominal = nominal
            @parameters = parameters.map {
              |t_param|
              t_param.instance_of?(TypeVariable) ? t_param : TypeVariable.create(t_param)
            }
            @_method_cache = {}
            super({},{})
        end

        def has_parameterized
          @parameters.any? {|p| p.wrapped_type.has_parameterized}
        end

        def has_method?(method)
          @nominal.has_method?(method)
        end

        def replace_constraints(c)
          np = []

          for p in @parameters
            if p.instance_of?(TypeVariable)
              np.push(p.replace_constraints(c))
            else
              raise Exception, "NA"
            end
          end

          ParameterizedType.new(@nominal, np)
        end
        
        def <=(other)
            case other
            when ParameterizedType
                return false unless (@nominal <= other.nominal and
                                     other.nominal <= @nominal)
                zipped = @parameters.zip(other.parameters)
                return false unless zipped.all? do |t, u|
                    t <= u
                end
                true
            when NominalType
                false
            when TupleType
                false
            else
                super(other)
            end
        end

        def le_poly(other, h)
            case other
            when ParameterizedType
                return false unless (@nominal.le_poly(other.nominal, h) and
                                     other.nominal.le_poly(@nominal, h))

                zipped = @parameters.zip(other.parameters)

                return false unless zipped.all? do |t, u|
                   t.le_poly(u, h)
                end

                true
            when NominalType
                false
            else
                super(other, h)
            end
        end

        def hash
            builder = Rtc::HashBuilder.new(23, 41)
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
        
        def type_of_param(param)
          param = @nominal.type_parameters.index(TypeParameter.new(param)) if param.class.name == "Symbol"
          @parameters[param].wrapped_type
        end

        def get_field(name, which = nil)
          return replace_type(@nominal.get_field(name, which), @parameters)
        end
        
        def get_method(name, which = nil)
          #TODO(jtoman): get caching to work with which parameter
          #return @_method_cache[name] if @_method_cache.has_key?(name)
          #@_method_cache[name] = 
          replace_type(@nominal.get_method(name, which),@parameters)
        end
        
        def to_s
            "#{@nominal.klass.name}<#{parameters.join(", ")}>"
        end
        
        private
        # perform type replacement recursively
        def replace_type(type, formal_type_parameters)
          return type
          case type
          when TypeParameter
            t_ind = @nominal.type_parameters.index(type)
            raise Exception.new("Unknown type id #{type}") if t_ind == nil
            if formal_type_parameters[t_ind].dynamic
              formal_type_parameters[t_ind]
            else
              formal_type_parameters[t_ind].wrapped_type
            end
          when OptionalArg
            OptionalArg.new(replace_type(type.type,formal_type_parameters))
          when Vararg
            Vararg.new(replace_type(type.type, formal_type_parameters))
          when ParameterizedType
            ParameterizedType.new(
              type.nominal,
              type.parameters.map { |t_param|
                replace_type(t_param, formal_type_parameters)
              }
            )
          when StructuralType
            #TODO(jtoman): implement me?
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
          when TypeVariable
            # it's unclear how exactly a type could be dynamic
            # in a method signature, but put this here just in case...?
            # fixed type variables however may appear in the type signature of a function
            # if the type signature is (for instance) foo: () -> Array<Bar>
            # where the type variable that is a paremter to the Array return value is
            # wrapping "Bar"
            if type.dynamic
              type
            else
              replace_type(type.wrapped_type, formal_type_parameters)
            end
          end
        end
    end

    # A type representing some method or block. ProceduralType has subcomponent
    # types for arguments (zero or more), block (optional) and return value
    # (exactly one).
    class ProceduralType < Type
        attr_reader :return_type
        attr_reader :arg_types
        attr_reader :block_type
        attr_reader :parameters

        # Create a new ProceduralType.
        #
        # [+return_type+] The type that the procedure returns.
        # [+arg_types+] List of types of the arguments of the procedure.
        # [+block_type+] The type of the block passed to this method, if it
        #                takes one.
        def initialize(parameters, return_type, arg_types=[], block_type=nil)
            @parameters = parameters
            @return_type = return_type
            @arg_types = arg_types
            @block_type = block_type

            super()
        end

        def replace_constraints(c)
          new_ret = @return_type.replace_constraints(c)
          new_args = []

          for a in @arg_types
            new_args.push(a.replace_constraints(c))
          end

          if @block_type == nil
            ProceduralType.new(@parameters, new_ret, new_args)
          else
            new_blk = @block_type.replace_constraints(c)
            ProceduralType.new(@parameters, new_ret, new_args, new_blk)
          end
        end

        def has_parameterized_args
          @arg_types.any? {|a| a.has_parameterized}
        end

        def has_parameterized_ret
          @return_type.has_parameterized
        end

        def get_parameterized_arg_pos
          positions = []
          i = 0

          @arg_types.each {|a|
            positions.push(i) if a.has_parameterized
            i += 1
          }

          positions
        end

        def has_parameterized
          has_parameterized_args or has_parameterized_ret
        end

#        def has_parameterized
#        end

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
            when TupleType
                false
            else
                super(other)
            end
        end

        def to_s  # :nodoc:
          if @block_type
            "[ (#{@arg_types.join(', ')}) " \
            "{#{@block_type}} -> #{@return_type} ]"
          else
            if @arg_types
              "[ (#{@arg_types.join(', ')}) -> #{@return_type} ]"
            else
              "[ () -> #{@return_type} ]"
            end
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
        #returns the minimum number of arguments required by this function
        # i.e. a count of the required arguments.
        def min_args
          p_layout = parameter_layout
          p_layout[:required][0] + p_layout[:required][1]
        end
        #gets the maximum number of arguments this function can take. If there is a rest
        # argument, this function returns -1 (unlimited)
        def max_args
          p_layout = parameter_layout
          if p_layout[:rest]
            -1
          else
            min_args + p_layout[:opt]
          end
        end
        
        # gets a hash describing the layout of the arguments to a function
        # the requied member is a two member array that indicates the number of
        # required arugments at the beginning of the parameter list and the number
        # at the end respectively. The opt member indicates the number of optional
        # arguments. If rest is true, then there is a rest argument.
        # For reference, parameter lists are described by the following grammar
        # required*, optional*, rest?, required*
        def parameter_layout
          return @param_layout_cache if defined? @param_layout_cache
          a_list = arg_types + [nil]
          to_return = {
            :required => [0,0],
            :rest => false,
            :opt => 0
          }
          def param_type(arg_type)
            case arg_type
            when NilClass
              :end
            when OptionalArg
              :opt
            when Vararg
              :rest
            else
              :req
            end
          end
          counter = 0
          i = 0
          p_type = param_type(a_list[i])
          while p_type == :req
            counter+=1
            i+=1
            p_type = param_type(a_list[i])
          end
          to_return[:required][0] = counter
          counter = 0
          while p_type == :opt
            counter+=1
            i+=1
            p_type = param_type(a_list[i])
          end
          to_return[:opt] = counter
          if p_type == :rest
            to_return[:rest] = true
            i+=1
            p_type = param_type(a_list[i])
          end
          counter = 0
          while p_type == :req
            counter+=1
            i+=1
            p_type = param_type(a_list[i])
          end
          to_return[:required][1] = counter
          raise "Invalid argument string detected" unless p_type == :end
          @param_layout_cache = to_return
        end

        def hash  # :nodoc:
            builder = Rtc::HashBuilder.new(17, 31)
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
        
        def <=(other)
          if other.instance_of(Vararg)
            type <= other.type
          else
            super(other)
          end
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

      def has_parameterized
        false
      end
      
      def eql?(other)
        other.instance_of?(SymbolType) and other.symbol == symbol
      end
      
      def ==(other)
        eql?(other)
      end
      
      def hash
        symbol.to_s.hash
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

            t0 = types[0]
            types.each{|t| types.delete(t) if t.instance_of?(BottomType)}
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

            return t0 if types == []
            return types[0] if types.size == 1
            return UnionType.new(types)
        end

        def replace_constraints(c)
          nt = []

          for t in @types
            nt.push(t.replace_constraints(c))
          end

          UnionType.of(nt)
        end

        def has_method?(method)
          @types.all? {|t| t.has_method?(method)}
        end

        def le_poly(other, h)
          if other.has_parameterized
            if other.instance_of?(TypeParameter)
              if h.keys.include?(other.symbol)
                if h[other.symbol].instance_of?(UnionType)
                  h[other.symbol] = UnionType.of(h[other.symbol].types.to_a + [self])
                else
                  h[other.symbol] = UnionType.of([h[other.symbol], self])
                end
              else
                h[other.symbol] = self
              end

              return true
            elsif other.instance_of?(UnionType)
              @types.all? do |t|
                t.le_poly(other, h)
              end
            else
              raise Exception, "NOT IMPLEMENTED 2"
            end
          else
            self <= other
          end
        end

        def has_parameterized
          @types.any? {|t| t.has_parameterized}
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
        
        def has_parameterized
          true
        end

        def replace_constraints(c)
          if c.keys.include?(@symbol)
            c[@symbol]
          else
            self
          end
        end

        # Return true if self is a subtype of other.
        #--
        # TODO(rwsims): Refine this as use cases become clearer.
        def <=(other)
          return other.instance_of?(TopType)
        end

        def le_poly(other, h)
          raise Exception, "NOT IMPLEMENTED 3"
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

      def replace_constraints(c)
        return TopType.new
      end
      
      def self.instance
        return @@instance || (@@instance = TopType.new)
      end
      
      def eql?(other)
        other.instance_of?(TopType)
      end

      def has_parameterized
        false
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
    
    class BottomType < Type
      def hash
        13
      end

      def initialize()
        super()
      end

      def replace_constraints(c)
        return BottomType.new
      end

      def has_parameterized
        false
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

      def le_poly(other, h)
        true
      end

      def self.instance
        return @@instance || (@@instance = BottomType.new)
      end
      
      @@instance = nil
    end
    
    class TypeVariable < Type
      attr_reader :dynamic
      alias :dynamic? :dynamic
      def self.create(type_param)
        raise(Exception, "Type Parameter must be an enumerator (for dynamic types) or a type class (for annotated types)") if
          !type_param.instance_of?(Enumerator) && !type_param.kind_of?(Type)
        TypeVariable.new(type_param)
      end

      def has_parameterized
        if @wrapped_type == nil
          false
        else
          @wrapped_type.has_parameterized
        end
      end

      def replace_constraints(c)
        if @wrapped_type.instance_of?(TypeParameter)
          if c.keys.include?(@wrapped_type.symbol)
            TypeVariable.create(c[@wrapped_type.symbol])
          else
            self
          end
        elsif @wrapped_type != nil
          @wrapped_type.replace_constraints(c)
        else
          self
        end
      end
      
      def ==(other)
        eql?(other)
      end
      
      def eql?(other)
        other.instance_of?(TypeVariable) && other.id == id
      end
      
      def constrain_to(type)
        raise Rtc::TypeNarrowingError, "Constrained #{type} is too narrow for type #{wrapped_type}" unless
          wrapped_type <= type
        @dynamic = false
        @wrapped_type = type
      end
      
      def wrapped_type
        if !dynamic
          @wrapped_type
        elsif @dirty and !@wrapped_type
          gen_type
        elsif @wrapped_type
          @wrapped_type
        else
          @type_cache
        end
      end
      
      def to_s
        wrapped_type.to_s
      end
      
      def inspect
        "TVar(#{id},#{dynamic}): #{wrapped_type.inspect}"
      end
      
      #this should not be called externally
      def initialize(type, is_hint = false)
        if type.instance_of?(Enumerator)
          @wrapped_type = nil # maybe the bottom type?
          @dynamic = true        
          @it = type
          @dirty = true
          @type_cache = nil
        elsif type.kind_of?(Type)
          @wrapped_type = type
          @dynamic = is_hint
        end
        super()
      end
      
      def <=(other)
        if other.instance_of?(TypeVariable)
          if dynamic
            my_type = wrapped_type
            their_type = other.wrapped_type
            my_type <= their_type
          else
            if other.instance_of?(TypeVariable)
              wrapped_type <= other.wrapped_type
            else
              typ = wrapped_type
              other.wrapped_type <= typ && typ <= other.wrapped_type
            end
          end
        else
          if dynamic
            return wrapped_type <= other
          end
          # otherwise our type has been constrained! this means that the other type must
          # match this type exactly
          typ = wrapped_type
          other <= typ && typ <= other
        end
      end

      def le_poly(other, h)
        if other.instance_of?(TypeVariable)
          if dynamic
            my_type = wrapped_type
            their_type = other.wrapped_type

            if not their_type.respond_to?(:symbol)
              my_type.le_poly(their_type, h)
            else
              if h.keys.include?(their_type.symbol)
                if h[their_type.symbol].instance_of?(UnionType)
                  h[their_type.symbol] = UnionType.of(h[their_type.symbol].types.to_a + [my_type])
                else
                  h[their_type.symbol] = UnionType.of([h[their_type.symbol], my_type])
                end
              else
                h[their_type.symbol] = my_type
              end

              true
            end
          else
            if other.instance_of?(TypeVariable)
              wrapped_type.le_poly(other.wrapped_type, h)
            else
              typ = wrapped_type
              other.wrapped_type.le_poly(typ, h) && typ.le_poly(other.wrapped_type, h)
            end
          end
        else
          if dynamic
            return wrapped_type <= other
          end
          # otherwise our type has been constrained! this means that the other type must
          # match this type exactly
          typ = wrapped_type
          other <= typ && typ <= other
        end
      end

      private 
      
      def gen_type
        curr_type = Set.new
        has_parameterized_type = false
        @it.each {
          |elem|
          elem_type = elem.rtc_type
          super_count = 0
          if curr_type.size == 0 
            curr_type << elem_type
            next
          end
          was_subtype = curr_type.any? {
            |seen_type|
            if elem_type <= seen_type
              true
            elsif seen_type <= elem_type
              super_count = super_count + 1
              false
            end
          }
          if was_subtype
            next
          elsif super_count == curr_type.size
            curr_type = Set.new([elem_type])
          else
            curr_type << elem_type
          end
        }
        if curr_type.size == 0
          curr_type = BottomType.instance
        elsif curr_type.size == 1
          curr_type = curr_type.to_a[0]
        else
          curr_type = UnionType.of(unify_param_types(curr_type))
        end
        @dirty = true
        @type_cache = curr_type
      end
      
      #FIXME(jtoman): see if we can lift this step into the gen_type step
      def unify_param_types(type_set)
        non_param_classes = []
        parameterized_classes = {}
        type_set.each {
          |member_type|
          if member_type.parameterized?
            nominal_type = member_type.nominal
            tparam_set = parameterized_classes.fetch(nominal_type) {
              |n_type|
              [].fill([], 0, n_type.type_parameters.size)
            }
            ((0..(nominal_type.type_parameters.size - 1)).map {
              |tparam_index|
              extract_types(member_type.parameters[tparam_index])
            }).each_with_index {
              |type_parameter,index|
              tparam_set[index]+=type_parameter
            }
            parameterized_classes[nominal_type] = tparam_set
          else
            non_param_classes << member_type
          end
        }
        parameterized_classes.each {
          |nominal,type_set|
          non_param_classes << ParameterizedType.new(nominal,
          type_set.map {
            |unioned_type_parameter|
            TypeVariable.new(UnionType.of(unify_param_types(unioned_type_parameter)),true)
          })
        }
        non_param_classes
      end
      
      def extract_types(param_type)
        wrapped_type = param_type.wrapped_type
        wrapped_type.instance_of?(UnionType) ? wrapped_type.types.to_a : [wrapped_type]
      end
      
      # this could be used to implement caching of wrapped types
      # we could add an annotation that would say which functions would mark a type
      # as dirty, and then at each call to those functions mark the wrapped type as
      # dirty. It is a questionable optimization, so at the moment this method
      # remains unused
      def _mark_dirty
        @dirty = true
      end
    end
end  # module Rtc::Types
