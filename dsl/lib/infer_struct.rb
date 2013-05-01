require 'set'

$trace = false
$file = nil

module InferStruct
  def self.start_trace
    $trace = true
  end
  
  def self.exit_trace
    $trace = false
  end
end
  
$call_stack = []
$calls = {}

class MethodID
  attr_reader :cls
  attr_reader :method

  def initialize(cls, method)
    @cls = cls
    @method = method
  end

  def ==(other)
    @cls == other.cls and @method == other.method
  end

  def eql?(other)
    @cls.eql?(other.cls) and @method.eql?(other.method)
  end

  def hash
    @cls.hash + @method.hash
  end
end

set_trace_func proc {|event, file, line, id, binding, classname|
  if event == "return"
    if classname == InferStruct and id == :start_trace
      $file = caller[-1][0..caller[-1].index(':')-1]
    elsif $trace
      if caller[1] and caller[1].index($file)
        # puts "*********** POPPING #{id.inspect}"
        $call_stack.pop
      end
    end
  elsif event == "call"
    if $trace and not (classname == InferStruct and id == :exit_trace)
      if caller[1] and caller[1].index($file)
        info = {}
        info[:slf] = binding.eval("self.inspect")
        info[:blk] = binding.eval("block_given?")
        info[:file] = file
        info[:line] = line
        info[:id] = id        
        info[:classname] = classname
        info[:descendants] = Set.new if not info.has_key?(:descendants)

        m = MethodID.new(classname, id)
        # puts "*********** PUSHING #{m.inspect}   #{caller.inspect}"

        tc = $call_stack[-1]

        if tc
          $calls[tc][:descendants].add(m)
        end
        
        $calls[m] = info if not $calls.has_key?(m)
        $call_stack.push(m)
      end
    elsif $trace and classname == InferStruct and id == :exit_trace
      puts "=============================================="
      puts "INFERRED STRUCT = "
      $calls.each {|c| puts c.inspect}
    end
  end
}


