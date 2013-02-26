module RoutingHelper
  def self.get_class(name)
    Module.const_get name
  end

  def self.class_exists?(name)
    c = get_class name
    c.is_a? Class
  rescue NameError
    false
  end
end

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
        pre_cond do |*args|
          args.all? do |a|
            if a.is_a? String or a.is_a? Symbol
            then 
              cname = "#{a.capitalize}Controller"
              p "Checking for class #{cname}"
              RoutingHelper.class_exists? cname
            else true
            end
          end
        end
        include_spec resources_spec
        include_spec get_post_spec
        include_spec logging_spec, "resources"
        # post_cond do |ret, *args|
        #   args.all? do |a|
        #     if a.is_a? String or a.is_a? Symbol
        #     then 
        #       # how to get the Application?
        #       app.method_defined? "#{a.downcase}_path"
        #     else true
        #     end
        #   end
        # end
      end
      spec :resource do
        # pre_cond do |*args|
        #   args.all? do |a|
        #     if a.is_a? String or a.is_a? Symbol
        #     then 
        #       cname = "#{a.capitalize}sController"
        #       p "Checking for class #{cname}"
        #       RoutingHelper.class_exists? cname
        #     else true
        #     end
        #   end
        # end
        include_spec resources_spec
        include_spec logging_spec, "resource"
        include_spec get_post_spec
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
