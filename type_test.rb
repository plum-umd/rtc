require 'rtc/typing/types.rb'
require 'set'

#program to write quick test cases to rapidly develop type code
# run as ruby -Ilib type_test.rb

#testing framework? what's that?

include Rtc::Types

def make_union(*r)
  UnionType.of(r.map {
                 |klass|
                 NominalType.of(klass)
               })
end

class A
end
class B < A
end
class C
end
class D
end
c_class = Rtc::Types::NominalType.of(C)
b_class = Rtc::Types::NominalType.of(B)
a_class = Rtc::Types::NominalType.of(A)

boolean_type = UnionType.of([NominalType.of(TrueClass), NominalType.of(FalseClass)])

puts "should be false => #{a_class <= b_class}"
puts "should be true => #{b_class <= a_class}"
puts "should be false => #{c_class <= b_class}"
[a_class, b_class, c_class].each do |k|
  puts "should be true => #{k <= k}"
end

proc_type_a = Rtc::Types::ProceduralType.new(c_class, [a_class, a_class])
proc_type_b = Rtc::Types::ProceduralType.new(c_class, [b_class, b_class])
puts "should be true => #{proc_type_a <= proc_type_b}"

sym1 = SymbolType.new(:a)
sym2 = SymbolType.new(:b)
sym3 = SymbolType.new(:c)
puts "should be false => #{sym1 <= sym2}"
puts "should be true => #{sym1 <= SymbolType.new(:a)}"

#tests for Parameterized Types

#the base types
set_type = NominalType.of(Set)
array_type = NominalType.of(Array)

#arrays are parameterized over types T
array_type.type_parameters = [TypeParameter.new(:T)]
array_type.add_method(:[], ProceduralType.new(TypeParameter.new(:T), [ NominalType.of(Fixnum) ]))

#sets are parameterized over types K
set_type.type_parameters = [TypeParameter.new(:K)]

#This is the type Array<K>
array_ret = ParameterizedType.new(array_type, [TypeParameter.new(:K)])

#This is the type () -> Array<K>
to_a_type = ProceduralType.new(array_ret, [])

set_type.add_method(:to_a, to_a_type)

include_type = ProceduralType.new(boolean_type, [TypeParameter.new(:K)])

set_type.add_method(:includes?, include_type)

# this is Set<A>
a_set = ParameterizedType.new(set_type, [a_class])
puts "should be [ () -> Array<NominalType<A>> ] => #{a_set.get_method(:to_a)}"
puts "should be [ (NominalType<Fixnum>) -> NominalType<A> ] => #{a_set.get_method(:to_a).return_type.get_method(:[])}"
puts "should be [ (NominalType<A>) -> (TrueClass or FalseClass) ] => #{a_set.get_method(:includes?)}"

union_type = UnionType.of([c_class, a_class])
puts "Should be true => #{a_class <= union_type}"

union_type2 = UnionType.of([NominalType.of(D), a_class, c_class])
union_type3 = UnionType.of([b_class, c_class])
puts "Should be true => #{union_type3 <= union_type2}"

my_type = A.new.rtc_type
puts "should be NominalType<A> => #{my_type}"
my_array = []
my_array << 2
array_type = my_array.rtc_type
puts "should be Array<NominalType<Fixnum>> => #{array_type}"
my_array << "hi!"
puts "should be Array<(NominalType<Fixnum> or NominalType<String>)> => #{array_type}"
my_array.delete_at(0)
puts "should be Array<NominalType<String>> => #{array_type}"

num_str_arr = [ "foo", 2 ]
#puts num_str_arr.rtc_type
string_array = [ "bar" ]
#puts string_array.rtc_type
puts "should be true => #{string_array.rtc_type <= num_str_arr.rtc_type}"
string_array.rtc_type.parameters[0].constrain_to(NominalType.of(String))
puts "should now be false => #{string_array.rtc_type <= num_str_arr.rtc_type}"

#string_array.rtc_type.parameters[0].constrain_to(NominalType.of(String))

puts "should be false => #{["bar", 4, 4.0].rtc_type <= num_str_arr.rtc_type}"

require 'rtc'

class ParentClass
  def my_method()
    puts "I'm a method!"
  end
end

class BreakingClass < ParentClass
  rtc_no_subtype
  undef_method :my_method
end

p = ParentClass.new
b = BreakingClass.new

puts "should be false => #{b.rtc_type <= p.rtc_type}"
