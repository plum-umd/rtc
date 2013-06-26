require 'dsl'

module Dsl::Infer
  class Nominal
    attr_reader :class

    def initialize(cls)
      @class = cls
    end

    def to_s
      @class.to_s
    end

    def superclass
      return nil if root?
      Nominal.new(@class.superclass)
    end

    def ==(cls1)
      @class == cls1.class
    end

    def root?
      @class == Object or @class == BasicObject
    end

    def <=(cls1)
      return true if root?
      return true if self == cls1
      return false if cls1.root?
      self <= cls1.superclass
    end

    def join(cls)
      return self if self <= cls
      return cls if cls <= self
      cls1 = self.superclass.join cls
      cls2 = self.join cls.superclass
      return cls1 if cls1 <= cls2
      return cls2 if cls2 <= cls1
    end
  end

  class Arr < Nominal
    attr_reader :base

    def initialize(base)
      case base
      when Nominal
        @base = base
      else
        @base = Nominal.new(base)
      end
    end

    def to_s
      "Array[#{base}]"
    end

    def ==(cls1)
      cls1.class == Arr and
        base == cls1.base
    end

    def superclass
      return Nominal.new(Array) if base.root?
      Arr.new(base.superclass)
    end

    def root?
      false
    end
  end

  class Tup < Arr
    attr_reader :elts

    def initialize(elts)
      case elts[0]
      when Nominal
        @elts = elts
      else
        @elts = elts.map { |c| Nominal.new(c) }
      end
    end

    def size
      @elts.length
    end

    def to_s
      "Tuple#{elts}"
    end

    def root?
      false
    end

    def ==(cls1)
      cls1.class == Tup and
        size = cls1.size and
        elts.zip(cls1.elts).all? { |p| p[0] == p[1] }
    end

    def superclass
      if elts.all? { |p| p.root? }
        first = elts[0]
        return Arr.new(elts.slice(1,-1).reduce(first) {|c1, c2| c1.join c2 })
      else
        Tuple(elts.map { |p| p.superclass })
      end
    end

  end

  class Engine
    def initialize(cls, mname)
      @class = cls
      @mname = mname

      @arg_names = cls.instance_method(mname).parameters
      @args = {}
      @returns = []
    end

    def add_args(*a, &b)
      names = @arg_names
      block_handled = false
      names.each { |i|
        case i[0]
        when :req
          args(i[1], a.shift)
        when :rest
          args(i[1], a)
          # This isn't quite right yet, since this only works if all the
          # opts are at the end, but Ruby allows for more mixed args
          # (required args can appear after optional args and
          # take precedence).
        when :opt
          args(i[1], a.shift) unless a.empty?
        else nil
        end
      }
    end

    def add_return(ret)
      @returns.push ret
    end

    def do_infer
      as = @args
      ret = @returns

      puts "  For method #{@mname} of class #{@class}:"
      as.each { |n, al| puts "    Argument #{n}: #{infer_single_list al}" }
      puts "    Return: #{infer_single_list ret}"
    end

    private

    def infer_single(val)
      case val.class
      when Array
        Tup.new(val.map{ |v| infer_single v })
      else
        Nominal.new(val.class)
      end
    end

    def infer_single_list(lst)
      return Nominal.new(Object) if lst.empty?

      first = lst.shift
      first_type = infer_single(first)
      return first_type if lst.empty?
      rest_type = infer_single_list lst

      first_type.join rest_type
    end

    def args(aname, aval)
      @args[aname] = [] unless @args[aname]

      @args[aname].push aval
    end
  end
end

class Dsl::Spec
  def infer
    engine = Dsl::Infer::Engine.new(@class, @mname)
    pre_task { |*args, &blk| engine.add_args *args, &blk }
    post_task { |r, *a| engine.add_return r }
    at_exit { engine.do_infer }
  end
end
