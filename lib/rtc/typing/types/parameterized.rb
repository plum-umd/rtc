require_relative './structural'
require 'rtc/runtime/native'
require 'rtc/tools/hash-builder.rb'

module Rtc::Types
    # A type that is parameterized on one or more other types. The base type
    # must be a NominalType, while the parameters can be any type.
    class ParameterizedType < StructuralType
        # The NominalType that is being parameterized.
        attr_accessor :nominal
        # The list of type parameters, in order.
        attr_accessor :parameters
        attr_accessor :dynamic
        
        # Creates a new ParameterizedType, parameterizing +nominal+ with
        # +parameters+. Note that +parameters+ must be listed in order.
        def initialize(nominal, parameters, dynamic = false)
            if nominal.type_parameters.size > 0
              raise Exception.new("Type parameter mismatch") unless parameters.size == nominal.type_parameters.length
            end

            @nominal = nominal
            @parameters = parameters
            @method_cache = Rtc::NativeHash.new
            @dynamic = dynamic
          super({},{})
        end

        def each
          yield @nominal
          @parameters.each {
            |p|
            yield p
          }
        end

        def has_method?(method)
          @nominal.has_method?(method)
        end
        
        def map
          new_nominal = yield @nominal
          new_params = Rtc::NativeArray.new
          parameters.each {
            |p|
            new_params << (yield p)
          }
          ParameterizedType.new(new_nominal, new_params, dynamic)
        end
        
        def parameterized?
          true
        end

        def <=(other)
          case other
          when ParameterizedType
            return false unless (@nominal <= other.nominal and
                                 other.nominal <= @nominal)
            zipped = @parameters.zip(other.parameters)
            if not @dynamic
              return false unless zipped.all? do |t, u|
                # because type binding is done via the subtyping operationg
                # we can't to t <= u, u <= t as uninstantiate type variables
                # do not have a meaningful subtype rule
                if u.instance_of?(TypeVariable)
                  t <= u
                else
                  t <= u and u <= t
                end
              end
            else
              return false unless zipped.all? do |t, u|
                t <= u
              end
            end
            true
          when NominalType
            if other.klass == Object
              true
            else
              false 
            end
          when TupleType
            false
          else
            super(other)
          end
        end

        def hash
            builder = Rtc::HashBuilder.new(23, 41)
            builder.include(@nominal)
            @parameters.each do |p|
              #builder.include(p.pointed_type)
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
          @parameters[param].pointed_type
        end

        def get_field(name, which = nil)
          return replace_type(@nominal.get_field(name, which))
        end
        
        def get_method(name, which = nil, tvars = nil)
          replacement_map = tvars || Rtc::NativeHash.new
          if dynamic
            # no caching here folks
            @nominal.type_parameters.each_with_index {
              |t_param, type_index|
              replacement_map[t_param.symbol] = TypeVariable.new(t_param.symbol, self, parameters[type_index])
            }
            to_ret = @nominal.get_method(name, which).replace_parameters(replacement_map)
            if to_ret.is_a?(IntersectionType)
              to_ret.each {
                |type|
                type.type_variables += replacement_map.values
              }
            else
              to_ret.type_variables += replacement_map.values
            end
            to_ret
          else
            if @method_cache[name]
              return @method_cache[name]
            end
            @nominal.type_parameters.each_with_index {
              |t_param, type_index|
              replacement_map[t_param.symbol] = parameters[type_index]
            }
            to_ret = @nominal.get_method(name, which).replace_parameters(replacement_map)
            has_tvars = 
              if to_ret.is_a?(IntersectionType)
                to_ret.types.any? {
                |type|
                not type.type_variables.empty?
              }
              else
                not to_ret.type_variables.empty?
              end
            if not has_tvars
              @method_cache[name] = to_ret
            end
            return to_ret
          end
        end
        
        def to_s
            "#{@nominal.klass.name}<#{parameters.join(", ")}>"
        end
    end
end
