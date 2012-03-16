# File to be included by client code.

module Rtc
  def self.setup
    yield self
  end
end

require 'rtc/annotated'
require 'rtc/options'
require 'rtc/runtime/class_modifier'

def rtc_annotated
  extend Rtc::Annotated
end

#FIXME(jtoman): needs a catchier and better name
def rtc_no_subtype
  self.rtc_meta[:no_subtype] = true
end

def rtc_typesig(my_sig)
  parser = Rtc::TypeAnnotationParser.new(self)
  class_annot = parser.scan_str(my_sig)
  raise "Invalid annotation, expected class annotation" unless class_annot.instance_of?(Rtc::ClassAnnotation)
  Rtc::ClassModifier.handle_class_annot(class_annot)
end

require 'rtc/typing/base_types.rb'
