
module Rtc
  class ClassNotFoundException < StandardError; end
  module ClassLoader
    def ClassLoader.load_class(ident, context)
      if ident[:type] == :absolute or context.instance_of?(Object)
        eval("::" + ident[:name_list].join("::"))
      else
        scopes = context.name.split("::")
        while scopes.size != 0
          curr_scope = eval(scopes.join("::"))
          obj = find_type_ident(ident[:name_list], curr_scope)
          return obj if obj != nil
          scopes.pop()
        end
        obj = find_type_ident(ident[:name_list], Object)
        raise ClassNotFoundException,"Could not find class #{ident_to_s(ident)} in context #{context.to_s}" unless obj != nil
        return obj
      end
    end
    
    def ClassLoader.ident_to_s(ident)
      if ident[:type] == :absolute
        "::" + ident[:name_list].join("::")
      else
        ident[:name_list].join("::")
      end
    end
    
    def ClassLoader.find_type_ident(name_list, scope)
      curr_scope = scope
      name_list.each {|id|
        if curr_scope.const_defined?(id)
          curr_scope = curr_scope.const_get(id)
        else
          return nil
        end 
      }
      return curr_scope
    end

  end
end
