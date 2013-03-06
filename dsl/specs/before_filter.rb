module BFHelper
  def self.has_instance_method?(obj, method)
    m = method.to_sym
    obj.public_instance_methods.include?(m) or
      obj.private_instance_methods.include?(m) or
      obj.protected_instance_methods.include?(m)
  end
end

module AbstractController::Callbacks::ClassMethods
  extend Dsl
  
  spec :before_filter do
    pre_task do |*filters|
      Dsl.state[:before_filter_methods] = [] if not Dsl.state[:before_filter_methods]
      
      Dsl.state[:before_filter_methods].push([filters, self])
    end
  end
end

class ActionDispatch::Routing::RouteSet::Dispatcher
  extend Dsl
  
  spec :controller_reference do
    post_cond do |controller|
      methods = []
      
      bfm = Dsl.state[:before_filter_methods]
      bfm and bfm.each {|e| methods.push(e) if e[1] == controller }
      
      methods.all? { |e|
        options = e[0]
        m = options[0]
        method_found = BFHelper.has_instance_method?(controller, m)
        if options.size > 1
          only_methods = options[1][:only]
          method_found and only_methods.all? {|n|
            BFHelper.has_instance_method?(controller, n)
          }
        else method_found
        end
      }
    end
    
  end
end
