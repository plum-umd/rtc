require 'rtc/runtime/native'
require_relative './structural'
require_relative './terminal'

module Rtc::Types

    # The simplest kind of type, where the name is the same as the type, such as
    # Fixnum, String, Object, etc.
    class NominalType < StructuralType
      include TerminalType
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
        @@cache = Rtc::NativeHash.new

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
        
        def map
          return self
        end

        def has_method?(method)
          method = method.to_sym
          self.klass.method_defined?(method)
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
          @type_parameters = t_params.map {
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
            when NominalType
              other_class = other.klass
              return true if other_class.name == @name
              it_class = @klass
              while it_class
                return true if it_class == other_class
                it_class = it_class.rtc_meta[:no_subtype] ?
                  nil : it_class.superclass
              end
              return false
            when ParameterizedType
              false
            when TupleType
              false
            when TopType
              true
            when StructuralType
              super(other)
            else
              super(other)
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
        
        def to_real
          self
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
            @method_types[name].is_a?(IntersectionType) ?
              @method_types[name].map { |it| it.instantiate } :
              @method_types[name].instantiate
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
            super(Rtc::NativeHash.new,Rtc::NativeHash.new)
            @klass = klass
            @type_parameters = []
            @name = klass.name
        end
    end
end
