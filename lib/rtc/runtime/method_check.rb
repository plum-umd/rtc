require 'rtc/runtime/master_switch.rb'
require 'rtc/options'

module Rtc::MethodCheck
  def self.check_args(method_types, invokee, args, method_name, constraints)
    class_param_type = invokee.class.get_class_parameters
    
    unless Rtc::ClassModifier.get_class_parameters[invokee.class.to_s].nil?
      class_param_type = Rtc::ClassModifier.get_class_parameters[invokee.class.to_s]
    end

    if class_param_type.class == Array
      n = Rtc::Types::NominalType.of(invokee.class)
      class_param_type = Rtc::Types::ParameterizedType.new(n, class_param_type)
    end

    if class_param_type
      invokee.rtc_type.le_poly(class_param_type, {})
    end

    constraint_m = {}
    method_types.each {|i| constraint_m[i] = {}}


    if class_param_type and class_param_type.has_parameterized
      if invokee.respond_to?(:is_proxy_object)
        invokee.proxy_type.le_poly(class_param_type, constraints)
      else
        invokee.rtc_type.le_poly(class_param_type, constraints)
      end
    end

    method_types.each {|i| constraint_m[i] = constraints}
    possible_types = Set.new(method_types)

    for m in method_types
      expected_arg_types = m.sig.arg_types

      if expected_arg_types.size != args.size
        possible_types.delete(m)
        next
      end

      args.zip(expected_arg_types).each {|arg, expected_arg_type|
        b = true
        next if expected_arg_type.instance_of?(Rtc::Types::ProceduralType)

        if expected_arg_type.has_parameterized
          if arg.respond_to?(:is_proxy_object)
            b = arg.proxy_type.le_poly(expected_arg_type, constraint_m[m])
          else
            b = arg.rtc_type.le_poly(expected_arg_type, constraint_m[m])
          end

          possible_types.delete(m) unless b
        else
          if arg.respond_to?(:is_proxy_object)
            b = arg.proxy_type <= expected_arg_type
          else
            b = arg.rtc_type <= expected_arg_type
          end
          
          possible_types.delete(m) unless b
        end
      }
    end

    if possible_types.size > 1
      raise Rtc::TypeMismatchException, "cannot infer type in intersecton type for method #{method_name}, whose types are #{method_types.inspect}"
    elsif possible_types.size == 0
      arg_types = args.map {|a| 
        if a.respond_to?(:is_proxy_object)
          a.proxy_type
        else
          a.rtc_type
        end
      }

      raise Rtc::TypeMismatchException, "In method #{method_name}, annotated types are #{method_types.inspect}, but actual arguments are #{args.rtc_to_str}, with argument types #{arg_types.inspect}"
    end

    correct_type = possible_types.to_a[0]
    constraints = constraint_m[correct_type]

    return correct_type
  end
end
