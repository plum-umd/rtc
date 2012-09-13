require 'weakref'
require 'rtc/runtime/method_check.rb'

class String
  alias :old_eql? :eql?

  def eql?(other)
    if other.respond_to?(:is_proxy_object)
      old_eql?(other.object)
    else
      old_eql?(other)
    end
  end
end

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

    def hash
      status = Rtc::MasterSwitch.is_on?
      Rtc::MasterSwitch.turn_off if status
      r = @object.hash

      Rtc::MasterSwitch.turn_on if status
      r
    end

    def eql?(other)
      if other.respond_to?(:is_proxy_object)
        r = @object.eql?(other.object)
      else
        r = @object.eql?(other)
      end

      r
    end

    def ==(other)
      eql?(other)
    end

    def rtc_to_s
      status = Rtc::MasterSwitch.is_on?
      Rtc::MasterSwitch.turn_off if status
      str = "{ProxyObject @object: #{@object.inspect}, @proxy_type: #{@proxy_type.inspect}}"
      Rtc::MasterSwitch.turn_on if status
      str
    end

    def rtc_to_str
      status = Rtc::MasterSwitch.is_on?
      Rtc::MasterSwitch.turn_off if status
#      str = "{ProxyObject @object: " + @object.inspect + ", @proxy_type: " + @proxy_type.to_s + "}"
      str = "{ProxyObject @object: #{@object.rtc_to_str}, @proxy_type: #{@proxy_type.rtc_to_str}}"
      Rtc::MasterSwitch.turn_on if status
      str
    end

    def method_missing(method, *args, &block)
      unless Rtc::MasterSwitch.is_on?
        return @object.send method, *args, &block
      end

      Rtc::MasterSwitch.turn_off

      arg_size = args.size
      mutate = false      
      method_types = @object.class.get_typesig_info(method)

      unless @proxy_type.has_method?(method)
        raise NoMethodError, "#{self.rtc_to_str} has no method #{method}"
      end

      if method_types
        extra_arg = {}
        extra_arg['__rtc_special'] = true
        extra_arg['self_proxy'] = self
        args.push(extra_arg)
      end

      Rtc::MasterSwitch.turn_on 
      
      return @object.send method, *args, &block
    end
  end
end
