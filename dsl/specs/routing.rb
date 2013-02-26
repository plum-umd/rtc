class ActionDispatch::Routing::RouteSet
  extend Dsl

  logging_spec = Dsl.create_spec do |name|
    pre_task do
      p "Entering #{name} on #{self}"
    end
    
    post_task do
      p "Exiting #{name} on #{self}"
    end
  end
  
  get_post_spec = Dsl.create_spec do
    dsl do
      spec :get do
        include_spec logging_spec, "get"
      end
      spec :post do
        include_spec logging_spec, "post"
      end
    end
  end
  
  resources_spec = Dsl.create_spec do
    dsl do
      spec :resources do
        include_spec resources_spec
        include_spec get_post_spec
        include_spec logging_spec, "resources"
      end
      spec :collection do
        include_spec logging_spec, "collection"
        include_spec get_post_spec
      end
      spec :member do
        include_spec logging_spec, "member"
        include_spec get_post_spec
      end
    end
  end

  spec :draw do
    include_spec logging_spec, "draw"
    include_spec resources_spec
    dsl do
      spec :namespace do
        include_spec resources_spec
      end
    end
  end
end
