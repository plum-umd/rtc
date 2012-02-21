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
        
        signatures.each do |signature|
          this_type.add_method(signature.id.to_s, signature.type)
          if self.method_defined?(signature.id.to_s)
            @@method_wrappers = Rtc::MethodWrapper.make_wrapper(self, signature.id.to_s)
          else
            @@deferred_methods << signature.id.to_s
          end
        end
    end
    
    def method_added(method_name)
      if @@deferred_methods.include?(method_name.to_s)
        @@deferred_methods.delete(method_name.to_s)
        @@method_wrappers = Rtc::MethodWrapper.make_wrapper(self, method_name.to_s)
      end
    end
end
