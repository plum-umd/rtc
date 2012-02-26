require "test/unit"
require 'rtc'

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


class TestMyClass < Test::Unit::TestCase
 
  def test_various
    c_class = Rtc::Types::NominalType.of(C)
    b_class = Rtc::Types::NominalType.of(B)
    a_class = Rtc::Types::NominalType.of(A)

    boolean_type = UnionType.of([NominalType.of(TrueClass), NominalType.of(FalseClass)])

    assert_equal(false, a_class <= b_class)
    assert_equal(true, b_class <= a_class)
    assert_equal(false, c_class <= b_class)
    assert_equal(true, a_class <= a_class)
    assert_equal(true, b_class <= b_class)
    assert_equal(true, c_class <= c_class)

    proc_type_a = Rtc::Types::ProceduralType.new(c_class, [a_class, a_class])
    proc_type_b = Rtc::Types::ProceduralType.new(c_class, [b_class, b_class])

    assert_equal(true, proc_type_a <= proc_type_b)

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
    assert_equal("[ () -> Array<NominalType<A>> ]", a_set.get_method(:to_a).to_s)
    assert_equal("[ (NominalType<Fixnum>) -> NominalType<A> ]", a_set.get_method(:to_a).return_type.get_method(:[]).to_s)
    assert_equal("[ (NominalType<A>) -> (NominalType<TrueClass> or NominalType<FalseClass>) ]", a_set.get_method(:includes?).to_s)

    union_type = UnionType.of([c_class, a_class])
    assert_equal(true, a_class <= union_type)

    union_type2 = UnionType.of([NominalType.of(D), a_class, c_class])
    union_type3 = UnionType.of([b_class, c_class])
    assert_equal(true, union_type3 <= union_type2)

    my_type = A.new.rtc_type
    assert_equal("NominalType<A>", my_type.to_s)
    my_array = []
    my_array << 2
    array_type = my_array.rtc_type
    assert_equal("Array<NominalType<Fixnum>>", array_type.to_s)
    my_array << "hi!"
    assert_equal("Array<(NominalType<Fixnum> or NominalType<String>)>", array_type.to_s)
    my_array.delete_at(0)
    assert_equal("Array<NominalType<String>>", array_type.to_s)

    num_str_arr = [ "foo", 2 ]
    assert_equal("Array<(NominalType<String> or NominalType<Fixnum>)>", num_str_arr.rtc_type.to_s)

    string_array = [ "bar" ]
    assert_equal("Array<NominalType<String>>", string_array.rtc_type.to_s)

    assert_equal(true, string_array.rtc_type <= num_str_arr.rtc_type)
    string_array.rtc_type.parameters[0].constrain_to(NominalType.of(String))
    assert_equal(false, string_array.rtc_type <= num_str_arr.rtc_type)

    assert_equal(false, ["bar", 4, 4.0].rtc_type <= num_str_arr.rtc_type)
  end

  def test_symbol
    sym1 = SymbolType.new(:a)
    sym2 = SymbolType.new(:b)
    sym3 = SymbolType.new(:c)

    assert_equal(false, sym1 <= sym2)
    assert_equal(true, sym1 <= SymbolType.new(:a))
  end
end
