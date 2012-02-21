# File to be included by client code.

require 'rtc/annotated'

def rtc_annotated
  extend Rtc::Annotated
end

#FIXME(jtoman): needs a catchier and better name
def rtc_no_subtype
  self.rtc_meta[:no_subtype] = true
end