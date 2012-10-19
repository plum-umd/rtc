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

  def rtc_to_str
    self.to_s
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
    return self if self === false || self === nil ||
      self.is_a?(Rtc::Types::Type)
    status = Rtc::MasterSwitch.is_on?
    Rtc::MasterSwitch.turn_off if status == true

    if annotation_string.class == String
      parser = Rtc::TypeAnnotationParser.new(self.class)
      annotated_type = parser.scan_str("##"+annotation_string)
    else
      annotated_type = annotation_string
    end

    if self.is_proxy_object?
      unless Rtc::MethodCheck.check_type(self.object, annotated_type)
        raise Rtc::AnnotateException, "object run-time type " + self.object.rtc_type.to_s + " NOT <= rtc_annotate argument type " + annotated_type.to_s        
      end
      if annotated_type.is_tuple
        r = Rtc::TupleProxy.new(@object, annotated_type)
      else
        r = Rtc::ProxyObject.new(@object, annotated_type)
      end
    else
      unless Rtc::MethodCheck.check_type(self, annotated_type)
        raise Rtc::AnnotateException, "object type " + self.rtc_type.to_s + " NOT <= rtc_annotate argument type " + annotated_type.to_s        
      end
      if annotated_type.is_tuple
        r = Rtc::TupleProxy.new(self, annotated_type)
      else
        r = Rtc::ProxyObject.new(self, annotated_type)        
      end
    end
    Rtc::MasterSwitch.turn_on if status == true
    r
  end

  def rtc_annotate(annotation_string)
    return self if self === false || self === nil ||
      self.is_a?(Rtc::Types::Type)
    status = Rtc::MasterSwitch.is_on?
    Rtc::MasterSwitch.turn_off if status == true

    if annotation_string.class == String
      parser = Rtc::TypeAnnotationParser.new(self.class)
      annotated_type = parser.scan_str("##"+annotation_string)
    else
      if annotation_string.is_a?(Rtc::Types::TypeVariable)
        raise "fatal error, cannot annotate on type variables"
      end
      annotated_type = annotation_string
    end

    if self.is_proxy_object?
      if not self.proxy_type <= annotated_type
        raise Rtc::AnnotateException, "object proxy type " + self.proxy_type.to_s + " NOT <= rtc_annotate argument type " + annotated_type.to_s        
      end
      if annotated_type.is_tuple
        r = Rtc::ProxyObject.new(@object, annotated_type)
      else
        r = Rtc::ProxyObject.new(@object, annotated_type)        
      end
    else
      unless Rtc::MethodCheck.check_type(self, annotated_type)
        raise Rtc::AnnotateException, "object type " + self.rtc_type.to_s + " NOT <= rtc_annotate argument type " + annotated_type.to_s
      end
      if annotated_type.is_tuple
        r = Rtc::TupleProxy.new(self, annotated_type)
      else
        r = Rtc::ProxyObject.new(self, annotated_type)
      end
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
      status = Rtc::MasterSwitch.is_on?
      Rtc::MasterSwitch.turn_off
        if meta_info.has_key?('mutate')
          mutate = meta_info['mutate']
        else
          mutate = false
        end

        if meta_info.has_key?('unwrap')
          unwrap = meta_info['unwrap']
        elsif meta_info.has_key?(:unwrap)
          unwrap = meta_info[:unwrap]
        else
          unwrap = []
        end
 
        signatures = @annot_parser.scan_str(string_signature)
        return unless signatures

        signatures.each {
          |s|
          if s.instance_of?(Rtc::ClassMethodTypeSignature) or
            s.instance_of?(Rtc::MethodTypeSignature)
            s.type.mutate = mutate
            s.type.unwrap = unwrap
          end
        }

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
            getter_type = Rtc::Types::ProceduralType.new([], field_type, [])
            setter_type = Rtc::Types::ProceduralType.new([], field_type, [field_type])
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
        Rtc::MasterSwitch.set_to(status)
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
        @class_method_wrappers[method_name.to_s] = Rtc::MethodWrapper.make_wrapper(class << self; self; end, method_name.to_s, true) 
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
    
    def add_type_parameters(t_params)
      return if t_params.empty?
      t_parameters = []
      iterators = {}
      t_params.each {
        |pair|
        t_parameters << pair[0]
        iterators[pair[0]] = pair[1]
      }
      Rtc::Types::NominalType.of(self).type_parameters = t_parameters
      define_iterators(iterators)
    end

    def rtc_typed
      if defined? @class_proxy
        @class_proxy
      end
      @class_proxy = Rtc::ProxyObject.new(self, self.rtc_type);
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


