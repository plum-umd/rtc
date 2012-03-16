# Common handling of class annotations

require 'rtc/typing/types'

module Rtc 
  class ClassModifier
    @@cache = {}
    def self.handle_class_annot(annot_obj)
      begin
        the_obj = eval(annot_obj.qualified_name)
        Rtc::Types::NominalType.of(the_obj).type_parameters = annot_obj.parameters
        the_obj
      rescue => e
        @@cache[annot_obj.qualified_name] = annot_obj.parameters
        nil
      end
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