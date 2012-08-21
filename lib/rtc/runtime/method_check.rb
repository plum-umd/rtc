require 'rtc/runtime/master_switch.rb'
require 'rtc/options'

module Rtc::MethodCheck
  def self.check_args(method_types, invokee, args, method_name, constraints)
    method_type = method_types[0]
    method_arg_types = method_type.arg_types
    class_param_type = invokee.class.get_class_parameters

    if class_param_type != nil
      if class_param_type.has_parameterized
        if invokee.respond_to?(:is_proxy_object)
          invokee.proxy_type.le_poly(class_param_type, constraints)
        else
          invokee.rtc_type.le_poly(class_param_type, constraints)
        end
      end
    end

    args.zip(method_arg_types).each {|arg, method_arg_type|
      b = true

      if method_arg_type.has_parameterized
        if arg.respond_to?(:is_proxy_object)
          b = arg.proxy_type.le_poly(method_arg_type, constraints)
        else
          b = arg.rtc_type.le_poly(method_arg_type, constraints)
        end

        if b == false
          raise Rtc::TypeMismatchException, "Cannot get solve for polymorphic types for method " + method_name.to_s
        end
      else
        if arg.respond_to?(:is_proxy_object)
          b = arg.proxy_type <= method_arg_type
        else
          b = arg.rtc_type <= method_arg_type
        end

        if b == false
          raise Rtc::TypeMismatchException, "argument type mismatch for method " + method_name.to_s
        end
      end
    }
  end
end
