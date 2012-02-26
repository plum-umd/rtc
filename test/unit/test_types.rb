require "test/unit"
require 'rtc'

class A
end

class B < A
end

class C
end

class D
end

class TestTypeSystem < Test::Unit::TestCase
  include Rtc::Types
  def make_union(*r)
    Rtc::Types::UnionType.of(r.map {
       |klass|
       Rtc::Types::NominalType.of(klass)
    })
  end
  
  class ParentClass
    def my_method()
      puts "I'm a method!"
    end
  end

  class BreakingClass < ParentClass
    rtc_no_subtype
    undef_method :my_method
  end
  
  def initialize(*)
    [A,B,C,D].each do
      |klass|
      class_obj = Rtc::Types::NominalType.of(klass)
      accessor_name = (klass.name.downcase + "_class").to_sym
      define_singleton_method(accessor_name) {
        ||
        class_obj
      }
    end
    @boolean_type = UnionType.of([NominalType.of(TrueClass), NominalType.of(FalseClass)])
    #arrays are parameterized over types T
    NominalType.of(Array).type_parameters = [TypeParameter.new(:T)]
    #sets are parameterized over types K
    NominalType.of(Set).type_parameters = [TypeParameter.new(:K)]
    super
  end

  attr_reader :boolean_type
 
  def test_nominal
    assert_equal(false, a_class <= b_class)
    assert(b_class <= a_class)
    assert_equal(false, c_class <= b_class)
    [a_class,b_class,c_class].each {
      |klass_obj|
      assert(klass_obj <= klass_obj)
    }
  end
  
  def test_no_subtype
    assert_equal(false, NominalType.of(BreakingClass) <= NominalType.of(ParentClass))
  end

  def test_proc_type
    proc_type_a = Rtc::Types::ProceduralType.new(c_class, [a_class, a_class])
    proc_type_b = Rtc::Types::ProceduralType.new(c_class, [b_class, b_class])

    assert(proc_type_a <= proc_type_b)
  end
  
  def test_parameterized_type
    #the base types
    set_type = NominalType.of(Set)
    array_type = NominalType.of(Array)

    
    array_type.add_method(:[], ProceduralType.new(TypeParameter.new(:T), [ NominalType.of(Fixnum) ]))
    
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
  end
  def test_union
    union_type = UnionType.of([c_class, a_class])
    assert(a_class <= union_type)

    union_type2 = UnionType.of([NominalType.of(D), a_class, c_class])
    union_type3 = UnionType.of([b_class, c_class])
    assert(union_type3 <= union_type2)
  end
  
  def test_rtc_type
    my_type = A.new.rtc_type
    assert_equal("NominalType<A>", my_type.to_s)
  end
  def test_dynamic_types
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

    assert(string_array.rtc_type <= num_str_arr.rtc_type)
    string_array.rtc_type.parameters[0].constrain_to(NominalType.of(String))
    assert_equal(false, string_array.rtc_type <= num_str_arr.rtc_type)

    assert_equal(false, ["bar", 4, 4.0].rtc_type <= num_str_arr.rtc_type)
  end

  def test_symbol
    sym1 = SymbolType.new(:a)
    sym2 = SymbolType.new(:b)
    sym3 = SymbolType.new(:c)

    assert_equal(false, sym1 <= sym2)
    assert(sym1 <= SymbolType.new(:a))
  end

  def test_dynamic_subtype
    test_obj = [1,2]
    type_parameter = test_obj.rtc_type.parameters[0]
    # type_parameter is still open
    assert("foo".rtc_type <= type_parameter)
    # type_paremter is now Fixnum or String
    test_obj.push("foo")

    other_test_obj = [1,"foo",:foo]
    other_type_parameter = other_test_obj.rtc_type.parameters[0]
    # tests that when subtyping two type variables, the "everything goes" is not
    # in place, we do proper subtyping checks
    assert_equal(false, other_type_parameter <= type_parameter)
    assert(type_parameter <= other_type_parameter)
    type_parameter.constrain_to(make_union(Fixnum, String))

    # ensure that after constraining t <= t' iff t == t' holds
    assert_equal(false, type_parametexr <= other_type_parameter)

    # test that after constraining, proper subtyping takes place
    assert_equal(false, :foo.rtc_type <= type_parameter)
  end
end
