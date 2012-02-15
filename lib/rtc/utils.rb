
module Rtc


  module HelperMethods

    private
    def self.demetaize_name(mod)
      if mod.to_s =~ /(.*)Class:((\w|::)+)>+$/
        return "<< #{$~[2]}"
      else
        return nil
      end
    end

    public
    def self.mod_name(mod)
      if mod.respond_to?(:name)
        if mod.name == ""
          # mod is a meta class
          demetaize_name(mod)
        else mod.name
        end
      else
        return nil
      end
    end
  end

end
