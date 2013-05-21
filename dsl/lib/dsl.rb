class MethodProxy
  def initialize
    @pres = []
    @posts = []
    @action = nil
  end

  def action(&blk)
    @action = blk
  end

  def register_pre(&blk)
    @pres.push(blk)
  end

  def register_post(&blk)
    @posts.unshift(blk)
  end

  def apply(cls, mname, gensym = 0)
    old_mname = "__rtc_old_#{mname}#{gensym}"
    action = @action
    pres = @pres
    posts = @posts

    cls.class_eval do
      alias_method old_mname, mname unless action

      define_method(mname) do |*args, &blk|
        new_args = pres.reduce(args + [blk]) do |args, b|
          instance_exec(*args, &b)
        end
        *new_args, blk = new_args if blk
        if conds.action
          r = conds.action.call(*new_args, &blk)
        else
          r = send old_method, *new_args, &blk
        end
        new_r, _ = posts.reduce([r] + new_args + [blk]) do |args, b|
          instance_exec(*args, &b)
        end
      end
    end
  end
end

module Dsl
  @state = {}

  def self.state
    @state
  end

  def self.create_spec(&blk)
    Proc.new &blk
  end

  def spec(method, &block)
    if instance_variable_get(:@dsl_gensym)
    then gensym = instance_variable_get(:@dsl_gensym) + 1
    else gensym = 0
    end
    instance_variable_set(:@dsl_gensym, gensym)

    proxy = MethodProxy.new
    proxy.instance_eval(&block)
    proxy.apply(self, method, gensym)
  end
end

class MethodProxy
  extend Dsl

  class PreConditionFailure < Exception; end
  class PostConditionFailure < Exception; end

  spec :pre_cond do
    action do |desc = "", block|
      register_pre do |*args|
        raise PreConditionFailure, desc unless instance_exec(*args, &block)
        args
      end
    end
  end

  spec :post_cond do
    action do |desc = "", block|
      register_post do |*args|
        raise PostConditionFailure, desc unless instance_exec(*args, &block)
        args
      end
    end
  end

  spec :pre_task do
    action do |block|
      register_pre do |*args|
        instance_exec(*args, &block)
        args
      end
    end
  end

  spec :post_task do
    action do |block|
      register_post do |*args|
        instance_exec(*args, &block)
        args
      end
    end
  end
      
  spec :dsl do
    action do |b|
      register_pre do |*a, blk|
        new_blk = Proc.new do |*args|
          ec = singleton_class
          ec.extend Dsl
          ec.class_exec(*args, &b)
          self.instance_exec(*args, &blk)
        end
        a + [new_blk]
      end
    end
  end

  spec :include_spec do
    action do |blk, *args|
      instance_exec(*args, blk)
    end
  end

end
