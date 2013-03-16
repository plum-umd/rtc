# http://rubydoc.info/gems/hash_converter/0.0.2/frames

require "hash_converter"

class HashConverter
  extend Dsl

  class << self
    extend Dsl

    spec :convert do
      pre_task do |arg, blk|
        $h = arg
      end
    end

    spec :path do
      pre_task do |arg, blk|
        $k = [] if not $k
        $k.push(arg.to_sym)
      end

      pre_cond do |arg, blk|
        x = $h

        $k.all? {|i|
          x.keys.include?(i)
          x = x[i]
        }
      end

      post_task do 
        $k.pop
      end
    end

    spec :map do
      pre_cond do |arg1, arg2, arg3, blk|
        x = $h
        $k.each {|i| x = x[i]}

        arg1.gsub(KEY_REGEX).all? {|v| 
          v = v.split('{')[1]
          v = v.split('}')[0].to_sym
          x.keys.include?(v)
        }
      end
    end
  end
end
