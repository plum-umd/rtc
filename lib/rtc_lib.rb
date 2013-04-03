require 'rtc'

Rtc::MasterSwitch.turn_off
require 'rtc/typing/base_types2.rb'
Rtc::MasterSwitch.turn_on

# constant set of all noncore classes currently annotated
NONCORE_ANNOTATED_CLASSES = Set.new ["csv"]
NONCORE_ANNOTATIONS_BASE_PATH = File.expand_path File.dirname(__FILE__) + \
      "/rtc/typing/noncore_base_types/base_"

loaded_classes = Set.new(ObjectSpace.each_object(Class)).collect! { 
  |c| 
  c.to_s.downcase 
} 

NONCORE_ANNOTATED_CLASSES.intersection(loaded_classes).each {
  |c|
  load(NONCORE_ANNOTATIONS_BASE_PATH + c + ".rb")
}

# intercept require and load class's type annotations, if they exist
alias :old_require :require
def require(name)
  old_require name

  if NONCORE_ANNOTATED_CLASSES.member?(name)
    load(NONCORE_ANNOTATIONS_BASE_PATH + name + ".rb")
  end
end
