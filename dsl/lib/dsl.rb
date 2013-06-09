module Dsl
  class Spec
    def initialize(cls, mname)
      @class = cls
      @mname = mname

      unless cls.method_defined? mname
        raise "Method #{mname} not defined for #{cls}"
      end
    end

    def include_spec(blk, *args)
      instance_exec(*args, &blk)
    end

    # Takes a block that transforms the incoming arguments
    # into (possibly) new arguments to be fed to the method.
    def pre(&b)
      mname = @mname
      old_mname = "__dsl_old_#{mname}_#{gensym}"

      @class.class_eval do
        alias_method old_mname, mname

        define_method mname do |*args, &blk|
          *new_args, new_blk = instance_exec(*args, blk, &b)
          send old_mname, *new_args, &new_blk
        end
      end
    end

    # Takes a block that transforms the return value
    # into a (possibly) return value to be returned from the method.
    # The block also gets handed the original arguments.
    def post(&b)
      mname = @mname
      old_mname = "__dsl_old_#{mname}_#{gensym}"

      @class.class_eval do
        alias_method old_mname, mname

        define_method mname do |*args, &blk|
          res = send old_mname, *args, &blk
          instance_exec(res, *args, blk, &b)
        end
      end
    end

    # pre/post_task are versions of pre/post that ignore the
    # return value from the block and just pass along the
    # original arguments or return value.

    def pre_task(&b)
      pre do |*args|
        instance_exec(*args, &b)
        args
      end
    end

    def post_task(&b)
      post do |r, *args|
        instance_exec(r, *args, &b)
        r
      end
    end

    class PreConditionFailure < Exception; end
    class PostConditionFailure < Exception; end

    # pre/post_cond are like pre/post_task, except they check
    # the block return and error if the block returns false/nil.

    def pre_cond(desc = "", &b)
      pre_task do |*args|
        raise PreConditionFailure, desc unless instance_exec(*args, &b)
      end
    end

    def post_cond(desc = "", &b)
      post_task do |r, *args|
        raise PostConditionFailure, desc unless instance_exec(r, *args, &b)
      end
    end


    # Since we're describing an existing method, not creating a new DSL,
    # here we want the dsl keyword to just intercept the block and add
    # our checks. We'll overwrite this functionality inside the entry version.
    def dsl(&blk)
      pre do |*args, &b|
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

    private

    def gensym
      if @gensym
        gsym = @gensym
      else
        gsym = 0
      end
      @gensym = gsym + 1
      gsym
    end
  end

  class Keyword < Spec
    def initialize(cls, mname)
      if cls.method_defined? mname
        raise "Method #{mname} already defined for #{cls}"
      end

      @class = cls
      @mname = mname

      action { nil }
    end

    # For non-DSL keywords
    def action(&blk)
      mname = @mname

      @class.class_eval do
        define_method mname, &blk
      end
    end

    # For keywords that take the same DSL they are in.
    def dsl_rec
      action do |*args, &blk|
        instance_exec(*args, &blk)
      end
    end

    # For keywords that take a different DSL than they are in.
    def dsl(cls = nil, *a, &b)
      mname = @mname

      raise "Need a class or block" unless cls or b

      unless b.nil?
        cls = Class.new(Object) if cls.nil?
        Lang.new(cls).instance_exec(*a, &b)
      end

      action do |*args, &blk|
        cls.new(*a).instance_exec(*args, &blk)
      end
    end
  end

  class Lang
    def initialize(cls)
      @class = cls
    end

    def keyword(mname, *args, &blk)
      Keyword.new(@class, mname).instance_exec(*args, &blk)
    end

    def spec(mname, *args, &blk)
      Spec.new(@class, mname).instance_exec(*args, &blk)
    end
  end

  def entry(mname,*args, &blk)
    Lang.new(self).keyword(mname, &blk)
  end

  def spec(mname, *args, &blk)
    Lang.new(self).spec(mname, &blk)
  end

  def create_spec(&b)
    Proc.new &b
  end
end
