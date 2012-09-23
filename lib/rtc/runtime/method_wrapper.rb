require 'rtc/runtime/master_switch.rb'
require 'rtc/options'

module Rtc
  
  class TypeMismatchException < StandardError; end

  class AnnotateException < StandardError; end

  class CastException < StandardError; end

  class AmbiguousUnionException < StandardError; end

  class NoMethodException < StandardError; end

  class MethodWrapper
    class NoArgument; end
    def self.make_wrapper(class_obj, method_name)
      return nil if Rtc::Disabled
      MethodWrapper.new(class_obj, method_name)
    end

    def wrap_block(x)
      Proc.new {|v| x.call(v)}
    end

    def invoke(invokee, arg_vector)
      regular_args = arg_vector[:args]
      blk = arg_vector[:block]
      from_proxy = false

      last_arg = regular_args[-1]
      if last_arg.is_a?(Hash) and last_arg['__rtc_special']
        regular_args.pop
        new_invokee = last_arg['self_proxy']
        from_proxy = true
      else
        last_arg = nil
        new_invokee = invokee
      end

      if $invokee_proxy.empty? or not invokee.equal?($invokee_proxy[-1].object)
        if blk == nil
          return @original_method.bind(invokee).call(*regular_args)
        else
          return @original_method.bind(invokee).call(*regular_args, &blk)
        end
      end

      method_type = new_invokee.rtc_type.get_method(@method_name.to_s)
      
      if method_type.is_a?(Rtc::Types::ProceduralType)
        method_types = [method_type]
      else
        method_types = method_type.types.to_a
      end
            
      chosen_type = Rtc::MethodCheck.check_args(method_types, @method_name, regular_args,  (not blk.nil?), @class_obj)
      
      
      unwrap_arg_pos = chosen_type.unwrap
      mutate = chosen_type.mutate
      unsolved_type_variables = []
      
      chosen_type.type_variables.each {
        |tvar|
        if tvar.solvable?
          tvar.solve
        else
          unsolved_type_variables << tvar
        end
      }
      

      i = 0
      chosen_type.arg_types.each { |arg_type|
        #TODO(jtoman): detect this error at the parser level
        #if arg_type.has_parameterized
        #  raise Rtc::TypeMismatchException, "Unbound parameter in method #{invokee.class}##{@method_name}"
        #end
        
        if arg_type.instance_of?(Rtc::Types::ProceduralType)
          regular_args[i] = BlockProxy.new(regular_args[i], arg_type, @method_name, invokee,
            unsolved_type_variables)
        else
          if unwrap_arg_pos.include?(i)
            if regular_args[i].is_proxy_object?
              regular_args[i] = regular_args[i].object
            end
          else
            regular_args[i] = regular_args[i].rtc_annotate(arg_type.is_a?(Rtc::Types::TypeVariable) ? arg_type.get_type : arg_type)
          end
        end
        
        i += 1
      }

      unless invokee.rtc_type.has_method?(@method_name)
        raise NoMethodError, invokee.inspect + " has no method " + @method_name.to_s
      end


      if blk
        block_proxy = BlockProxy.new(blk, chosen_type.block_type,@method_name,
          invokee, unsolved_type_variables)
        wrapped_block = wrap_block(block_proxy)
        Rtc::MasterSwitch.turn_on
        ret_value = @original_method.bind(invokee).call(*regular_args, &wrapped_block)
        Rtc::MasterSwitch.turn_off
      else
        Rtc::MasterSwitch.turn_on
        ret_value = @original_method.bind(invokee).call(*regular_args)
        Rtc::MasterSwitch.turn_off
      end
      
      trailing_tvar = nil
      
      unsolved_type_variables.each {
        |tvar|
        if tvar.solvable? 
          tvar.solve
        # this type variable was solved in a block
        elsif tvar.instantiated
          next
        else
          raise "Invalid tsig" unless trailing_tvar.nil?
          trailing_tvar = tvar
        end
      }

      unless ret_value.rtc_type <= chosen_type.return_type
        # p ret_value.rtc_type, chosen_type.return_type, @method_name, invokee, chosen_type
        
        raise TypeMismatchException, "invalid return type in " + @method_name.to_s
      end
      
      trailing_var.instantiate unless trailing_tvar.nil?
      if ret_value === false || ret_value === nil ||
          ret_value.is_a?(Rtc::Types::Type)
        ret_proxy = ret_value
      elsif chosen_type.return_type.is_a?(Rtc::Types::TypeVariable)
        ret_proxy = ret_value.rtc_annotate(chosen_type.return_type.get_type)
      else
        ret_proxy = ret_value.rtc_annotate(chosen_type.return_type)
      end

      if ret_value.proxies and not from_proxy and mutate
        ret_type = ret_value.rtc_type 

        ret_value.proxies.each {|p|
          unless ret_type <= p.proxy_type
            raise Rtc::TypeMismatchException, "Return object run-time type #{ret_type.inspect} NOT <= one of the object\'s proxy list types #{p.proxy_type.inspect}  method=#{@method_name},  invokee=#{invokee.rtc_to_str},   args=#{regular_args.rtc_to_str},   ret=#{ret_value.inspect},    invokee_type=#{invokee.rtc_type.inspect}   #{new_mt.inspect}"
          end
        }
      end

      if mutate
        unless invokee.rtc_type <= new_mt.return_type
          raise Rtc::TypeMismatchException, "type mismatch on return value"
        end
      end

      return ret_proxy
    end

    private
    
    def on_error(message)
      case Rtc::Options[:on_type_error]
      when :ignore
        ;
      when :exception
        raise TypeMismatchException,message
      when :file
        Rtc::Options[:type_error_config].write(message)
      when :callback
        Rtc::Options[:type_error_config].call(message)
      when :exit
        exit -1
      end
    end
    
    def initialize(class_obj,method_name)
      @method_name = method_name
      @class_obj = class_obj

      class_obj = @class_obj

      this_obj = self
      original_method = @original_method = class_obj.instance_method(method_name)
      wrapper_lambda = lambda {
        |*__rtc_args, &__rtc_block|
        if Rtc::MasterSwitch.is_on?
          Rtc::MasterSwitch.turn_off 
          args = {:args => __rtc_args, :block => __rtc_block }

          begin
            this_obj.invoke(self, args)
          ensure
            Rtc::MasterSwitch.turn_on
          end
        else
          if __rtc_block.nil?
            return original_method.bind(self).call(*__rtc_args)
          else
            return original_method.bind(self).call(*__rtc_args, &__rtc_block)
          end
        end
      }

      class_obj.send(:define_method, method_name, wrapper_lambda)
    end
  end

  class BlockProxy < MethodWrapper
    attr_reader :proc
    attr_accessor :block_type
    attr_reader :method_type
    attr_reader :method_name
    attr_reader :class_obj

    def initialize(proc, type, method_name, class_obj,
        unsolved_tvars)
      @proc = proc
      @block_type = type
      @method_name = method_name
      @class_obj = class_obj
      @unsolved_type_variables = unsolved_tvars
      @needs_solving = true
    end

    def call(*args)
      Rtc::MasterSwitch.turn_off
      #arg = args[0]

      #TODO(jtoman): refactor
      raise Rtc::TypeMismatchException, "Arg count different in block" unless 
        args.length == block_type.arg_types.length
      arg_type_pairs = args.zip(block_type.arg_types)
      arg_type_pairs.each {
        |value, expected_type|
        raise Rtc::TypeMismatchException, "block argument mismatch" unless
          value.rtc_type <= expected_type
      }
      
      update_type_variables
      
      annotated_args = arg_type_pairs.map {
        |value, type|
        value.rtc_annotate(type.real_type)
      }

      Rtc::MasterSwitch.turn_on
      ret = @proc.call(*annotated_args)
      Rtc::MasterSwitch.turn_off

      raise Rtc::TypeMismatchException, "Block return type mismatch" unless ret.rtc_type <= block_type.return_type
      
      update_type_variables
      if ret === false or ret === nil or ret.is_a?(Rtc::Types::Type)
        ret
      else
        ret.rtc_annotate(block_type.return_type.real_type)
      end
    end
    
    private
    
    def update_type_variables
      if @needs_solving
        @needs_solving = false
        new_unsolved = []
        @unsolved_type_variables.each { |utv|
          if utv.solvable?
            utv.solve
          else
            @needs_solving = true
            new_unsolved << utv
          end
        }
        @unsolved_type_variables = new_unsolved
      end
    end
  end
end
