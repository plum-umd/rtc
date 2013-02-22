module ActionController
  module Rendering
    extend Dsl

    spec :process_action do
      pre_cond do
        s = get_self
        a = false

        if include2?($rtf_pff_meta, [s.class, :except]) 
          if special_include?($rtc_pff_meta[s.class][:except], s.action_name.to_sym)
            a = true
          end
        end

        $rtc_pff_called or ((not $rtc_pff_called) and a)
      end
    end
  end

  module RequestForgeryProtection
    extend Dsl 

    module ClassMethods
      extend Dsl

      spec :protect_from_forgery do |options|
        pre_task do
          $rtc_pff_meta = {} if not $rtc_pff_meta
          h = {}
          options = get_arg(:options)
          h[get_self] = get_arg(:options)
          $rtc_pff_meta.merge!(h)
        end

        post_task do

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

