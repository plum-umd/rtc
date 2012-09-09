# Module that annotated classes must extend.
#
# Author:: Ryan W Sims (rwsims@umd.edu)

require 'rtc/annot_parser.tab'
require 'rtc/runtime/method_wrapper.rb'
require 'rtc/runtime/class_modifier.rb'
require 'rtc/proxy_object'
require 'set'

class TypeSigInfo
  attr_reader :sig
  attr_reader :mutate
  attr_reader :unwrap
  
  def initialize(sig, mutate, unwrap)
    @sig = sig
    @mutate = mutate
    @unwrap = unwrap
  end
end

class Object
  attr_reader :annotated_methods
  attr_reader :proxies
  attr_writer :proxies

  @@class_info = {}

  def rtc_to_str
    self.to_s
  end

  def self.get_mutant_methods
    return [] if not @@class_info.keys.include?(self)
    @@class_info[self]['mutant_methods']
  end

  def self.get_non_mutant_methods
    return [] if not @@class_info.keys.include?(self)
    @@class_info[self]['non_mutant_methods']
  end

  def self.add_to_typesigs(id, type, mutate, unwrap)
    if not @@class_info.keys.include?(self)
      @@class_info[self] = {}
      @@class_info[self]['mutant_methods'] = Set.new
      @@class_info[self]['non_mutant_methods'] = Set.new
      @@class_info[self]['typesigs'] = {}
    end

    if mutate == true
      @@class_info[self]['mutant_methods'].add(id)
    else
      @@class_info[self]['non_mutant_methods'].add(id)
    end

    ts = TypeSigInfo.new(type, mutate, unwrap)

    if @@class_info[self]['typesigs'].keys.include?(id)
      @@class_info[self]['typesigs'][id].push(ts)
    else
      @@class_info[self]['typesigs'][id] = [ts]
    end
  end

  def self.get_typesig_info(id)
    id = id.to_s
    return nil if not @@class_info.keys.include?(self)
    return nil if not @@class_info[self]['typesigs'].include?(id)
    @@class_info[self]['typesigs'][id]
  end

  def self.get_class_parameters
    params = Rtc::ClassModifier.get_class_parameters
    params[self]
  end

  def add_annotated_method(id, type)
    if @annotated_methods
      # FIXME: should this be intersection type
      @annotated_methods[m] = Rtc::Types::ProceduralType.new(ret_type, arg_types, blk_type)
    else
      @annotated_methods = {}
      @annotated_methods[m] = Rtc::Types::ProceduralType.new(ret_type, arg_types, blk_type)
    end
  end

  def add_type2(t)
    if @proxy_types
      found = @proxy_types.any? {|pt| t <= pt and pt <= t}
      @proxy_types.add(t) if found == false
    else
      @proxy_types = Set.new([t])
    end

    self
  end

  def proxy_types_to_s
    if @proxy_types
      return @proxy_types.to_a.map {|i| i.to_s} 
    else
      raise Exception, " object has no proxy_types"
    end
  end

  def rtc_inst(annotation_string)
    sigs = Rtc::TypeAnnotationParser.new(self.class).scan_str(annotation_string)
    sig = sigs[0]     # what to do when more than one type?

    method_name = sig.id
    method_type = sig.type

    if @annotated_methods
      @annotated_methods[method_name] = method_type
    else
      @annotated_methods = {}
      @annotated_methods[method_name] = method_type
    end

    self
  end  

  def rtc_cast(annotation_string)
    if annotation_string.class == String
      parser = Rtc::TypeAnnotationParser.new(self.class)
      annotated_type = parser.scan_str("##"+annotation_string)
    else
      annotated_type = annotation_string
    end
    
    if self.class == Rtc::ProxyObject
      my_type = self.object.rtc_type
    else
      my_type = self.rtc_type
    end

    if not my_type <= annotated_type
      raise Rtc::CastException, "object type " + my_type.to_s + " NOT <= rtc_cast argument type " + annotated_type.to_s
    end

    if self.class == Rtc::ProxyObject
      add_type(annotated_type)
    else
      Rtc::ProxyObject.new(self, annotated_type)
    end
  end
  
  def rtc_annotate(annotation_string)
    status = Rtc::MasterSwitch.is_on?
    Rtc::MasterSwitch.turn_off if status == true

    if annotation_string.class == String
      parser = Rtc::TypeAnnotationParser.new(self.class)
      annotated_type = parser.scan_str("##"+annotation_string)
    else
      annotated_type = annotation_string
    end

    if self.respond_to?(:is_proxy_object)
      if not self.proxy_type <= annotated_type
        raise Rtc::AnnotateException, "object proxy type " + self.proxy_type.to_s + " NOT <= rtc_annotate argument type " + annotated_type.to_s        
      end

      r = Rtc::ProxyObject.new(@object, annotated_type)        
    else
      if not self.rtc_type <= annotated_type 
        raise Rtc::AnnotateException, "object type " + self.rtc_type.to_s + " NOT <= rtc_annotate argument type " + annotated_type.to_s        
      end

      r = Rtc::ProxyObject.new(self, annotated_type)        
    end


    if self.proxies == nil
      self.proxies = Set.new([r])
    else
      self.proxies.add(r)
    end

    Rtc::MasterSwitch.turn_on if status == true
    r
  end
end


