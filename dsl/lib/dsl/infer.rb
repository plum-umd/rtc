require 'dsl'

class Class
  def subclass?(cls)
    return true if cls == self
    return false unless self.superclass
    self.superclass.subclass? cls
  end

  def common_ancestor(cls)
    return Class unless self.superclass and cls.superclass
    return self if cls.subclass? self
    return cls if self.subclass? cls
    step_one_self = self.superclass.common_ancestor cls
    step_one_cls = self.common_ancestor cls.superclass
    return step_one_self if step_one_cls.subclass? step_one_self
    return step_one_cls
  end
end

module Dsl::Infer
  def self.name_args(cls, mname)
    @arg_names = {} unless @arg_names
    @arg_names[cls] = {} unless @arg_names[cls]
    @arg_names[cls][mname] = cls.instance_method(mname).parameters
  end

  def self.add_args(cls, mname, *a, &b)
    names = arg_names(cls, mname)
    p names
    block_handled = false
    names.each { |i|
      case i[0]
        when :req
          args(cls, mname, i[1], a.shift)
        when :rest
          args(cls, mname, i[1], a)
        # This isn't quite right yet, since this only works if all the
        # opts are at the end, but Ruby allows for more mixed args
        # (required args can appear after optional args and
        # take precedence).
        when :opt
          args(cls, mname, i[1], a.shift) unless a.empty?
        else nil
      end
    }
    p @args[cls][mname]
  end

  def self.add_return(cls, mname, ret)
    returns(cls, mname, ret)
    p @returns[cls][mname]
  end

  def self.do_infer
    @args.each_key do |c|
      puts "For class #{C}:"
      @args[c].each_key do |m|
        as = @args[c][m]
        ret = @returns[c][m]

        puts "  For method #{m}:"
        as.each { |n, al| puts "    Argument #{n}: #{infer_single_list al}" }
        puts "    Return: #{infer_single_list ret}"
      end
    end
  end

  private

  def self.infer_single_list(lst)
    return "none provided" if lst.empty?

    first = lst.shift
    first_type = first.class
    return first_type if lst.empty?
    rest_type = infer_single_list lst

    first_type.common_ancestor rest_type
  end

  def self.arg_names(cls, mname)
    @arg_names[cls][mname]
  end

  def self.returns(cls, mname, ret)
    @returns = {} unless @returns
    @returns[cls] = {} unless @returns[cls]
    @returns[cls][mname] = [] unless @returns[cls][mname]

    @returns[cls][mname].push(ret)
  end

  def self.args(cls, mname, aname, aval)
    @args = {} unless @args
    @args[cls] = {} unless @args[cls]
    @args[cls][mname] = {} unless @args[cls][mname]
    @args[cls][mname][aname] = [] unless @args[cls][mname][aname]

    @args[cls][mname][aname].push(aval)
  end
end

class Dsl::Spec
  def infer
    cls = @class
    mname = @mname
    Dsl::Infer.name_args(cls, mname)
    pre_task { |*args, &blk| Dsl::Infer.add_args(cls, mname, *args, &blk) }
    post_task { |r, *a| Dsl::Infer.add_return(cls, mname, r) }
  end
end

at_exit do
  Dsl::Infer.do_infer
end
