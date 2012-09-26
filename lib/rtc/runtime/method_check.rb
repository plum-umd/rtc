require 'rtc/runtime/master_switch.rb'
require 'rtc/options'

module Rtc::MethodCheck
  
  def self.check_type(value, type)
    if value.is_proxy_object?
      value.rtc_type <= type
    elsif value.rtc_is_complex?
      if type.has_variables
        return value.rtc_type <= type
      end
      case type
      when Rtc::Types::ParameterizedType
        return type.nominal.klass == value.class
      when Rtc::Types::UnionType
        type.any? {
          |t|
          self.check_type(value, type)
        }
      when Rtc::Types::TopType
        return true
      else
        return false
      end    
    else
      return value.rtc_type <= type
    end
  end
  
  def self.check_args(method_types, method_name, args, has_block, class_obj)
    method_types.each { |mt|
      mt.type_variables.each { |tv| tv.start_solve }
    }
    possible_types = []
    for m in method_types
      expected_arg_types = m.arg_types
      if expected_arg_types.size != args.size
        next
      end
      #TODO(jtoman): rest and optional args
      valid = true
      args.zip(expected_arg_types).each {|arg, expected_arg_type|
        next if expected_arg_type.instance_of?(Rtc::Types::ProceduralType)
        if not self.check_type(arg,expected_arg_type)
          valid = false
          break
        end
      }
      if valid
        possible_types.push m
      end
    end

    if possible_types.size > 1
      possible_types2 = Set.new
      
      if has_block
        possible_types.each {|t|
          possible_types2.add(t) if t.block_type 
        }
      else
        possible_types.each {|t|
          possible_types2.add(t) if t.block_type == nil
        }
      end
      if possible_types2.size != 1
        raise Rtc::TypeMismatchException, "cannot infer type in intersecton type for method #{method_name}, whose types are #{method_types.inspect}"
      else
        possible_types = possible_types2
      end
    elsif possible_types.size == 0
      arg_types = args.map {|a|
        a.rtc_type 
      }
      
      raise Rtc::TypeMismatchException, "In method #{method_name}, annotated types are #{method_types.inspect}, but actual arguments are #{args.rtc_to_str}, with argument types #{arg_types.inspect}" +
        " for class #{class_obj}"
    elsif possible_types.size == 1
      correct_type = possible_types[0]
    end

    correct_type = possible_types.to_a[0]
    return correct_type
  end
end
