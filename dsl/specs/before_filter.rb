module AbstractController
  module Callbacks
    module ClassMethods
      extend Dsl

      spec :before_filter do |s|
        pre_task do
          $before_filter_methods = [] if not $before_filter_methods

          names = get_arg(:names)
          s = get_self
          $before_filter_methods.push([names, s])
        end
      end
    end
  end
end


module ActionDispatch
  module Routing
    class RouteSet
      class Dispatcher
        extend Dsl

        spec :controller_reference do
          post_cond do
            controller_name = get_ret
            methods = []

            $before_filter_methods.each {|e|
              methods.push(e) if e[1] == controller_name
            }

            if methods.size > 0
              all_methods_exist = methods.all? { |m|
                m = m[0]
                arg0 = m[0]
                arg0_found = has_instance_method?(controller_name, arg0)
                arg1_found = true
                
                if m.size > 1
                  arg1 = m[1]
                  if arg1.keys.include?(:only)
                    arg1[:only].each {|n|
                      arg1_found = false if not has_instance_method?(controller_name, n)
                    }
                  end
                end
                
                arg0_found and arg1_found
              }
            else 
              true
            end
          end

        end
      end
    end
  end
end