# Mixin for annotated classes. The module defines class methods for declaring
# type annotations and querying a class for the types of various methods.
#
# Note that this should be +extend+ed, not +include+ded.
module Rtc::Annotated

    # Adds a type signature for a method to the class's method type table.
    def typesig(string_signature, meta_info={})
        if meta_info.keys.include?('mutate')
          mutate = meta_info['mutate']
        else
          mutate = false
        end

        if meta_info.keys.include?('unwrap')
          unwrap = meta_info['unwrap']
        else
          unwrap = []
        end

        signatures = @annot_parser.scan_str(string_signature)
        return unless signatures

        signatures.each {|s| self.add_to_typesigs(s.id.to_s, s.type, mutate, unwrap)}

        if signatures.instance_of?(Rtc::ClassAnnotation)
           Rtc::ClassModifier.handle_class_annot(signatures)
           return
        end
        this_type = Rtc::Types::NominalType.of(self)

        meta_type = self.rtc_type

        (signatures.map {
          |sig|
          if sig.instance_of?(Rtc::InstanceVariableTypeSignature)
            field_name = sig.id.to_s[1..-1]
            field_type = sig.type
            this_type.add_field(field_name, field_type)
            getter_type = Rtc::Types::ProceduralType.new(field_type, [])
            setter_type = Rtc::Types::ProceduralType.new(field_type, [field_type])
            [Rtc::MethodTypeSignature.new(sig.pos,field_name,getter_type),
              Rtc::MethodTypeSignature.new(sig.pos,field_name+"=",setter_type)]
          elsif sig.instance_of?(Rtc::ClassVariableTypeSignature)
            field_name = sig.id.to_s[2..-1]
            field_type = sig.type
            meta_type.add_field(field_name, field_type)
            getter_type = Rtc::Types::ProceduralType.new(field_type, [])
            setter_type = Rtc::Types::ProceduralType.new(field_type, [field_type])
            [Rtc::ClassMethodTypeSignature.new(sig.pos, field_name, getter_type),
              Rtc::ClassMethodTypeSignature.new(sig.pos, field_name+"=", setter_type)]
          else
            sig
          end
        }).flatten.each do |signature|
          if signature.instance_of?(Rtc::ClassMethodTypeSignature)
            handle_class_typesig(signature)
          else
            handle_instance_typesig(signature)
          end
        end
    end
    
    def handle_instance_typesig(signature)
      if signature.id.to_s == "__rtc_next_method"
        @next_methods << signature.type
        return
      end
      this_type = Rtc::Types::NominalType.of(self)

      this_type.add_method(signature.id.to_s, signature.type)
      if self.instance_methods(false).include?(signature.id.to_sym)
        if not @method_wrappers.keys.include?(signature.id.to_s)
          @method_wrappers[signature.id.to_s] = Rtc::MethodWrapper.make_wrapper(self, signature.id.to_s)
        end
      else
        @deferred_methods << signature.id.to_s
      end
    end
    
    def handle_class_typesig(signature)
      meta_type = self.rtc_type
      meta_type.add_method(signature.id.to_s, signature.type)
      if self.methods(false).include?(signature.id.to_sym)
        @class_method_wrappers[signature.id.to_s] = Rtc::MethodWrapper.make_wrapper(class << self; self; end, signature.id.to_s)
      else
        @deferred_class_methods << signature.id.to_s
      end
    end
    
    #FIXME(jtoman): needs a better and catchier name
    def no_subtype
      self.rtc_meta[:no_subtype] = true
    end
    
    def define_iterator(param_name,iterator_name)
      rtc_meta.fetch(:iterators)[param_name] = iterator_name
    end
    
    def define_iterators(iter_hash)
      rtc_meta.fetch(:iterators).merge!(iter_hash)
    end
    
    def singleton_method_added(method_name)
      return if not defined? @annot_parser
      if method_name == :singleton_method_added
        return
      end
      if @deferred_class_methods.include?(method_name.to_s)
        @deferred_class_methods.delete(method_name.to_s)
        @class_method_wrappers[method_name.to_s] = Rtc::MethodWrapper.make_wrapper(class << self; self; end, method_name.to_s) 
      end
    end

    def method_added(method_name)
      return if not defined? @annot_parser
      if @deferred_methods.include?(method_name.to_s)
        @deferred_methods.delete(method_name.to_s)
        @method_wrappers[method_name.to_s] = Rtc::MethodWrapper.make_wrapper(self, method_name.to_s)
      end
      if @next_methods.size != 0
        this_type = Rtc::Types::NominalType.of(self)
        @next_methods.each {
          |m_sig|
          this_type.add_method(method_name.to_s, m_sig)
        }
        @next_methods = []
        if not @method_wrappers[method_name.to_s]
          @method_wrappers[method_name.to_s] = Rtc::MethodWrapper.make_wrapper(self, method_name.to_s)
        end
      end
    end
    
    def self.extended(extendee)
      if Rtc::ClassModifier.deferred?(extendee)
        Rtc::ClassModifier.modify_class(extendee)
      end

      #FIXME: there must be a better way to do this
      [[:@annot_parser, Rtc::TypeAnnotationParser.new(extendee)],
       [:@method_wrappers,{}],
       [:@deferred_methods, Set.new],
       [:@next_methods, []],
       [:@class_method_wrappers, {}],
       [:@deferred_class_methods, Set.new]
      ].each {
        |i_var, value|
        extendee.instance_variable_set(i_var, value)
      }
    end
end


