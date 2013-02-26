module Dsl
  @@method_prefix = "__rtc_old__"

  class Conditions
    attr_reader :pre_conds, :pre_tasks, :post_conds, :post_tasks, :included_specs

    def initialize
      @pre_conds = []
      @pre_tasks = []
      @post_conds = []
      @post_tasks = []
      @included_specs = []
      @dsl = []
    end

    def include_spec(s, *args)
      self.instance_exec(*args, &s)
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

    def dsl(&block)
      if block_given?
        @dsl.push(block)
      else
        @dsl
      end
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

  def self.create_spec(&blk)
    Proc.new &blk
  end

  def spec(method, &block)
    unless method_defined? method or private_instance_methods.include? method
      raise Exception, "method #{method} not defined on #{name}"
    end

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
        if blk and conds.dsl
          new_blk = Proc.new do |*args|
            unless self.instance_variable_get(:@dsl_specs_run)
              ec = class << self; self; end
              unless self.is_a?(Dsl)
                ec.extend Dsl
              end
              conds.dsl.each { |b| ec.class_exec(*args, &b) }
              self.instance_variable_set(:@dsl_specs_run, true)
            end
            self.instance_exec(*args, &blk)
          end
          r = send old_method, *args, &new_blk
        else
          r = send old_method, *args, &blk
        end
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

