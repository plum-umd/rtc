# Module that annotated classes must extend.
#
# Author:: Ryan W Sims (rwsims@umd.edu)

require 'rtc/annot_parser.tab'
require 'rtc/runtime/method_wrapper.rb'
require 'set'
# Mixin for annotated classes. The module defines class methods for declaring
# type annotations and querying a class for the types of various methods.
#
# Note that this should be +extend+ed, not +include+ded.
module Rtc::Annotated
    @@annot_parser = Rtc::TypeAnnotationParser.new("main")
    @@method_wrappers = {}
    
    @@deferred_methods = Set.new
    
    # Adds a type signature for a method to the class's method type table.
    def typesig(string_signature)
        signatures = @@annot_parser.scan_str(string_signature)
        return unless signatures
        
        this_type = Rtc::Types::NominalType.of(self)
        
        (signatures.map {
          |sig|
          if sig.instance_of?(Rtc::InstanceVariableTypeSignature)
            field_name = sig.id.to_s[1..-1]
            field_type = sig.type
            getter_type = Rtc::Types::ProceduralType.new(field_type, [])
            setter_type = Rtc::Types::ProceduralType.new(field_type, [field_type])
            [Rtc::MethodTypeSignature.new(sig.pos,field_name,getter_type),
              Rtc::MethodTypeSignature.new(sig.pos,field_name+"=",setter_type)]
          else
            sig
          end
        }).flatten.each do |signature|
          this_type.add_method(signature.id.to_s, signature.type)
          if self.method_defined?(signature.id.to_s)
            @@method_wrappers = Rtc::MethodWrapper.make_wrapper(self, signature.id.to_s)
          else
            @@deferred_methods << signature.id.to_s
          end
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
      rtc_meta.fetch(:iterators).merge(iter_hash)
    end
    
    def method_added(method_name)
      if @@deferred_methods.include?(method_name.to_s)
        @@deferred_methods.delete(method_name.to_s)
        @@method_wrappers = Rtc::MethodWrapper.make_wrapper(self, method_name.to_s)
      end
    end
end
