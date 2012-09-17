require 'weakref'
require 'rtc/runtime/method_check.rb'

class Object
  alias :old_eq :==
  alias :old_eql? :eql?
  alias :old_equal? :equal?

  def ==(other)
    if other.respond_to?(:is_proxy_object)
      old_eq(other.object)
    else
      old_eq(other)
    end
  end

  def eql?(other)
    if other.respond_to?(:is_proxy_object)
      old_eql?(other.object)
    else
      old_eql?(other)
    end
  end

  def equal?(other)
    if other.respond_to?(:is_proxy_object)
      old_equal?(other.object)
    else
      old_equal?(other)
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

    def !~(other)
      @object !~ (other)
    end

    def <=>(other)
      @object <=> (other)
    end

    def ===(other)
      @object === (other)
    end

    def =~(other)
      @object =~ (other)
    end

    def class
      @object.class
    end

    def clone 
      @object.clone
    end

    # def define_singleton_method 
    # def display(port=$>)
    # def dup

    def to_enum(method, *args)
      @object.to_enum(method, args)
    end

    def enum_for(method, *args)
      @object.enum_for(method, args)
    end

    def ==(other)
      eql?(other)
    end

    def equal?(other)
      eql?(other)
    end

    def eql?(other)
      if other.respond_to?(:is_proxy_object)
        @object.eql?(other.object)
      else
        @object.eql?(other)
      end
    end

    # def extend
    # def freeze
    # def frozen?

    def hash
      status = Rtc::MasterSwitch.is_on?
      Rtc::MasterSwitch.turn_off if status
      r = @object.hash
      Rtc::MasterSwitch.turn_on if status
      r
    end

    def instance_of?(c)
      @object.instance_of?(c)
    end

    def inspect
      @object.inspect
    end

    def instance_variable_defined?(symbol)
      @object.instance_variable_defined?(symbol)
    end

    def instance_variable_get(symbol)
      @object.instance_variable_get(symbol)
    end

    def instance_variable_set(symbol, obj)
      @object.instance_variable_set(symbol, obj)
    end

    def instance_variables
      @object.instance_variables
    end

    def is_a?(c)
      @object.is_a?(c)
    end

    def kind_of?(c)
      @object.kind_of?(c)
    end

    def method(sym)
      @object.method(sym)
    end

    def nil?
      @object.nil?
    end

    def __id__
      @object.__id__
    end

    def object_id
      @object.object_id
    end

    def public_method(sym)
      @object.public_method(sym)
    end

    # def public_send
    # def respond_to?

    def respond_to_missing?(symbol, *i)
      @object.respond_to_missing?(symbol, i)
    end

    # def send

    def singleton_class
      @object.singleton_class
    end

    def singleton_methods
      @object.singleton_methods
    end

    def taint
      @object.taint
    end

    def tainted?
      @object.tainted?
    end

    # def tap

    def to_s
      @object.to_s
    end

    def trust
      @object.trust
    end

    def untaint
      @object.untaint
    end

    def untrust
      @object.untrust
    end

    def untrusted?
      @object.untrusted
    end

    # private def remove_instance_variable(symbol)

    def is_proxy_object
      true
    end

    def rtc_type
      @object.rtc_type
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

      unless @proxy_type.has_method?(method)
        raise NoMethodError, "#{self.rtc_to_str} has no method #{method}"
      end

      if @object.class.get_typesig_info(method)
        args.push({'__rtc_special' => true, 'self_proxy' => self})
      end

      Rtc::MasterSwitch.turn_on 
      
      return @object.send method, *args, &block
    end
  end
end
