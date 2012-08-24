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
      if Rtc::Disabled
        return nil
      end
      MethodWrapper.new(class_obj, method_name)
    end

    def wrap_block(x)
      Proc.new {|v| x.call(v)}
    end

    def invoke(invokee, arg_vector)

      regular_args = arg_vector[:args]

      if regular_args[-1] == "@@from_proxy@@"

        new_mt = regular_args[-2]

        if regular_args.length == 4
          regular_args = []
        else
#          if self.class.get_native_methods.include?(@method_name.to_s)
            regular_args = regular_args[0..regular_args.length-5]
 #         else
  #        end
        end

      else
        method_types = invokee.class.get_typesigs(@method_name.to_s)
        method_type = method_types[0]

        Rtc::MethodCheck.check_args(method_types, invokee, regular_args, @method_name, @constraints)

        if @constraints.empty?
          new_mt = method_types[0]
        else
          new_mt = method_types[0].replace_constraints(@constraints)
        end

        i = 0
        new_mt.arg_types.each { |arg_type|
          regular_args[i] = regular_args[i].rtc_annotate(arg_type)
          i += 1
        }

        if not invokee.rtc_type.has_method?(@method_name)
          raise NoMethodError, invokee.inspect + " has no method " + method_name.to_s
        end
      end

      if invokee.class.get_native_methods.include?(@method_name)
        regular_args = regular_args.map {|a|
          if a.respond_to?(:is_proxy_object)
            a.object
          else
            a
          end
        }
      end

      Rtc::MasterSwitch.turn_on
      ret_value = @original_method.bind(invokee).call(*regular_args)
      Rtc::MasterSwitch.turn_off

#      if ret_value.eql?(invokee) and invokee.class.get_mutant_methods.include?(@method_name.to_s)
#          return ret_value.rtc_cast(method_type.return_type)
#      end


      if new_mt.return_type.has_parameterized
        ret_valid = ret_value.rtc_type.le_poly(new_mt.return_type, @constraints)
      else
        ret_valid = ret_value.rtc_type <= new_mt.return_type
      end

      if ret_valid == false
        raise TypeMismatchException, "invalid return type in " + @method_name.to_s
      end

      if ret_value.respond_to?(:is_proxy_object)
        ret_value.proxy_type = new_mt.return_type
        return ret_value
      else
        new_obj = Rtc::ProxyObject.new(ret_value, new_mt.return_type)
        return new_obj
      end
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
      @constraints = {}

      class_obj = @class_obj
      constraints = @constraints

      this_obj = self
      original_method = @original_method = class_obj.instance_method(method_name)
      wrapper_lambda = lambda {
        |*__rtc_args, &__rtc_block|
        if Rtc::MasterSwitch.is_on?
          Rtc::MasterSwitch.turn_off 
          args = {:args => __rtc_args, :block => __rtc_block }

          if args[:block]
            method_type = self.rtc_typeof(method_name, class_obj)
            args[:block] = BlockProxy.new(args[:block], method_type, method_name, constraints, class_obj)
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

    def initialize(proc, type, method_name, constraints, class_obj)
      @proc = proc
      @method_type = type
      @block_type = type.block_type
      @method_name = method_name
      @constraints = constraints
      @class_obj = class_obj
    end

    def call(*args)
      arg = args[0]
      args_valid = check_args(args, @block_type)

      if not args_valid
        message = "Function #{@class_obj.name.to_s}##{@method_name.to_s} block argument type mismatch:" +
          "   Expected function type: " + method_type.to_s
        on_error(message)
      end

      ret = @proc.call(arg)

      if @block_type.return_type.has_parameterized
        return_valid = ret.rtc_type.le_poly(@block_type.return_type, @constraints)
      else
        return_valid = ret.rtc_type <= @block_type.return_type
      end

      if not return_valid # ret.rtc_type <= @block_type.return_type 
        message = "Function #{@class_obj.name.to_s}##{@method_name.to_s} block return type mismatch:" +
          "   Expected function type: " + method_type.to_s
        on_error(message)
      end

      ret
    end
  end
end
