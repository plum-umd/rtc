# Module that annotated classes must extend.
#
# Author:: Ryan W Sims (rwsims@umd.edu)

require 'rtc/annot_parser.tab'
require 'rtc/runtime/method_wrapper.rb'
require 'rtc/runtime/class_modifier.rb'
require 'set'
class Object
  def rtc_annotate(annotation_string)
    parser = Rtc::TypeAnnotationParser.new(self.class)
    annotated_type = parser.scan_str("##"+annotation_string)
    raise Rtc::TypeMismatchException, "Invalid type annotation: annotation was for #{annotated_type.nominal.klass}" +
      " but self is #{self.class.name}" unless self.class == annotated_type.nominal.klass
    my_type = self.rtc_type
    annotated_type.parameters.each_with_index {
      |type_param,index|
      my_type.parameters[index].constrain_to(type_param.pointed_type)
    }
    self
  end
end

# Mixin for annotated classes. The module defines class methods for declaring
# type annotations and querying a class for the types of various methods.
#
# Note that this should be +extend+ed, not +include+ded.
module Rtc::Annotated
    # Adds a type signature for a method to the class's method type table.
    def typesig(string_signature)
        signatures = @annot_parser.scan_str(string_signature)
        return unless signatures
        
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
        @method_wrappers[signature.id.to_s] = Rtc::MethodWrapper.make_wrapper(self, signature.id.to_s)
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
