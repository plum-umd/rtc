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
#      str = "{ProxyObject @object: " + @object.inspect + ", @proxy_type: " + @proxy_type.to_s + "}"
      str = "{ProxyObject @object: " + @object.rtc_to_str + ", @proxy_type: " + @proxy_type.rtc_to_str + "}"
      Rtc::MasterSwitch.turn_on if status == true
      str
    end

    def method_missing(*args, &block)
      status = Rtc::MasterSwitch.is_on?
      Rtc::MasterSwitch.turn_off if status

      method_name = args[0]
      method_args = args[1..-1]
      arg_size = method_args.size

      if status == false
        if method_args == []
          if block
            ret = @object.send method_name, &block
          else
            ret = @object.send method_name
          end
        else
          if block
            ret = @object.send method_name, *method_args, &block
          else
            ret = @object.send method_name, *method_args
          end
        end
        
        return ret
      end

      mutate = false      
      method_types = @object.class.get_typesig_info(method_name)

      if not @proxy_type.has_method?(method_name)
        raise NoMethodError, self.rtc_to_str + " has no method " + method_name.to_s
      end

      if method_types != nil
        extra_arg = {}
        extra_arg['__rtc_special'] = true
        extra_arg['self_proxy'] = self
        method_args.push(extra_arg)
      end

      Rtc::MasterSwitch.turn_on 
      
      if block
        ret = @object.send method_name, *method_args, &block
      else
        ret = @object.send method_name, *method_args
      end
      
      Rtc::MasterSwitch.turn_off    

      Rtc::MasterSwitch.turn_on if status == true

      return ret
    end
  end
end
