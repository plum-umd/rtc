# Classes for representing the various types recognized by rtc.
#
# Author:: Ryan W Sims (rwsims@umd.edu)

require 'set'
require 'singleton'
require 'rtc/runtime/native'

require 'rtc/runtime/class_loader'
require 'rtc/runtime/type_inferencer'

Dir.glob(File.dirname(__FILE__) + "/types/*.rb").each { |file|
  require_relative file
}

class Rtc::GlobalCache
  @@cache = Rtc::NativeHash.new
  def self.cache
    @@cache
  end
end

class Object
  def rtc_meta
    if defined? @_rtc_meta
      @_rtc_meta
    else
      if frozen? and Rtc::GlobalCache.cache[object_id] 
        return Rtc::GlobalCache.cache[object_id]
      end
      to_return = Rtc::NativeHash.new;
      to_return[:annotated] = false
      to_return[:no_subtype] = false
      to_return[:iterators] = Rtc::NativeHash.new
      to_return[:_type] = nil
      to_return[:proxy_context] = Rtc::NativeArray.new
      if frozen?
        Rtc::GlobalCache.cache[object_id] = to_return
      else
        @_rtc_meta = to_return
      end
    end
  end

  def rtc_gc
    Rtc::GlobalCache.cache[object_id] = nil
  end
  
  @@old_freeze_meth = Object.instance_method(:freeze)
  
  def freeze
    # force the meta property to be intialized
    if not frozen?
      rtc_meta
    end
    @@old_freeze_meth.bind(self).call()
  end

  def rtc_type
    return Rtc::Types::BottomType.new if self == nil
    return rtc_get_type
  end
  
  def rtc_typeof(name, which_class = nil)
    name = name.to_s
    if name[0] == "@"
      self.rtc_type.get_field(name[1..-1], which_class)
    else
      self.rtc_type.get_method(name, which_class)
    end
  end
  
  def rtc_is_complex?
    if self.nil?
      false
    end
    not Rtc::Types::NominalType.of(self.class).type_parameters.empty?
  end
  
  protected
  
  def rtc_get_type
    if self.class.name == "Symbol"
      Rtc::Types::SymbolType.new(self)
    else
      class_obj = Rtc::Types::NominalType.of(self.class)

      if class_obj.type_parameters.size == 0
        class_obj
      elsif class_obj.klass == Array
          Rtc::Types::ParameterizedType.new(class_obj, Rtc::NativeArray[Rtc::TypeInferencer.infer_type(self.each)], true)
      elsif class_obj.klass == Set 
          Rtc::Types::ParameterizedType.new(class_obj, [Rtc::TypeInferencer.infer_type(self.each)], true)
      elsif class_obj.klass == Hash
          Rtc::Types::ParameterizedType.new(class_obj, Rtc::NativeArray[
            Rtc::TypeInferencer.infer_type(self.each_key),
            Rtc::TypeInferencer.infer_type(self.each_value)
          ], true)
      else
          #user defined parameterized classes
        iterators = class_obj.klass.rtc_meta[:iterators]
        tv = class_obj.type_parameters.map {
          |param|
          if iterators[param.symbol].nil?
            raise "Cannot infer type of type parameter #{param.symbol} on class #{self.class}"
          elsif iterators[param.symbol].is_a?(Proc)
            # this is a function call, not a hash lookup by the way
            # despite what the weird operator would imply
            enum = iterators[param.symbol][self]
          else
            enum = self.send(iterators[param.symbol])
          end
          Rtc::TypeInferencer.infer_type(enum)
        }

        Rtc::Types::ParameterizedType.new(class_obj, tv, true)
      end
    end
  end
end

class Module
  def rtc_get_type
    return Rtc::Types::NominalType.of(class << self; self; end)
  end
end

class Class
  def rtc_instance_typeof(name, include_super = true)
    my_type = Rtc::Types::NominalType.of(self)
    name = name.to_s
    if name[0] == "@"
      my_type.get_field(name[1..-1], include_super ? nil : self)
    else
      my_type.get_method(name, include_super ? nil : self)
    end
  end
end

class Rtc::TypeNarrowingError < StandardError; end

