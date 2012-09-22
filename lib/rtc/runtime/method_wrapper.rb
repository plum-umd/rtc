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
      
      method_type = new_invokee.rtc_typeof(@method_name.to_s)
      
      if method_type.is_a?(Rtc::Types::ProceduralType)
        method_types = [method_type]
      else
        method_types = method_type.types.to_a
      end
            
      chosen_type = Rtc::MethodCheck.check_args(method_types, @method_name, regular_args,  (not blk.nil?), @class_obj)
      
      # if not $method_stack.keys.include?(invokee.class)
        # $method_stack[invokee.class] = {}
      # end
#       
      # if not $method_stack[invokee.class].keys.include?(@method_name)
        # $method_stack[invokee.class][@method_name] = []
      # end
# 
      # $method_stack[invokee.class][@method_name].push(cons)
      #method_meta = invokee.rtc_meta["function_meta"][@method_name][chosen_type]
      #TODO(jtoman): figure out what to do with this metadata
      #unwrap_arg_pos = method_meta.unwrap
      unwrap_arg_pos = []
      #mutate = method_meta.mutate
      mutate = false
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
          regular_args[i] = BlockProxy.new(regular_args[i], arg_type, @method_name, invokee)
        else
          if unwrap_arg_pos.include?(i)
            if regular_args[i].respond_to?(:is_proxy_object)
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
      
      puts "calling #{@method_name} on #{invokee}"
      puts "args are #{regular_args}"
      if blk
        wb = wrap_block(blk)
        Rtc::MasterSwitch.turn_on
        ret_value = @original_method.bind(invokee).call(*regular_args, &wb)
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
        else
          raise "Invalid tsig" unless trailing_tvar.nil?
          trailing_tvar = tvar
        end
      }

      #c = $method_stack[invokee.class][@method_name][-1]
      unless ret_value.rtc_type <= chosen_type.return_type
        p ret_value.rtc_type, chosen_type.return_type, @method_name, invokee, chosen_type
        
        raise TypeMismatchException, "invalid return type in " + @method_name.to_s
      end
      
      trailing_var.instantiate unless trailing_tvar.nil?

      if chosen_type.return_type.is_a?(Rtc::Types::TypeVariable)
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

        if invokee.proxies
          invokee.proxies.each {|p|
            unless ret_value.rtc_type <= p.proxy_type
              raise Rtc::TypeMismatchException, "Return object run-time type #{ret_value.rtc_type.inspect} NOT <= one of the object's proxy list types #{p.proxy_type.inspect}"
            end
          }       
        end

      end

      #$method_stack[invokee.class][@method_name].pop

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
          puts "intercepted call"
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
    attr_reader :block_type
    attr_writer :block_type
    attr_reader :method_type
    attr_reader :method_name
    attr_reader :constraints
    attr_reader :class_obj

    def initialize(proc, type, method_name, class_obj)
      @proc = proc
      @block_type = type
      @method_name = method_name
      @class_obj = class_obj
    end

    def call(*args)
      Rtc::MasterSwitch.turn_off
      #arg = args[0]

      i = 0
      for a in args
        valid = true

        #if method_type.arg_types[i].has_parameterized
        #  raise Rtc::TypeMismatchException, "Unable to infer block argument type from regular argument types"
        #end
        valid = a.rtc_type <= method_type.arg_types[i]

        unless valid
          raise Rtc::TypeMismatchException, "block argument mismatch"
        end

        i += 1
      end

      Rtc::MasterSwitch.turn_on
      ret = @proc.call(arg)
      Rtc::MasterSwitch.turn_off

      # new_ret_type = method_type.return_type.replace_constraints(c)
      new_ret_type = method_type.return_type

      if new_ret_type.has_parameterized
        if not ret.rtc_type.le_poly(new_ret_type, c)
          raise Rtc::TypeMismatchException, "block return type mismatch"
        end
      else
        unless ret.rtc_type <= new_ret_type
          raise Rtc::TypeMismatchException, "block return type mismatch"
        end
      end

      return ret
    end
  end
end
