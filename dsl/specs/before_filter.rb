module AbstractController::Callbacks::ClassMethods
  extend Dsl
  
  spec :before_filter do
    pre_task do |*filters|
      $before_filter_methods = [] if not $before_filter_methods
      
      $before_filter_methods.push([filters, self])
    end
  end
end

class ActionDispatch::Routing::RouteSet::Dispatcher
  extend Dsl
  
  spec :controller_reference do
    post_cond do |controller|
      methods = []
      
      $before_filter_methods and $before_filter_methods.each {|e|
        methods.push(e) if e[1] == controller
      }
      
      methods.all? { |e|
        options = e[0]
        m = options[0]
        method_found = Dsl.has_instance_method?(controller, m)
        if options.size > 1
          only_methods = options[1][:only]
          method_found and only_methods.all? {|n| Dsl.has_instance_method?(controller, n) }
        else method_found
        end
      }
    end
    
  end
end
