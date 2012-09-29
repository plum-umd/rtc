require 'weakref'
require 'rtc/runtime/method_check.rb'

class Array
  alias :old_eq :==
  alias :old_eql? :eql?
  alias :old_equal? :equal?

  def ==(other)
    if other.is_proxy_object?
      old_eq(other.object)
    else
      old_eq(other)
    end
  end

  def eql?(other)
    if other.is_proxy_object?
      old_eql?(other.object)
    else
      old_eql?(other)
    end
  end

  def equal?(other)
    if other.is_proxy_object?
      old_equal?(other.object)
    else
      old_equal?(other)
    end
  end
end

class Hash
  alias :old_eq :==
  alias :old_eql? :eql?
  alias :old_equal? :equal?

  def ==(other)
    if other.is_proxy_object?
      old_eq(other.object)
    else
      old_eq(other)
    end
  end

  def eql?(other)
    if other.is_proxy_object?
      old_eql?(other.object)
    else
      old_eql?(other)
    end
  end

  def equal?(other)
    if other.is_proxy_object?
      old_equal?(other.object)
    else
      old_equal?(other)
    end
  end
end

class Symbol
  alias :old_eq :==
  alias :old_eql? :eql?
  alias :old_equal? :equal?

  def ==(other)
    if other.is_proxy_object?
      old_eq(other.object)
    else
      old_eq(other)
    end
  end

  def eql?(other)
    if other.is_proxy_object?
      old_eql?(other.object)
    else
      old_eql?(other)
    end
  end

  def equal?(other)
    if other.is_proxy_object?
      old_equal?(other.object)
    else
      old_equal?(other)
    end
  end
end

class String
  alias :old_eq :==
  alias :old_eql? :eql?
  alias :old_equal? :equal?

  def ==(other)
    if other.is_proxy_object?
      old_eq(other.object)
    else
      old_eq(other)
    end
  end

  def eql?(other)
    if other.is_proxy_object?
      old_eql?(other.object)
    else
      old_eql?(other)
    end
  end

  def equal?(other)
    if other.is_proxy_object?
      old_equal?(other.object)
    else
      old_equal?(other)
    end
  end
end

class Object
  alias :old_eq :==
  alias :old_eql? :eql?
  alias :old_equal? :equal?

  def is_proxy_object?
    return false
  end

  def ==(other)
    if other.is_proxy_object?
      old_eq(other.object)
    else
      old_eq(other)
    end
  end

  def eql?(other)
    if other.is_proxy_object?
      old_eql?(other.object)
    else
      old_eql?(other)
    end
  end

  def equal?(other)
    if other.is_proxy_object?
      old_equal?(other.object)
    else
      old_equal?(other)
    end
  end

  def rtc_get_proxy
    rtc_meta[:proxy_context][-1]
  end

  def rtc_push_proxy(p)
    rtc_meta[:proxy_context].push(p)
  end
  
  def rtc_pop_proxy()
    rtc_meta[:proxy_context].pop
  end
end

module Rtc

  class ProxyObject
    attr_reader :object
    attr_reader :proxy_type
    attr_writer :proxy_type

    alias :old_inspect :inspect

    def initialize(object, proxy_type)
      if object.is_a?(Rtc::Types::Type)
        raise "this should never happen"
      end
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
      if other.is_proxy_object?
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

    def is_proxy_object?
      true
    end

    def rtc_type
      @proxy_type
    end
    
    def true_rtc_type
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

      #if @object.class.get_typesig_info(method)
      #  args.push({'__rtc_special' => true, 'self_proxy' => self})
      #end

      begin
        #puts "about to push proxy for #{method}"
        @object.rtc_push_proxy(self)
        #puts "done pushing proxy for #{method}"
        Rtc::MasterSwitch.turn_on
        r = @object.send method, *args, &block
      ensure
        Rtc::MasterSwitch.turn_off
        #puts "about to call pop proxy for #{method}"
        @object.rtc_pop_proxy
        #puts "done popping proxy #{method}"
        Rtc::MasterSwitch.turn_on
        #puts "master switch is on in #{method}"
        #puts "call depth #{caller.length}"
      end
      #puts "returning from #{method}"
      return r
    end
  end

  class TupleProxy < ProxyObject
    def initialize(object, proxy_type)
      raise "Error, type must be a tuple type!" unless proxy_type.is_a?(Rtc::Types::TupleType)
      super(object, proxy_type)
    end
    
    def [](*args)
      if args.length == 2
        arg = args[0]..args[1]
      elsif args.length == 1
        arg = args[0]
      end
      if arg.is_a?(Numeric)
        type = proxy_type.ordered_params[arg]
        return nil unless type
        return object[arg].rtc_annotate(type)
      elsif arg.is_a?(Range)
        types = proxy_type.ordered_params[arg]
        return nil unless types
        return [] if types.empty?
        values = object[arg]
        return values.rtc_annotate(Rtc::Types::TupleType.new(types))
      else
        raise "snake! you can't do that! you'll create a type paradox!"
      end
    end

    def []=(*args)
      if args.length == 2 and args[0].is_a?(Numeric)
        index = args[0]
        type = proxy_type.ordered_params[index]
        raise "bad index!" unless type
        raise Rtc::TypeMismatchException, "bad tuple value" unless Rtc::MethodCheck.check_type(args[1], type)
        object[index] = args[1]
      else
        if args[0].is_a?(Range)
          range = args[0]
          element_index = 1
        else
          range = args[0]..args[1]
          element_index = 2
        end
        types = proxy_type.ordered_params[range]
        raise "bad index!" if types.nil? or types.empty?
        elements = args[element_index]
        unless elements.is_a?(Array)
          elements = [elements]
        end
        raise "cannot delete elements from a tuple" unless elements.size == types.size
        i = 0
        len = elements.length
        while i < len
          raise Rtc::TypeMismatchException, "tuple type mismatch" unless Rtc::MethodCheck.check_type(elements[i], types[i])
          i += 1
        end
        object[range] = elements
        args[element_index]
      end
    end
    def to_ary
      object.zip(proxy_type.ordered_params).map {
        |t,v|
        t.rtc_annotate(v)
      }
    end
    def to_a
      object.zip(proxy_type.ordered_params).map {
        |t,v|
        t.rtc_annotate(v)
      }
    end
  end
end

