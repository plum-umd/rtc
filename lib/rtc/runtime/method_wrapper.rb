require 'rtc/runtime/master_switch.rb'
require 'rtc/options'
module Rtc
  
  class TypeMismatchException < StandardError; end
  
  class MethodWrapper
    class NoArgument; end
    def self.make_wrapper(class_obj, method_name)
      if Rtc::Disabled
        return nil
      end
      MethodWrapper.new(class_obj, method_name)
    end

    def check_args(passed_arguments, method_type)
      return false unless method_type.min_args <= passed_arguments.size
      return false unless passed_arguments.size <= method_type.max_args or method_type.max_args == -1
      #check the first set of required arguments
      i = 0
      parameter_layout = method_type.parameter_layout
      while i < parameter_layout[:required][0]
        return false unless passed_arguments[i].rtc_type <= method_type.arg_types[i]
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
      
      method_type = invokee.rtc_typeof(@method_name)
      candidate_types = []
      
      if method_type.instance_of?(Rtc::Types::IntersectionType)
        possible_method_types = method_type.types
      else
        possible_method_types = [method_type]
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
        message = "Function " + @method_name.to_s + " argument type mismatch:" +
          "   Expected function type: " + method_type.to_s
        #for a in arg_list
        #  arg_types.push(a.rtc_type)
        #  arg_values.push(a)
        #end

        #puts "   Actual argument types: " + arg_types.to_s
        #puts "   Actual argument values: " + arg_values.to_s
        on_error(message)
      end

      blk = arg_vector[:block]

      Rtc::MasterSwitch.turn_on
      if blk
        ret_value = @original_method.bind(invokee).call(*regular_args, &blk)
      else
        ret_value = @original_method.bind(invokee).call(*regular_args)
      end
      Rtc::MasterSwitch.turn_off

      return_valid = candidate_types.any? {
        |ct|
        ret_value.rtc_type <= ct.return_type 
      }
      
      if not return_valid
        message = "Function " + @method_name.to_s + " return type mismatch: " + "   Expected function type: " + method_type.to_s
        #puts "   Actual return type #{ret_value.rtc_type}"
        #puts "   Actual return value: " + ret_value.to_s
        on_error(message)
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
    
    @@arg_vector_name = "__rtc_args"
    @@block_name = "__rtc_block"
    @@no_check_invoke = "
    if #{@@block_name}.nil?
      return original_method.bind(self).call(*#{@@arg_vector_name})
    else
      return original_method.bind(self).call(*#{@@arg_vector_name}, &#{@@block_name})
    end
    "
    
    def initialize(class_obj,method_name)
      @method_name = method_name
      @class_obj = class_obj
      this_obj = self
      original_method = @original_method = class_obj.instance_method(method_name)
      wrapper_lambda = eval("lambda {
        |#{gen_arg_string()}|
        if Rtc::MasterSwitch.is_on?
          Rtc::MasterSwitch.turn_off 
          args = #{gen_collapse_args()}
          begin
            this_obj.invoke(self, args)
          ensure
            Rtc::MasterSwitch.turn_on
          end
        else
          #{@@no_check_invoke}
        end
      }")
      class_obj.send(:define_method, method_name, wrapper_lambda)
    end
    
    def gen_arg_string()
      return "*#{@@arg_vector_name}, &#{@@block_name}"
    end
    def gen_collapse_args()
      "{ :args => #{@@arg_vector_name}, :block => #{@@block_name}}"
    end
  end
end
