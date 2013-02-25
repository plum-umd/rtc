module Dsl
  @@method_prefix = "__rtc_old__"

  class Conditions
    attr_reader :pre_conds, :pre_tasks, :post_conds, :post_tasks

    def initialize
      @pre_conds = []
      @pre_tasks = []
      @post_conds = []
      @post_tasks = []
    end

    def post_task(&block)
      @post_tasks.push(block)
    end

    def post_cond(&block)
      @post_conds.push(block)
    end
    
    def pre_task(&block)
      @pre_tasks.push(block)
    end

    def pre_cond(&block)
      @pre_conds.push(block)
    end  
  end

  def self.include2?(h, ks)
    h and h.keys.include?(ks[0]) and h[ks[0]].include?(ks[1])
  end

  def self.special_include?(obj, name)
    (obj.class == Array and obj.include?(name)) or (obj.class == Symbol and obj == name)
  end

  def self.has_instance_method?(obj, method)
    m = method.to_sym
    obj.public_instance_methods.include?(m) or
      obj.private_instance_methods.include?(m) or
      obj.protected_instance_methods.include?(m)
  end

  def spec(method, &block)
    old_method = @@method_prefix + method.to_s
    old_method = old_method.to_sym

    conds = Conditions.new
    conds.instance_eval(&block)

    class_eval do
      alias_method old_method, method

      define_method(method) do |*args, &blk|
        conds.pre_tasks.each { |b|
          self.instance_exec(*args, &b)
        }
        conds.pre_conds.each { |b|
          raise Exception, "pre condition not met" unless self.instance_exec(*args, &b)
        }
        r = send old_method, *args, &blk
        conds.post_tasks.each { |b|
          self.instance_exec(r, *args, &b)
        }
        conds.post_conds.each { |b|
          raise Exception, "post condition not met" unless self.instance_exec(r, *args, &b)
        }
        r
      end
    end
  end

end

