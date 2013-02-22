$method_prefix = "__rtc_old__"
$post_task_stack = []
$post_cond_stack = []
$method_info = []
$ret = nil

class MethodInfo
  attr_accessor :name
  attr_accessor :args
  attr_accessor :caller_obj

  def initialize(name, args, caller_obj)
    @name = name
    @args = args
    @caller_obj = caller_obj
  end
end

def include2?(h, ks)
  return false if not h
  h.keys.include?(ks[0]) and h[ks[0]].include?(ks[1])
end

def special_include?(obj, name)
  (obj.class == Array and obj.include?(name)) or (obj.class == Symbol and obj == name)
end

module Dsl
  def get_ret
    $ret
  end

  def has_instance_method?(obj, method)
    m = method.to_sym
    return true if obj.public_instance_methods.include?(m)
    return true if obj.private_instance_methods.include?(m)
    return true if obj.protected_instance_methods.include?(m)
    false
  end

  def get_arg(name)
    current_method = $method_info[-1]
    old_method_name = "#{$method_prefix}#{current_method.name}"
    arg_names_org = instance_method(old_method_name.to_sym).parameters
    arg_names = []
    arg_names_org.each {|e| arg_names.push(e) if e[0] != :block}
    passed_args = current_method.args
    arg_found = arg_names.any? {|e| e[1] == name}
    
    if not arg_found
      vn = arg_names.map {|e| e[1]}
      raise Exception, "Dsl#get_arg #{name} is not a valid argument name.  Valid argument names for method #{old_method_name} are #{vn.inspect}"
    end
    
    i = 0
    arg_names.each {|a|
      break if a[0] == :rest
      return passed_args[i] if a[1] == name
      i = i + 1
    }
    
    arg_names = arg_names[i..-1].reverse
    passed_args = passed_args[i..-1].reverse
    
    i = 0
    arg_names.each {|a|
      break if a[0] == :rest
      return passed_args[i] if a[1] == name
      i = i + 1
    }
    
    passed_args[i..-1].reverse
  end
  
  def get_self
    $method_info[-1].caller_obj
  end

  def spec(method, margs=nil, &block)
    old_method = "__rtc_old__" + method.to_s
    old_method = old_method.to_sym

    class_eval do
      class_eval ("alias #{old_method.inspect} #{method.inspect}")

      define_method(method) do |*args|
        $method_info.push(MethodInfo.new(method, args, self))
        $post_task_stack.push([])
        $post_cond_stack.push([])

        begin
          yield
          r = send old_method, *args
          $ret = r
          $post_task_stack[-1].each {|p| p.call}
          
          $post_cond_stack[-1].each {|p|
            if not p.call
              raise Exception, "post condition not met"
            end
          }

          r
        ensure
          $method_info.pop
          $post_task_stack.pop
          $post_cond_stack.pop
        end
      end
    end
  end

  def post_task(&block)
    $post_task_stack[-1].push(block)
  end

  def post_cond(&block)
    $post_cond_stack[-1].push(block)
  end
  
  def pre_task(a=nil,&block)
    yield
  end

  def pre_cond(a=nil,&block)
    r = yield

    if not r
      raise Exception, "pre condition not met"
    end
  end
end

