# Module that annotated classes must extend.
#
# Author:: Ryan W Sims (rwsims@umd.edu)

require 'rtc/annot_parser.tab'

# Mixin for annotated classes. The module defines class methods for declaring
# type annotations and querying a class for the types of various methods.
#
# Note that this should be +extend+ed, not +include+ded.
module Rtc::Annotated
    @@method_types = {}
    @@annot_parser = Rtc::TypeAnnotationParser.new("main")

    # Adds a type signature for a method to the class's method type table.
    def typesig(string_signature)
        signatures = @@annot_parser.scan_str(string_signature)
        return unless signatures

        signatures.each do |signature|
            @@method_types[signature.id.to_s] = signature.type
        end
    end

    # Returns a map from method names to types.
    def method_types
        @@method_types
    end

    # Returns the type of a method name.
    def type_of(method)
        @@method_types[method]
    end
end
