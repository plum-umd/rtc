module Dsl
  class PreConditionFailure < Exception; end
  class PostConditionFailure < Exception; end

  @state = {}

  def self.state
    @state
  end

  class Conditions
    attr_reader :pre_conds, :pre_tasks, :post_conds, :post_tasks, :included_specs, :action

    def initialize
      @pre_conds = []
      @pre_tasks = []
      @post_conds = []
      @post_tasks = []
      @action = nil
      @included_specs = []
      @dsl = []
    end

    def include_spec(s, *args)
      self.instance_exec(*args, &s)
    end

    def post_task(&block)
      @post_tasks.push(block)
    end

    def post_cond(desc = "", &block)
      @post_conds.push([desc, block])
    end
    
    def pre_task(&block)
      @pre_tasks.push(block)
    end

    def pre_cond(desc = "", &block)
      @pre_conds.push([desc, block])
    end

    def action(&block)
      raise RuntimeException, "Action already defined for spec" if @action
      @action = block
    end

    def dsl(&block)
      if block_given?
        @dsl.push(block)
      else
        @dsl
      end
    end
  end

  def self.create_spec(&blk)
    Proc.new &blk
  end

  def spec(method, &block)
    unless method_defined? method or private_instance_methods.include? method
      raise NoMethodError, "method #{method} not defined on #{name}"
    end

    if instance_variable_get(:@dsl_gensym)
    then gensym = instance_variable_get(:@dsl_gensym) + 1
    else gensym = 0
    end
    instance_variable_set(:@dsl_gensym, gensym)

    old_method = "__rtc_old_#{method}#{gensym}"

    conds = Conditions.new
    conds.instance_eval(&block)

    class_eval do
      alias_method old_method, method if conds.actions.empty?

      define_method(method) do |*args, &blk|
        conds.pre_tasks.each { |b|
          self.instance_exec(*args, &b)
        }
        conds.pre_conds.each { |desc, b|
          raise PreConditionFailure, desc unless self.instance_exec(*args, &b)
        }
        if blk and conds.dsl
          new_blk = Proc.new do |*args|
            ec = singleton_class
            ec.extend Dsl
            conds.dsl.each { |b| ec.class_exec(*args, &b) }
            self.instance_exec(*args, &blk)
          end
          if conds.actions.empty?
            r = send old_method, *args, &new_blk
          else
            r = conds.action.call(*args, &new_blk)
          end
        elsif conds.actions.empty?
          r = send old_method, *args, &blk
        else
          r = conds.action.call(*args, &blk)
        end
        conds.post_tasks.each { |b|
          self.instance_exec(r, *args, &b)
        }
        conds.post_conds.each { |desc, b|
          raise PostConditionFailure, desc unless self.instance_exec(r, *args, &b)
        }
        r
      end
    end
  end

end

