require_relative './type'
require 'rtc/runtime/native'

module Rtc::Types
  
    # A type representing some method or block. ProceduralType has subcomponent
    # types for arguments (zero or more), block (optional) and return value
    # (exactly one).
    class ProceduralType < Type
        attr_reader :return_type
        attr_reader :arg_types
        attr_reader :block_type
        attr_reader :parameters
        attr_accessor :mutate
        attr_accessor :unwrap

        attr_accessor :type_variables
        # Create a new ProceduralType.
        #
        # [+return_type+] The type that the procedure returns.
        # [+arg_types+] List of types of the arguments of the procedure.
        # [+block_type+] The type of the block passed to this method, if it
        #                takes one.
        # [+tvars+] The list of instantiated type variables that exist in this for this
        #                 method
        def initialize(parameters, return_type, arg_types=[], block_type=nil, tvars = [], meta={})
            @parameters = parameters.nil? ? [] : parameters
            @return_type = return_type
            @arg_types = arg_types
            @block_type = block_type
            @type_variables = tvars
            @mutate = meta['mutate'].nil? ? false : meta['mutate']
            @unwrap = meta['unwrap'].nil? ? [] : meta['unwrap']
            super()
        end

        def map
          new_arg_types = Rtc::NativeArray.new
          arg_types.each {
            |p|
            new_arg_types << (yield p)
          }
          ProceduralType.new(
                             parameters,
                             (yield return_type),
                             new_arg_types,
                             block_type.nil? ? nil : (yield block_type),
                             type_variables,
                             { "mutate" => mutate, "unwrap" => unwrap }
                             )
        end

        def each
          yield return_type
          yield block_type if block_type
          arg_types.each { |a| yield a }
        end
        
        def instantiate
          if not parameterized?
            return self
          end
          type_vars = Rtc::NativeHash.new
          parameters.map {
            |t_param|
            type_vars[t_param.symbol] = TypeVariable.new(t_param.symbol, self)
          }
          to_return = self.map {
            |t|
            t.replace_parameters(type_vars)
          };
          to_return.type_variables = type_vars.values;
          return to_return
        end
        
        def parameterized?
          not parameters.empty?
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
          to_return = Rtc::NativeHash.new()
          to_return[:required] = Rtc::NativeArray[0,0]
          to_return[:rest] =  false
          to_return[:opt] = 0
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
end
