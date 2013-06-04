module Dsl
  class MethodProxy
    def self.gensym
      if @gensym
        gsym = @gensym
      else
        gsym = 0
      end

      @gensym = gsym + 1
    end

    def self.pre_block(kls, mname, &blk)
      old_mname = "__rtc_old_#{mname}#{gensym}"

      kls.class_eval do
        alias_method old_mname, mname

        define_method mname do |*args, &b|
          *new_args, new_b = instance_exec(*args, b, &blk)
          send old_mname, *new_args, &new_b
        end
      end
    end

    def self.post_block(kls, mname, &blk)
      old_mname = "__rtc_old_#{mname}#{gensym}"

      kls.class_eval do
        alias_method old_mname, mname

        define_method mname do |*args, &b|
          r = send old_mname, *args, &b
          instance_exec(r, *args, b, &blk)
        end
      end
    end
  end

  class DslSpec
    def initialize(kls, mname)
      @class = kls
      @mname = mname
    end

    def action(&blk)
      mname = @mname
      @class.class_eval do
        define_method mname, &blk
      end
    end
  end

  @state = {}

  def self.state
    @state
  end

  def self.create_spec(&blk)
    Proc.new &blk
  end

  def spec(method, &block)
    obj = DslSpec.new(self, method)
    obj.instance_eval(&block)
  end
end

class Dsl::DslSpec
  class PreConditionFailure < Exception; end
  class PostConditionFailure < Exception; end

  def pre_cond (desc = "", &blk)
    Dsl::MethodProxy.pre_block(@class, @mname) do |*args|
      raise PreConditionFailure, desc unless instance_exec(*args, &blk)
      args
    end
  end

  def post_cond (desc = "", &blk)
    Dsl::MethodProxy.post_block(@class, @mname) do |*args|
      raise PostConditionFailure, desc unless instance_exec(*args, &blk)
      args
    end
  end

  def pre_task (&blk)
    Dsl::MethodProxy.pre_block(@class, @mname) do |*args|
      instance_exec(*args, &blk)
      args
    end
  end

  def post_task (&blk)
    Dsl::MethodProxy.post_block(@class, @mname) do |*args|
      instance_exec(*args, &blk)
      args
    end
  end

  def dsl (&blk)
    Dsl::MethodProxy.pre_block(@class, @mname) do |*args, b|
      if b
        new_b = Proc.new do |*args|
          ec = singleton_class
          ec.extend Dsl
          ec.class_eval &blk
          instance_exec(*args, &b)
        end
        args + [new_b]
      else args
      end
    end
  end

  def include_spec (blk, *args)
    instance_exec(*args, &blk)
  end

end
