require 'rtc/annot_parser.tab'
require 'rtc/annotated'

# Run 
# ruby -Ilib bin/rubydust get_types.rb input_file
#


#def assert(v)
#  fail "[FAIL] assert failed." unless v
#end

#def assert_equal(v1, v2, *msg)
#  fail "[FAIL] assert_equal failed." unless v1 == v2
#end

input_file = ARGV[0]

require input_file

puts Foo.type_of('dummy')
puts Foo.type_of('factorial')
puts Foo.type_of('f')
puts Foo.type_of('f2')
puts Foo.type_of('f3')
puts Foo.type_of('f4')

exit

def __factorial(x)
#   foo = Foo.new
#   foo.factorial(x)

#   puts Foo.method_types['factorial']...
#   puts x.instance_of?(NominalType...)

   return x + 1
end

foo = Foo.new
puts __factorial(5)
