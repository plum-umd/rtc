# http://hsume2.github.com/rose/

require 'rose'
require 'set'

module Rose
  class Shell
    extend Dsl

    spec :photosynthesize do
      pre_cond "ID or column name not valid" do |*args|
        lst = args[0]
        h = args[1]

        if h.keys.include?(:with)
          h[:with].all? {|k, v|
            c = v.to_a[0][0]
            name = Dsl.state[:__rtc_rose_name]
            Dsl.state[:__rtc_rose_meta][name][:cols].include?(c)
            k.to_i < lst.size and Dsl.state[:__rtc_rose_meta][name][:cols].include?(c)
          }
        else
          true
        end
      end
    end

  end
end

class << Rose
  extend Dsl 

  check_col_spec = Dsl.create_spec do |method_name|
    pre_cond "Column name must have been defined in Rose.make" do |col|
      name = Dsl.state[:__rtc_rose_name]
      cols = Dsl.state[:__rtc_rose_meta][name][:cols]
      cols.include?(col)       
    end
  end

  spec :make do 
    pre_task do |name, options|
      Dsl.state[:__rtc_rose_name] = name
      Dsl.state[:__rtc_rose_meta] ||= {}
      Dsl.state[:__rtc_rose_meta][name] ||= {}

      if options.class == Hash and options.keys.include?(:class)
        Dsl.state[:__rtc_rose_meta][name][:class] = options[:class]
        Dsl.state[:__rtc_rose_class] = options[:class]
      else
        Dsl.state[:__rtc_rose_class] = nil
      end
    end

    pre_cond "argument class must be < Struct" do |*args, options|
      if options.class == Hash and options.keys.include?(:class)
        options[:class].ancestors.include?(Struct)
      else
        true
      end
    end

    dsl do
      spec :sort do 
        include_spec check_col_spec

        pre_cond "sort order must be :ascending or :descending" do |col, order|
          order == :ascending or order == :descending
        end
      end

      spec :summary do
        include_spec check_col_spec
      end

      spec :pivot do
        include_spec check_col_spec
      end

      spec :rows do
        dsl do
          spec :column do 
            pre_task do |arg|
              name = Dsl.state[:__rtc_rose_name]
              Dsl.state[:__rtc_rose_meta][name][:cols] ||= Set.new
              
              if arg.class == Hash
                v = arg.to_a[0][1]
                Dsl.state[:__rtc_rose_meta][name][:cols].add(v)
              else
                Dsl.state[:__rtc_rose_meta][name][:cols].add(arg)
              end              
            end

            pre_cond "hash key must be a write accessor" do |*args|            
              name = Dsl.state[:__rtc_rose_name]
              cls = Dsl.state[:__rtc_rose_class]

              if cls
                if args[0].class == Hash
                  k = args[0].to_a[0][0]
                  s = k.to_s + '='
                  cls.instance_methods.include?(s.to_sym)
                else
                  true
                end
              else
                true
              end
            end
          end
        end
      end


    end

  end
end
