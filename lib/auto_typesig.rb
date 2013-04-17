# Purpose
# This file uses the run-time types used in a unit test file to
# build a typesig template for the class.
#
# How to use?
#
# 1. In this file, change $cls to the class in the unit test
# 2. In the unit test file, add "require 'auto_typesig'" on top
# 3. Run the unit test as usual
# 4. Typesigs will be written to typesig_#{cls}.rb
#    In the result typesig file
#    * Each run-time type is added as a separate typesig
#    * Each intersection type has an inferred (and possibly incorrect)
#      typesig as a comment right below it.
#    * Each type in the commented typesig is created using the least
#      common ancestor class in the corresponding type position.
#    * typesigs are sorted based on method names
#    * intersection typesigs are sorted based on the number of arguments

# Problems
# 1. Does not work with a lot of parameterized stuff
# 2. Inferred typesigs may be incorrect
# 3. No support for class methods
# 4. Block types are not recorded

require 'set'
require 'rtc_lib'

$cls = Fixnum
$outfile = "typesig_#{$cls}.rb"
$auto_typesigs = {}
$typesigh = {}
$info = []

class AutoTypesig
  attr_accessor :arg_types
  attr_accessor :ret_type

  def initialize(arg_types, ret_type)
    @arg_types = arg_types
    @ret_type = ret_type
  end
end

$gid= 0

module Spec
  def auto_typesig(m)
    om = "foo_#{$gid}"
    $gid = $gid + 1

    class_eval do
      alias_method om, m

      define_method(m) do |*args, &blk|
        r = self.send(om.to_sym, *args, &blk)
        $info.push([self.class, m, args, r])
        r
      end
    end
  end
end

$cls.class_eval do
  extend Spec

  methods = self.instance_methods(false)
  deletes = [:old_equal?, :old_eql?, :old_eq]

  deletes.each {|d|
    methods.delete(d)
  }

  methods.each {|m| auto_typesig m}
end


module MiniTest
  class Unit
    alias :old_run :run
    
    def get_lca(argi)
      ancestors = argi.map {|a|
        if a.instance_of?(Rtc::Types::NominalType)
          a.klass.ancestors
        elsif a.instance_of?(Rtc::Types::ParameterizedType)
          a.nominal.klass.ancestors
        elsif a.instance_of?(Rtc::Types::BottomType)
          NilClass.ancestors
        else
          raise Exception, "Type not supported"
        end
      }
      
      lc = ancestors[0]
      ancestors.each {|a| lc = lc & a}
      lc[0]
    end

    
    def run args = []
      old_run(args)

      puts "\nWriting typesigs for class #{$cls} in #{$outfile}..."

      info = Array.new($info)
      info.each {|c, m, args, ret|
        $typesigh[c] = {} if not $typesigh[c]
        $typesigh[c][m] = [] if not $typesigh[c][m]
        arg_types = args.map {|a| a.rtc_type}
        ret_type = ret.rtc_type
        t = Rtc::Types::ProceduralType.new([], ret_type, arg_types)
        $typesigh[c][m].push(t)
      }

      $typesigh.each {|cls, data|
        f = File.new($outfile, 'w')

        begin
          f.puts "class #{cls}\n  rtc_annotated\n\n"

          data.sort.each {|m, tlist|
            t = Rtc::Types::IntersectionType.of(tlist)
            m = "\'#{m}\'" if m.match(/[^A-za-z0-9]/)
            
            if t.instance_of?(Rtc::Types::IntersectionType)
              sh = {}
              max_size = 0
              num_types = t.types.size

              t.types.map {|t|
                s = t.arg_types.size
                sh[s] = [] if not sh[s]
                sh[s].push(t)
                max_size = s if max_size < s
              }

              t = sh.sort.to_a.map {|a, b| b}
              t.flatten!

              args = t.map {|t| t.arg_types}
              rets = t.map {|t| t.return_type}

              if num_types > 1
                nt = []
                i = 0
                
                while i < max_size
                  argi = args.map {|a| a.values_at(i)}
                  argi.flatten!
                  argi.select! {|v| v != nil}
                  lc = get_lca(argi)
                  nt.push(lc.rtc_type)
                  i += 1
                end

                nrt = get_lca(rets).rtc_type
              end
            else
              t = [t]
            end
            
            t.each {|t|
              t = t.to_s[2..-3]
              f.puts "  typesig(\"#{m}: #{t}\")"
            }            

            if nt
              nt.map! {|t| t.to_s[8..-2]}
              nt = "(" + nt.map {|t| "#{t}"}.join(", ") + ")"
              nrt = nrt.to_s[8..-2]
              typesig2 = "  # typesig(\"#{m}: #{nt} -> #{nrt}\")"
              f.puts typesig2
            end
          }

          f.puts "end"
        rescue Exception => e
          f.close
          puts e.backtrace
        end
      }
    end
  end
end
