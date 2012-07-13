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

#    def check_args(passed_arguments, method_type, param_arg_pos)
    def check_args(passed_arguments, method_type)
      return false unless method_type.min_args <= passed_arguments.size
      return false unless passed_arguments.size <= method_type.max_args or method_type.max_args == -1

      pap = []

      if method_type.has_parameterized
        pap = method_type.get_parameterized_arg_pos
      end

      param_arg_pos = Set.new(pap)

      #check the first set of required arguments
      i = 0
      parameter_layout = method_type.parameter_layout
      while i < parameter_layout[:required][0]
        if param_arg_pos.include?(i)
          return false unless passed_arguments[i].rtc_type.le_poly(method_type.arg_types[i], @constraints)
        else
          return false unless passed_arguments[i].rtc_type <= method_type.arg_types[i]
        end

        i+=1
      end
      
      #check the second set of required arguments
      i = 1
      while i <= parameter_layout[:required][1]
        return false unless passed_arguments[-i].rtc_type <= method_type.arg_types[-i]
        i += 1
      end
      
      #check the optional arguments
      opt_offset = parameter_layout[:required][0]
      iter_end = passed_arguments.size - parameter_layout[:required][1]
      i = 0
      while i < parameter_layout[:opt] and opt_offset + i < iter_end
        return false unless passed_arguments[opt_offset + i].rtc_type <= method_type.arg_types[opt_offset + i].type
        i += 1
      end
      
      #we still have some left for the rest argument (which must come after the optional arguments)
      #so check that
      if i + opt_offset < iter_end
        rest_args = passed_arguments.slice(i+opt_offset, iter_end - (i+opt_offset))
        return false unless
          rest_args.rtc_type.type_of_param(0) <= method_type.arg_types[parameter_layout[:required][0] + parameter_layout[:opt]].type
      end

      return true
    end

    def invoke(invokee, arg_vector)
      regular_args = arg_vector[:args]

      method_type = invokee.rtc_typeof(@method_name, @class_obj)
      candidate_types = []

      if method_type.instance_of?(Rtc::Types::IntersectionType)
        possible_method_types = method_type.types
      else
        possible_method_types = [method_type]
      end

      instantiated = false

      if invokee.annotated_methods
        for k,v in invokee.annotated_methods
          if k.to_s == @method_name
            instantiated = true
            type = invokee.annotated_methods[k]
            possible_method_types = [type]
            break
          end
        end
      end

      for mt in possible_method_types
        if check_args(regular_args, mt)
          candidate_types.push(mt)
        end
      end

      if candidate_types.empty?
        #arg_types = []
        #arg_values = []
        #puts "Function " + @method_name.to_s + " argument type mismatch:"
        #puts "   Expected function type: " + method_type.to_s
        
        if instantiated
          message = "Function #{@class_obj.name.to_s}##{@method_name.to_s}  argument type mismatch:" +
            "   Expected INSTANTIATED function type: " + possible_method_types.to_s
        else
          message = "Function #{@class_obj.name.to_s}##{@method_name.to_s}  argument type mismatch:" +
            "   Expected function type: " + method_type.to_s
        end
        #for a in arg_list
        #  arg_types.push(a.rtc_type)
        #  arg_values.push(a)
        #end

        #puts "   Actual argument types: " + arg_types.to_s
        #puts "   Actual argument values: " + arg_values.to_s
        on_error(message)
      end

      blk = arg_vector[:block]

      if instantiated and blk
        blk.block_type = possible_method_types[0].block_type
      end

      Rtc::MasterSwitch.turn_on

      if blk
        wb = wrap_block(blk)
        ret_value = @original_method.bind(invokee).call(*regular_args, &wb)
      else
        ret_value = @original_method.bind(invokee).call(*regular_args)
      end

      Rtc::MasterSwitch.turn_off

      return_valid = candidate_types.any? {
        |ct|

        if ct.return_type.has_parameterized
          ret_value.rtc_type.le_poly(ct.return_type, @constraints, true)
        else
          ret_value.rtc_type <= ct.return_type 
        end
      }

      if not return_valid
        if instantiated
          message = "Function #{@class_obj.name.to_s}##{@method_name.to_s} return type mismatch: " + "   Expected INSTANTIATED function type: " + possible_method_types.to_s + 
          ", actual return type #{ret_value.rtc_type.to_s}"
        else
          message = "Function #{@class_obj.name.to_s}##{@method_name.to_s} return type mismatch: " + "   Expected function type: " + method_type.to_s + 
          ", actual return type #{ret_value.rtc_type.to_s}"
        end
        
        on_error(message)
      end

      if invokee.proxy_types
        proxy_type_valid = invokee.proxy_types.all? { |t|
          invokee.rtc_type <= t
        }

        if not proxy_type_valid
          raise Rtc::AnnotateException, "Invokee object type " + invokee.rtc_type.to_s + " NOT <= annotated types " + invokee.proxy_types_to_s.to_s + " after method " + invokee.class.to_s + '.' + @method_name
        end
      end

      ret_value
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
