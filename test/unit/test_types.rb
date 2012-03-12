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
    set_type = NominalType.of(Set)
    a_set = ParameterizedType.new(set_type, [a_class])
    assert_equal("[ () -> Array<A> ]", a_set.get_method("to_a").to_s)
    assert_equal("[ (Fixnum) -> A ]", a_set.get_method("to_a").return_type.get_method("[]").to_s)
    assert_equal("[ (A) -> (TrueClass or FalseClass) ]", a_set.get_method("includes?").to_s)
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
    assert_equal("A", my_type.to_s)
  end
  def test_dynamic_types
    my_array = []
    my_array << 2
    array_type = my_array.rtc_type
    assert_equal("Array<Fixnum>", array_type.to_s)
    my_array << "hi!"
    assert_equal("Array<(Fixnum or String)>", array_type.to_s)
    my_array.delete_at(0)
    assert_equal("Array<String>", array_type.to_s)

    num_str_arr = [ "foo", 2 ]
    assert_equal("Array<(String or Fixnum)>", num_str_arr.rtc_type.to_s)

    string_array = [ "bar" ]
    assert_equal("Array<String>", string_array.rtc_type.to_s)

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
    assert_equal(false, type_parameter <= other_type_parameter)

    # test that after constraining, proper subtyping takes place
    assert_equal(false, :foo.rtc_type <= type_parameter)
  end
  
  def test_nested_polytypes
    #FIXME(jtoman): these tests rely very much on the ordering of types within type parameters, and should
    # be changed from string comparisons
    nested_type = [[:foo],[:bar]]
    assert_equal( "Array<Array<(:foo or :bar)>>", nested_type.rtc_type.to_s)
    assert_equal("Array<Array<(:foo or :bar or Array<(:baz or :gorp)>)>>", [[:foo,:bar], [[:baz,:gorp]]].rtc_type.to_s)
    assert_equal("Array<(:qux or Array<:bar>)>", [:qux, [:bar]].rtc_type.to_s)
  end
  
  def test_nested_polytypes_subtype
    a_instance = A.new
    single_arr = [a_instance]
    double_arr = [[a_instance]]
    assert_equal(single_arr.rtc_type <= double_arr.rtc_type, false)
    assert_equal(double_arr.rtc_type <= single_arr.rtc_type, false)
  end
  
 
  class MyClass
    rtc_annotated
    typesig("foo: (A, A) -> C")
  end
  
  class StructuralPartA
    rtc_annotated
    typesig("foo: (C) -> C")
  end
  
  class StructuralPartB < StructuralPartA
    rtc_annotated
    typesig("bar: (A) -> A")
  end
  
  def test_structural_types
    my_class_type = NominalType.of(MyClass)
    foo_method_type = ProceduralType.new(c_class, [a_class, a_class])
    structural_type = StructuralType.new({}, {"foo"=>foo_method_type})
    # test basic subtype rules
    assert(my_class_type <= structural_type)
    
    # depth subtyping
    foo_super_method_type = ProceduralType.new(c_class, [b_class, b_class])
    assert(my_class_type <= StructuralType.new({}, {"foo" => foo_super_method_type}))
    
    #failure cases, when the structual type is wider
    assert_equal(false, my_class_type <= StructuralType.new({}, {
      "foo" => foo_method_type,
      "bar" => ProceduralType.new(c_class, [])
    }))
    
    assert_equal(false, my_class_type <= StructuralType.new({},{
      "foo" => ProceduralType.new(c_class, [])
    }))
  end
  
  def test_structural_respects_inheritance
    struct_type = StructuralType.new({},{
      "foo" => ProceduralType.new(c_class, [c_class]),
      "bar" => ProceduralType.new(a_class, [a_class])
    })
    assert(NominalType.of(StructuralPartB) <= struct_type)
  end
end
