
# Determinig source position at runtime is very tricky *as* it sounds. So I
# allowed several different types of position as legitimate. Refer to each
# class for detail.
#
# NOTE: Because most positions do not have precise source line number, it is
# required to do some sort of post processing. This is a TODO for now.

require 'rtc/utils'

module Rtc

    module Positioning
        # finds the source location of the caller (of specified level). 
        def self.caller_pos(callerstack, level=1)
            info = callerstack[level].split(":")
            LinePosition.new(info[0].to_s, info[1].to_i)
        end 

        # computes the file/line position of the current control flow but disregards
        # any internal files. they appear because we do this patching and evals.
        def self.get_smart_pos()
            pos = caller_pos(caller(), 0)
            i = 0
            while (pos.file =~ /(monitors.rb|modifier.rb|\(eval\))/) do
                i = i + 1
                pos = caller_pos(caller(), i)
            end
            return pos
        end
    end

  class Position; end # this is just a dummy abstract class

  class MergedPosition < Position
    attr_reader :pos_list

    def initialize(*args)
      if args.length == 1
        case args[0]
        when Array
          @pos_list = args[0]
        else
          raise "Merged position takes more than one individual positions"
        end 
      elsif args.length > 1
        @pos_list = args
      else
        raise "Merged position takes more than one individual positions"
      end
    end

    def to_s; (@pos_list.map {|pos| pos.to_s}).join(" and ") end

  end

  # represents a position in the source code.
  class LinePosition < Position

    attr_accessor :file
    attr_accessor :line

    def initialize(file,line=nil)
      @file = file
      @line = line
    end 

    def self.dummy_pos(); LinePosition.new("???", -1) end 
    def to_s(); "#{file ? file : "???"} : #{line ? line : -1}" end

  end 

  # this is special. it contains type parameter name (in string)
  class TypeParamPosition < LinePosition

    attr_accessor :type_param

    def initialize(type_param, file, line)
      super(file, line)
      @type_param = type_param
    end

    def to_s; "tparam #{type_param.to_s} (#{super()})" end

  end

  # represents a location for a class
  class ClassPosition < Position

    attr_accessor :klass

    def initialize(klass); @klass = klass end
    def to_s()
      @klass.respond_to?(:name) ? @klass.name : @klass.to_s
    end

  end 

  class FieldPosition < ClassPosition

    attr_accessor :fname

    def initialize(klass, fname) 
      super(klass)
      @fname = fname
    end 

    def to_s(); "#{super}##{fname}" end

  end

  # represents mname definition location using the class name and the mname
  # name
  class DefPosition < ClassPosition

    attr_accessor :klass
    attr_accessor :mname

    def initialize(klass, mname)
      super(klass)
      @mname = mname
    end 

    # TODO: there is a room for improvement here!
    def to_s()
      "#{super}##{mname}" 
    end

    def self.dummy_pos(); DefPosition.new("???", "???") end

  end 

  # represents a formal argument position using its index.
  class FormalArgPosition < DefPosition

    attr_accessor :index

    def initialize(klass, mname, index)
      super(klass, mname)
      @index = index
    end 

    def to_s(); "#{super}(#{@index})" end

    def self.dummy_pos(); FormalArgPosition.new("???", "???", -1) end

  end 

  # represents a formal return value position. it's same as the mname
  # definition but to_s mname indicates that it's for the return value.
  class FormalRetValPosition < DefPosition

    def to_s(); "#{super} return" end

  end

  class FormalBlockPosition < DefPosition

    def to_s(); "#{super} block" end

  end

end 
