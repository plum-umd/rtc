require 'weakref'

module Rtc
  class ProxyObject
    attr_reader :object
    attr_reader :types

    def initialize(object, type)
      # type = WeakRef.new(type)      
      # FIXME:  weak ref caused problems with Rtc types

      @object = object
      @types = Set.new([type])
    end

    def add_type(type)
      found = @types.any? {|t| t <= type and type <= t}
      @types.add(type) if found == false

      self
    end

    def method_missing(*args, &block)
      # FIXME: support block, probably with define_method
      method = args[0]

      # FIXME: some hard coded stuff here
      if @types.to_a[-1].to_s.start_with?("Array<")
        methods = Array.new.methods

        if not(methods.include?(method))
          raise Rtc::NoMethodException, @types.to_a[-1].to_s + " has no method " + method.to_s
        end
      else
        puts @types.to_a[-1].class
      end

      if args[1] == nil
        @object.send method
      else
        @object.send method, args[1]
      end
    end
  end
end
