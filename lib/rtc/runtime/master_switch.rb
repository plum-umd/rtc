module Rtc
    # Master switch works as a flag for patching code to avoid patching its own
    # code. When entering a patching code, this switch should be turned off.
    # When exiting, this switch should be turned back on. Notice that when this
    # patching code invokes the original method(s), this switch should be turned
    # back on. For example,
    #
    #   x.foo
    #     1) goes to x.method_missing
    #     2) some patching code
    #     3) calls the actual method 'foo'
    #     4) ... (this foo may call other methods)
    #     5) comes back to the patching code
    #
    # at step 4, we must be able to capture other calls, and thus, this switch
    # must be turned on.
    class MasterSwitch
        @@master_switch = true
        def self.is_on?(); return @@master_switch end
        def self.turn_on(); @@master_switch = true end
        def self.turn_off(); @@master_switch = false end
        def self.set_to(state); @@master_switch = state end
        def self.off_if_on(); 
          return false if not @@master_switch
          @@master_switch = false
          true
        end
    end

    def self.turn_switch_on(); MasterSwitch.turn_on() end
    def self.turn_switch_off(); MasterSwitch.turn_off() end
    def self.is_switch_on?(); MasterSwitch.is_on?() end
    def self.set_switch_to(state); MasterSwitch.set_to(state) end
end
