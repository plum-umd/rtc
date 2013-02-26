module CSRFHelper
  def self.include2?(h, ks)
    h and h.keys.include?(ks[0]) and h[ks[0]].include?(ks[1])
  end

  def self.special_include?(obj, name)
    (obj.class == Array and obj.include?(name)) or (obj.class == Symbol and obj == name)
  end
end

module ActionController
  module Rendering
    extend Dsl

    spec :process_action do
      pre_cond do
        $rtc_pff_called or
          ((not $rtc_pff_called) and
           CSRFHelper.include2?($rtf_pff_meta, [self.class, :except]) and
           CSRFHelper.special_include?($rtc_pff_meta[self.class][:except], self.action_name.to_sym))
      end
#      Don't we need to reset it eventually?  Maybe something like:
#
#      post_task do
#        $rtc_pff_called = false
#      end
#
#      so that the next time process_action is called, we ensure another v_a_t call was made?
    end
  end

  module RequestForgeryProtection
    extend Dsl 

    module ClassMethods
      extend Dsl

      spec :protect_from_forgery do
        pre_task do |options|
          $rtc_pff_meta = {} if not $rtc_pff_meta
          $rtc_pff_meta[self] = options
        end
      end
    end
    
    spec :verify_authenticity_token do
      pre_task do
        $rtc_pff_called = true
      end
    end
  end
end

