# File to be included by client code.

module Rtc
  Disabled = ENV.fetch("RTC_DISABLE", false)
  
  def self.setup
    yield self
  end
end

require 'rtc/annotated'

def rtc_annotated
  extend Rtc::Annotated
end

#FIXME(jtoman): needs a catchier and better name
def rtc_no_subtype
  self.rtc_meta[:no_subtype] = true
end

def rtc_typesig(my_sig)
  parser = Rtc::TypeAnnotationParser.new(self)
  parser.scan_str(my_sig)
end

require 'rtc/typing/base_types.rb'
