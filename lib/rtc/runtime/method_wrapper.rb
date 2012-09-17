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
      extra_arg = nil
      from_proxy = false
      cons = {}

      last_arg = regular_args[-1]
      if last_arg.is_a?(Hash) and last_arg['__rtc_special']
        regular_args.pop
        new_invokee = last_arg['self_proxy']
        from_proxy = true
      else
        last_arg = nil
        new_invokee = invokee
      end
      
      method_types = invokee.class.get_typesig_info(@method_name.to_s)
      method_type_info = Rtc::MethodCheck.check_args(method_types, new_invokee, regular_args, @method_name, cons, blk)
      
      if not $method_stack.keys.include?(invokee.class)
        $method_stack[invokee.class] = {}
      end
      
      if not $method_stack[invokee.class].keys.include?(@method_name)
        $method_stack[invokee.class][@method_name] = []
      end

      $method_stack[invokee.class][@method_name].push(cons)

      unwrap_arg_pos = method_type_info.unwrap
      mutate = method_type_info.mutate
      method_type = method_type_info.sig

      if cons.empty?
        new_mt = method_type
      else
        new_mt = method_type.replace_constraints(cons)
      end


      i = 0
      new_mt.arg_types.each { |arg_type|
        if arg_type.has_parameterized
          raise Rtc::TypeMismatchException, "Unbound parameter in method #{invokee.class}##{@method_name}"
        end
        
        if arg_type.instance_of?(Rtc::Types::ProceduralType)
          regular_args[i] = BlockProxy.new(regular_args[i], arg_type, @method_name, invokee)
        else
          if unwrap_arg_pos.include?(i)
            if regular_args[i].respond_to?(:is_proxy_object)
              regular_args[i] = regular_args[i].object
            end
          else
            regular_args[i] = regular_args[i].rtc_annotate(arg_type)
          end
        end
        
        i += 1
      }

      unless invokee.rtc_type.has_method?(@method_name)
        raise NoMethodError, invokee.inspect + " has no method " + @method_name.to_s
      end

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


      c = $method_stack[invokee.class][@method_name][-1]
      new_mt_return_type = new_mt.return_type.replace_constraints(c)

      if new_mt_return_type.has_parameterized
        ret_valid = ret_value.rtc_type.le_poly(new_mt.return_type, {})
      else
        ret_valid = ret_value.rtc_type <= new_mt_return_type
      end

      unless ret_valid
        raise TypeMismatchException, "invalid return type in " + @method_name.to_s
      end

      if new_mt_return_type.has_parameterized
        h = {}
        if ret_value.rtc_type.le_poly(new_mt_return_type, h)
          nr = new_mt_return_type.replace_constraints(h)
          ret_proxy = ret_value.rtc_annotate(nr)
        else
          raise Rtc::TypeMismatchException, "Invalid return type for method #{@method_name}"
        end
      else
        ret_proxy = ret_value.rtc_annotate(new_mt_return_type)
      end

      if ret_value.proxies and not from_proxy and mutate
        ret_type = ret_value.rtc_type 

        ret_value.proxies.each {|p|
          unless ret_type <= p.proxy_type
            raise Rtc::TypeMismatchException, "Return object run-time type #{ret_type.inspect} NOT <= one of the object\'s proxy list types #{p.proxy_type.inspect}  method=#{@method_name},  invokee=#{invokee.rtc_to_str},   args=#{regular_args.rtc_to_str},   ret=#{ret_value.inspect},    invokee_type=#{invokee.rtc_type.inspect}   #{new_mt.inspect}"
          end
        }
      end



      if method_type_info.mutate
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

      $method_stack[invokee.class][@method_name].pop

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

          if args[:block]
            method_type = self.rtc_typeof(method_name, class_obj)
            args[:block] = BlockProxy.new(args[:block], method_type, method_name, class_obj)
          end

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

      if type.instance_of?(Rtc::Types::IntersectionType)
        type.types.each {|t|
          if t.block_type
            @method_type = t
          end
        }
      else
        @method_type = type
      end

      @block_type = @method_type.block_type
      @method_name = method_name
      @class_obj = class_obj
    end

    def call(*args)
      Rtc::MasterSwitch.turn_off
      arg = args[0]

      c = $method_stack[@class_obj][@method_name][-1]


      if c.empty?
        unless @block_type
          method_type = @method_type
        else
          method_type = @block_type
        end
      else
        unless @block_type
          method_type = @method_type.replace_constraints(c)
        else
          method_type = @block_type.replace_constraints(c)
        end
      end

      i = 0
      for a in args
        valid = true

        if method_type.arg_types[i].has_parameterized
          raise Rtc::TypeMismatchException, "Unable to infer block argument type from regular argument types"
        end

        if a.respond_to?(:is_proxy_object)
          valid = a.proxy_type <= method_type.arg_types[i]
        else

          valid = a.rtc_type <= method_type.arg_types[i]
        end

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
