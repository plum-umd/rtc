require 'rtc'

Rtc::MasterSwitch.turn_off
require 'rtc/typing/base_types2.rb'
Rtc::MasterSwitch.turn_on

NONCORE_ANNOTATED_CLASSES = Set.new ["csv"]
alias :old_require :require
def require(name)
  old_require name
  if NONCORE_ANNOTATED_CLASSES.member?(name)
    load(File.expand_path File.dirname(__FILE__) + \
      "/rtc/typing/noncore_base_types/base_" + name + ".rb") 
  end
end
