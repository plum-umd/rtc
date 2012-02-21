module Rtc
  class MethodWrapper
    class NoArgument; end
    #TODO(jtoman): Make error reporting better
    #XXX(jtoman): for some reason I thought a static method was a good idea. Now I'm not so sure.
    def self.make_wrapper(class_obj, method_name)
      MethodWrapper.new(class_obj, method_name)
    end
    def invoke(invokee, arg_vector)
      regular_args = arg_vector[:args]
      passed_and_formals = regular_args.zip(@no_block_params)
      arg_list = []
      method_type = invokee.rtc_typeof(@method_name)
      passed_and_formals.each_with_index {
        |p_f,index|
        passed,formal = p_f
        if formal[0] == :opt
          next if passed.instance_of?(Rtc::MethodWrapper::NoArgument)
          raise(Exception,"Type mismatch") unless passed.rtc_type <= method_type.arg_types[index].type
          arg_list << passed
        elsif formal[0] == :rest
          actual_rest_type = passed.rtc_type.type_of_param(0) 
          raise(Exception, "Type mismatch") unless actual_rest_type <= method_type.arg_types[index].type 
          arg_list += passed
        else
          raise(Exception, "Type mismatch") unless passed.rtc_type <= method_type.arg_types[index]
          arg_list << passed
        end
      }
      if arg_vector[:block]
        ret_value = @original_method.bind(invokee).call(*arg_list, &arg_vector[:block])
      else
        ret_value = @original_method.bind(invokee).call(*arg_list)
      end
      raise(Exception, "Return type mismatch") unless ret_value.rtc_type <= method_type.return_type
      ret_value
    end
    private
    def initialize(class_obj,method_name)
      @method_name = method_name
      @class_obj = class_obj
      this_obj = self
      @original_method = class_obj.instance_method(method_name)
      @no_block_params = @original_method.parameters.reject { |param_spec| param_spec[0] == :block }
      wrapper_lambda = eval("lambda {
        |#{gen_arg_string()}|
        args = #{gen_collapse_args()}
        this_obj.invoke(self, args)
      }")
      class_obj.send(:define_method, method_name, wrapper_lambda)
    end
    
    def make_single_arg_string(parameter)
      case parameter[0]
      when :req
        parameter[1].to_s
      when :opt
        "#{parameter[1].to_s} = Rtc::MethodWrapper::NoArgument.new"
      when :rest
        if parameter.size == 1
          "*__rtc_rest"
        else
          "*#{parameter[1].to_s}"
        end
      else
        raise "FATAL: Unrecognized parameter type"
      end
    end
    def gen_arg_string()
      (@no_block_params.map {
        |param_spec|
        make_single_arg_string(param_spec)
      } + ["&__rtc_block"]).join(", ")
    end
    def gen_collapse_args()
      "{ :args => [" + @no_block_params.map {
        |param_spec|
        if param_spec[0] == :rest and param_spec.size == 1
          "__rtc_rest"
        else
          param_spec[1].to_s
        end
      }.join(", ") + "], :block => __rtc_block}"
    end
  end
end
