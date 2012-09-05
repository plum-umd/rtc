require 'weakref'
require 'rtc/runtime/method_check.rb'

module Rtc
  class ProxyObject
    attr_reader :object
    attr_reader :proxy_type
    attr_writer :proxy_type

    alias :old_inspect :inspect

    def initialize(object, proxy_type)
      # type = WeakRef.new(type)      
      # FIXME:  weak ref caused problems with Rtc types

      @object = object
      @proxy_type = proxy_type
    end

    def is_proxy_object
      true
    end

    def class
      @object.class
    end

    def inspect
#      @object.inspect
      rtc_to_str
    end

    def rtc_inspect
      rtc_to_str
    end

    def rtc_type
      @object.rtc_type
    end

    def to_s
      @object.to_s
    end

    def rtc_to_s
      status = Rtc::MasterSwitch.is_on?
      Rtc::MasterSwitch.turn_off if status == true
      str = "{ProxyObject @object: " + @object.inspect + ", @proxy_type: " + @proxy_type.inspect + "}"
      Rtc::MasterSwitch.turn_on if status == true
      str
    end

    def rtc_to_str
      status = Rtc::MasterSwitch.is_on?
      Rtc::MasterSwitch.turn_off if status == true
      str = "{ProxyObject @object: " + @object.inspect + ", @proxy_type: " + @proxy_type.to_s + "}"
      Rtc::MasterSwitch.turn_on if status == true
      str
    end

    def method_missing(*args, &block)
      status = Rtc::MasterSwitch.is_on?
      Rtc::MasterSwitch.turn_off if status

      constraints = {}
      method_name = args[0]
      method_args = args[1..-1]
      native = false
      mutate = false
      
      method_type_info = @object.class.get_typesig_info(method_name)

      if method_type_info == nil
        if method_args == []
          Rtc::MasterSwitch.turn_on
          ret = @object.send method_name
          Rtc::MasterSwitch.turn_off    
        else
          Rtc::MasterSwitch.turn_on
          ret = @object.send method_name, *method_args
          Rtc::MasterSwitch.turn_off    
        end

        return ret
      end

      constraints = {}
      method_types = method_type_info.map {|t| t.sig}

      Rtc::MethodCheck.check_args(method_types, self, method_args, method_name, constraints)
        
      if constraints.empty?
        new_mt = method_types[0]
      else
        new_mt = method_types[0].replace_constraints(constraints)
      end

      i = 0
      new_mt.arg_types.each { |arg_type|
        method_args[i] = method_args[i].rtc_annotate(arg_type)
        i += 1
      }

      if not @proxy_type.has_method?(method_name)
        raise NoMethodError, self.rtc_to_str + " has no method " + method_name.to_s
      end


      unwrap_arg_pos = method_type_info.map {|i| i.unwrap}
      unwrap_arg_pos = unwrap_arg_pos[0]
      
      new_args = method_args

      unwrap_arg_pos.each {|p|
        new_args[p] = method_args[p].object
      }

      stype = nil
      new_args.concat([stype, constraints, new_mt, "@@from_proxy@@"])

      if new_args == nil
        Rtc::MasterSwitch.turn_on
        ret = @object.send method_name
        Rtc::MasterSwitch.turn_off    
      else
        Rtc::MasterSwitch.turn_on
        ret = @object.send method_name, *new_args
        Rtc::MasterSwitch.turn_off    
      end

      if @object.class.get_mutant_methods.include?(method_name.to_s)
        mutate = true

        if not @object.rtc_type <= new_mt.return_type
          raise Rtc::TypeMismatchException, "type mismatch on return value"
        end
      end

      if mutate == true and not self.proxies == nil
        ret_type = ret.object.rtc_type

         self.proxies.each {|p|
          if not ret_type <= p.proxy_type
            raise Rtc::TypeMismatchException, "Return object run-time type #{ret_type.inspect} NOT <= one of the object\'s proxy list types #{p.proxy_type.inspect}"
          end
        }
      end

      Rtc::MasterSwitch.turn_on if not Rtc::MasterSwitch.is_on?

      return ret
    end
  end
end
