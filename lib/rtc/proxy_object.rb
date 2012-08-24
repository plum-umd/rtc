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
      @object.inspect
#      rtc_to_str
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
      
      method_types = @object.class.get_typesigs(method_name.to_s)

      if method_types == nil
        Rtc::MasterSwitch.turn_on
        if method_args == []
          ret = @object.send method_name
        else
          ret = @object.send method_name, *method_args
        end
        Rtc::MasterSwitch.turn_off    

        return ret
      end

      constraints = {}
      
      Rtc::MethodCheck.check_args(method_types, self, method_args, method_name, constraints)
        
      if constraints.empty?
        new_mt = method_types[0]
      else
        new_mt = method_types[0].replace_constraints(constraints)
      end

      stype = self.class.get_class_parameters
      stype = stype.replace_constraints(constraints)

      $gstype = stype

      i = 0
      new_mt.arg_types.each { |arg_type|
        method_args[i] = method_args[i].rtc_annotate(arg_type)
        i += 1
      }

      if not @proxy_type.has_method?(method_name)
        raise NoMethodError, self.rtc_to_str + " has no method " + method_name.to_s
      end

      if self.class.get_native_methods.include?(method_name.to_s)
        new_args = method_args.map {|a| a.object}
      else
        new_args = method_args
      end

      new_args.concat([stype, constraints, new_mt, "@@from_proxy@@"])

      Rtc::MasterSwitch.turn_on
      if new_args == nil
        ret = @object.send method_name
      else
        ret = @object.send method_name, *new_args
      end
      Rtc::MasterSwitch.turn_off    

      #      ret = ret.rtc_annotate(new_mt.return_type)

      if @object.class.get_mutant_methods.include?(method_name.to_s)
        if not @object.rtc_type <= new_mt.return_type
          raise Rtc::TypeMismatchException, "type mismatch on return value"
        end
        @proxy_type = new_mt.return_type
      else
        ret.proxy_type = new_mt.return_type
      end

      @proxy_type = $gstype

      return ret
    end
  end
end
