# Common handling of class annotations

require 'rtc/typing/types'

module Rtc 
  class ClassModifier
    attr_reader :cache 

    @@cache = {}
    @@class_parameters = {}

    def self.handle_class_annot(annot_obj)
      begin
        the_obj = eval(annot_obj.qualified_name)
        Rtc::Types::NominalType.of(the_obj).type_parameters = annot_obj.parameters

        n = Rtc::Types::NominalType.of(the_obj)
        t = Rtc::Types::ParameterizedType.new(n, annot_obj.parameters)
        @@class_parameters[the_obj] = t

        the_obj
      rescue => e
        @@cache[annot_obj.qualified_name] = annot_obj.parameters
        nil
      end
    end

    def self.get_class_parameters
      @@class_parameters
    end

    def self.modify_class(class_obj)
      if @@cache[class_obj.name]
        Rtc::Types::NominalType.of(class_obj).type_parameters = @@cache[class_obj.name]
        @@cache.delete(class_obj.name)
      end
    end
    
    def self.deferred?(class_obj)
      @@cache.include?(class_obj.name)
    end
  end
end
