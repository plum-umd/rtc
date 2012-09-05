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
      Rtc::MasterSwitch.turn_off 

      regular_args = arg_vector[:args]
      blk = arg_vector[:block]
      
      from_proxy = false

      if regular_args[-1] == "@@from_proxy@@"
        from_proxy = true
        new_mt = regular_args[-2]

        if regular_args.length == 4
          regular_args = []
        else
          regular_args = regular_args[0..regular_args.length-5]
        end
      else
        method_type_info = invokee.class.get_typesig_info(@method_name.to_s)
        method_types = method_type_info.map {|i| i.sig}
        method_type = method_types[0]

        Rtc::MethodCheck.check_args(method_types, invokee, regular_args, @method_name, @constraints)


        unwrap_arg_pos = method_type_info.map {|i| i.unwrap}
        unwrap_arg_pos = unwrap_arg_pos[0]
        
        mutate = method_type_info.map {|i| i.mutate}
        mutate = mutate[0]

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
          raise NoMethodError, invokee.inspect + " has no method " + @method_name.to_s
        end
      end

      if from_proxy == false
        unwrap_arg_pos.each {|pos| 
          regular_args[pos] = regular_args[pos].object
        }
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

      if new_mt.return_type.has_parameterized
        ret_valid = ret_value.rtc_type.le_poly(new_mt.return_type, @constraints)
      else
        ret_valid = ret_value.rtc_type <= new_mt.return_type
      end

      if ret_valid == false
        raise TypeMismatchException, "invalid return type in " + @method_name.to_s
      end
      

      if not @constraints.empty?
        new_mt = new_mt.replace_constraints(@constraints)
      end

      ret_proxy = ret_value.rtc_annotate(new_mt.return_type)


      if not ret_value.proxies == nil and from_proxy == false
        ret_type = ret_value.rtc_type 

        ret_value.proxies.each {|p|
          if not ret_type <= p.proxy_type
            raise Rtc::TypeMismatchException, "Return object run-time type #{ret_type.inspect} NOT <= one of the object\'s proxy list types #{p.proxy_type.inspect}"
          end
        }
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
      Rtc::MasterSwitch.turn_off

      arg = args[0]

      if @constraints.empty?
        method_type = @block_type
      else
        method_type = @block_type.replace_constraints(@constraints)
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

        if valid == false
          raise Rtc::TypeMismatchException, "block argument mismatch"
        end

        i += 1
      end

      Rtc::MasterSwitch.turn_on
      ret = @proc.call(arg)
      Rtc::MasterSwitch.turn_off

      return ret
    end
  end
end
