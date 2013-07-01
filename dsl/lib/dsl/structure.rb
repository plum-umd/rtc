require 'set'
require 'ruby-graphviz'
require 'graphviz/theory'
require 'yaml'
require 'set'
require 'helpers'

class Array
  def to_edge_array
    x = self.each_slice(2).to_a
    self.shift

    if self
      y = self.each_slice(2).to_a
    else
      y = []
    end

    # [x, y].each {|i| i.pop if i != [] and i[-1].length == 1}
    r = x + y
    r.select {|x| x.size == 2}
  end
end

class InferStruct
  class << self
    attr_accessor :trace
    attr_accessor :file
    attr_accessor :call_stack
    attr_accessor :lang_orders
    attr_accessor :lang_orders_cur
    attr_accessor :prev_cls
    attr_accessor :trace
  end

  def self.start_trace
    @trace = true
  end
  
  def self.exit_trace
    @trace = false
  end

  def self.set_classes_to_monitor(&blk)
    @cls_monitor_blk = blk
  end

  def self.monitor_class?(cls)
    @cls_monitor_blk.call(cls) 
  end

  def self.get_paths
    h = {}

    self.lang_orders.each {|l, orders|
      h[l] = Set.new

      orders.each {|order|
        order.each {|o|
          h[l].add(o.path)
        }
      }
    }

    h
  end

  def self.print_lang_orders
    lang_paths = self.get_paths

    self.lang_orders.each {|l, orders|
      puts "LANGUAGE #{l}"

      puts "   orders = "
      orders.each {|o|
        puts "      #{o.inspect}"
      }

      puts "   paths = #{lang_paths[l].inspect}"
    }
  end

  def self.write_lang_orders
    n = 0
    outdir = "lang_outdir"
    lang_paths = self.get_paths

    self.lang_orders.each {|l, orders|      
      order_methods = orders.flatten.map {|x| x.method}
      order_methods.uniq!

      prod = Set.new(order_methods.product(order_methods))
      edges = []
      missing_edges = []

      orders.each {|o|
        o = o.map {|x| x.method}
        edges2 = o.to_edge_array
        edges2.each {|e| edges.push(e) if e.size == 2}
      }

      prod.each {|e| missing_edges.push(e) if not edges.include?(e)}

      if not missing_edges.empty? 
        n = n + 1
        outfile = "#{outdir}/lang#{n}.txt"
        file = File.open(outfile, 'w')
        puts "Writing to file #{outfile}"

        #puts "lang: #{l}"
        file.write "lang: #{l}\n"

        missing_edges.each {|e| 
          # puts "edge: #{e[0]} #{e[1]}"
          file.write "edge: #{e[0]} #{e[1]}\n"
        }
        
        lang_paths[l].each {|p|
          p.map! {|x| x.method}
          p.reverse!
          path = p.join(" ")
          # puts "path: #{path}"
          file.write "path: #{path}\n"
        }

        file.close
      end
    }
  end
end

$langs = Set.new

set_trace_func proc {|event, file, line, id, binding, classname|
  slf_cls = binding.eval("self.class")

  if slf_cls == Class or slf_cls == Module
    slf_cls =  class << binding.eval("self") ; binding.eval("self") ; end
  end

  if event == "return"

    if classname == InferStruct
      if id == :exit_trace
        puts "Exiting..."
        InferStruct.print_lang_orders
        InferStruct.write_lang_orders
      end
    elsif InferStruct.file and caller[1] and caller[1].index(InferStruct.file) and InferStruct.trace and InferStruct.monitor_class?(slf_cls)

      m = InferStruct.call_stack.pop
      pc = InferStruct.prev_cls

      if pc and m.cls != pc
        if InferStruct.lang_orders[pc] 
          if not InferStruct.lang_orders_cur[pc].empty?
            InferStruct.lang_orders[pc].push(InferStruct.lang_orders_cur[pc]) 
          end

          InferStruct.lang_orders_cur[pc] = []
        end
      end

      InferStruct.prev_cls = m.cls

    end

  elsif event == "call"
    if classname == InferStruct
      if id == :start_trace
        InferStruct.trace = true
      end
    elsif caller[1] and caller[1].index(InferStruct.file) and InferStruct.trace and InferStruct.monitor_class?(slf_cls)

      InferStruct.call_stack = [] if not InferStruct.call_stack
      InferStruct.lang_orders = {} if not InferStruct.lang_orders
      InferStruct.lang_orders_cur = {} if not InferStruct.lang_orders_cur

      cs = InferStruct.call_stack.clone
      m = MethodID.new(slf_cls, id, cs)

      if InferStruct.call_stack[-1]
        InferStruct.lang_orders_cur[slf_cls] = [] if not InferStruct.lang_orders_cur[slf_cls]
        InferStruct.lang_orders[slf_cls] = [] if not InferStruct.lang_orders[slf_cls]
        InferStruct.lang_orders_cur[slf_cls].push(m)
        # puts "PUSHING #{id}  #{slf_cls}    #{InferStruct.call_stack.inspect}"
      end

      InferStruct.call_stack.push(m)
    end
  end
}


