require "test/unit"
require 'rtc_lib'

class TypeCheckingTestClass
  rtc_annotated
  
  typesig("simple_method: (Fixnum) -> Fixnum")
  def simple_method(arg)
    arg + 1
  end
  
  typesig("bad_return: () -> Fixnum")
  def bad_return
    "foo"
  end
  
  typesig("bad_return_2: (.?) -> String")
  def bad_return_2(my_obj)
    return my_obj && true
  end
  
  typesig("subtype_arg: (Integer) -> Integer")
  def subtype_checking(arg)
    arg + 1
  end
  
  # a method where the formal parameter lists does not match the
  # given type annotation 
  typesig("different_formals: (Fixnum,?String,*Fixnum,Fixnum) -> Fixnum")
  def different_formals(*a)
    a[0] + a[-1]
  end

  typesig("union_arg: (:foo or :bar) -> Fixnum")
  def union_arg(b)
    5
  end
  
  typesig("parameterized_arg: (Array<:subscribers or :talks or :subscribed_talks>) -> Fixnum")
  def parameterized_arg(b)
    6
  end
  
  typesig("union_return: (Fixnum) -> Fixnum or String")
  def union_return(a)
    if a < 10
      return 0
    else
      return "hello world!"
    end
  end
  
  typesig("intersection_type: (Fixnum, Fixnum) -> Fixnum")
  typesig("intersection_type: (String) -> String")
  def intersection_type(a,b = nil)
    if b.nil?
      a + "1"
    else
      a + b + 5
    end
  end
end

class FieldClass
  rtc_annotated
  typesig('@foo: Fixnum')
  attr_accessor :foo
  
  typesig('@bar: String')
  typesig('@bar: Fixnum')
  attr_accessor :bar
end

class TestTypeChecking < Test::Unit::TestCase
 
  attr_reader :test_instance 
 
  def initialize(*)
    @test_instance = TypeCheckingTestClass.new.rtc_annotate("TypeCheckingTestClass")
    super
  end
 
  def check_failure(method,arg_vectors)
    arg_vectors.each {
      |arg_vector|
      assert_raise Rtc::TypeMismatchException do
        method.call(*arg_vector)
      end
    }
  end
  
  def setup
    assert(Rtc::MasterSwitch.is_on?)
  end
  
  def test_simple
    assert_nothing_raised do
      test_instance.simple_method(5)
    end
    assert_raise Rtc::TypeMismatchException do
      test_instance.simple_method("foo")
    end
  end
  
  def test_bad_return
    assert_raise Rtc::TypeMismatchException do
      test_instance.bad_return
    end
    
    assert_raise Rtc::TypeMismatchException do
      test_instance.bad_return_2(3)
    end
  end
  
  def test_union_return()
    assert_nothing_raised do
      test_instance.union_return(1)
      test_instance.union_return(11)
    end
  end
  
  def test_union_args
    assert_nothing_raised do
      test_instance.union_arg(:foo)
      test_instance.union_arg(:bar)
    end
  end
  
  def test_subtype_checking
    assert_nothing_raised do
      test_instance.subtype_checking(4)
    end
  end
  
  def test_different_formals
    assert_nothing_raised do
      test_instance.different_formals(1,5)
    end
  end
  
  def test_complex_parameters
    assert_nothing_raised do
      test_instance.different_formals(1,"foo",5)
      test_instance.different_formals(1,4)
      test_instance.different_formals(1,"foo",4,5,6,7,8)
    end
    
     [
      [1,2,5],
      [1,"foo","bar",5],
      [1,"foo",4,"bar",5]
     ].each {
      |arg_vector|
      assert_raise Rtc::TypeMismatchException do
        test_instance.different_formals(*arg_vector)
      end
    }
  end
   
    def test_parameterized_arg
      $RTC_STRICT = true
     assert_nothing_raised do
       test_instance.parameterized_arg([:subscribers, :talks])
       test_instance.parameterized_arg([:subscribers])
       test_instance.parameterized_arg([:talks])
       test_instance.parameterized_arg([:subscribed_talks])
     end
     
     [
       [:tals],
       [:talks,:foorbar]
     ].each {
        |arg_vector|
        assert_raise Rtc::TypeMismatchException do
          test_instance.parameterized_arg(*arg_vector)
        end
      }
      $RTC_STRICT = false
   end
   
   def test_intersection_type
     assert_nothing_raised do
       test_instance.intersection_type(4,4)
       test_instance.intersection_type("foo")
     end
     [
      [4],
      ["foo","bar"],
      [4,"boo"],
     ].each {
       |arg_vector|
       assert_raise Rtc::TypeMismatchException do
         test_instance.intersection_type(*arg_vector)
       end
     }
   end
   def test_field_checking
     field_instance = FieldClass.new.rtc_annotate("FieldClass")
     assert_nothing_raised do
       field_instance.foo = 4
     end
     [:foo, "4"].each {
       |v|
       assert_raise Rtc::TypeMismatchException do
         field_instance.foo = v
       end
     }
   end
   
   def test_intersection_field
     field_instance = FieldClass.new.rtc_annotate("FieldClass")
     assert_nothing_raised do
       field_instance.bar = 4
       field_instance.bar = "3"
     end
     
     assert_raise Rtc::TypeMismatchException do
       field_instance.bar = :foo
     end
   end
   
   # also tests for automatic unioning
   def test_field_query
     field_instance = FieldClass.new
     assert_equal(field_instance.rtc_typeof(:@foo),Rtc::Types::NominalType.of(Fixnum))
     assert_equal(field_instance.rtc_typeof(:@bar),Rtc::Types::UnionType.of([
      Rtc::Types::NominalType.of(Fixnum),
      Rtc::Types::NominalType.of(String)
     ]))
     assert_equal(field_instance.rtc_typeof("@foo"),Rtc::Types::NominalType.of(Fixnum))
     assert_equal(field_instance.rtc_typeof("@bar"),Rtc::Types::UnionType.of([
      Rtc::Types::NominalType.of(Fixnum),
      Rtc::Types::NominalType.of(String)
     ]))
   end
   
   
   def test_parameterized_instance_typeof
     expected_method_type = Rtc::Types::ProceduralType.new([],Rtc::Types::TypeParameter.new(:t), [
        Rtc::Types::NominalType.of(Fixnum)
     ])
     assert_equal(expected_method_type, Array.rtc_instance_typeof("at"))
   end
   
   
   def test_instance_typeof
     expected_method_type = Rtc::Types::ProceduralType.new([], Rtc::Types::NominalType.of(Fixnum),[
       Rtc::Types::NominalType.of(Fixnum)
     ])
     test_instance = TypeCheckingTestClass.new.rtc_annotate("TypeCheckingTestClass")
     assert_equal(test_instance.rtc_typeof("simple_method"),expected_method_type)
     assert_equal(test_instance.rtc_typeof("simple_method"),TypeCheckingTestClass.rtc_instance_typeof("simple_method"))
     assert_equal(FieldClass.rtc_instance_typeof("@foo"),(fixnum_type = Rtc::Types::NominalType.of(Fixnum)))
     assert_equal(FieldClass.rtc_instance_typeof(:@foo),fixnum_type)
     assert_equal(TypeCheckingTestClass.rtc_instance_typeof(:simple_method),expected_method_type)
     assert_equal(TypeCheckingTestClass.rtc_instance_typeof("simple_method"),expected_method_type)
   end
   
   
   class SuperClass
    rtc_annotated
    typesig("foo: (Fixnum) -> String")
    typesig("bar: (Fixnum) -> Fixnum")
   end
  
   class ChildClass < SuperClass
    rtc_annotated
    typesig("bar: (String) -> String")
   end
   
   class NoSubtypeChildClass < SuperClass
     rtc_no_subtype
   end
   
   def test_inheritance_typeof
     rtc_of = Rtc::Types::NominalType.method(:of)
     proc_type = Rtc::Types::ProceduralType
     foo_type = proc_type.new([], rtc_of[String], [
       rtc_of[Fixnum]
     ])
     child_instance = ChildClass.new
     assert_equal(child_instance.rtc_typeof("foo"), foo_type)
     assert_equal(ChildClass.rtc_instance_typeof("foo"), foo_type)
     
     bar_type = proc_type.new([], rtc_of[String],[
       rtc_of[String]
     ])
     assert_equal(ChildClass.rtc_instance_typeof("bar"), bar_type)
     assert_equal(child_instance.rtc_typeof("bar"), bar_type)
     assert_equal("adsf".rtc_typeof("adfadfadfsasdf"), nil)
     assert_equal(String.rtc_instance_typeof("adfadfadfadf"), nil)
     
     assert_equal(NoSubtypeChildClass.rtc_instance_typeof("foo"), nil)
   end
   
   def test_constrained()
     my_arr = [1, "foo"]
     annotated_arr = nil
     assert_nothing_raised do
       annotated_arr = my_arr.rtc_annotate("Array<String or Fixnum>")
     end
     assert_raise Rtc::AnnotateException do
       annotated_arr.rtc_annotate("Array<Fixnum>")
     end
     assert_raise Rtc::TypeMismatchException do
       annotated_arr.push(4.0)
     end
   end
   
   
   class ParentSig
     rtc_annotated
     typesig("foo: (Fixnum) -> Fixnum")
     def foo(x)
       x + 1
     end
     typesig("bar: () -> Fixnum")
     def bar
       4
     end
     typesig("@baz_field: Fixnum")
   end
  
  class OverrideSig < ParentSig
    rtc_annotated
    typesig("foo: (String) -> String")
    def foo(x)
      super(Integer x).to_s
    end
  end
   
  def test_override_typesig
    assert_nothing_raised do
      OverrideSig.new.rtc_annotate("OverrideSig").foo("2")
    end
    assert_raise Rtc::TypeMismatchException do
      OverrideSig.new.rtc_annotate("OverrideSig").foo(4)
    end
    
    assert_raise Rtc::TypeMismatchException do
      ParentSig.new.rtc_annotate("ParentSig").foo("2")
    end
    
    assert_nothing_raised do
      ParentSig.new.rtc_annotate("ParentSig").foo(4)
    end
  end
   
   def test_typeof_include_super
     expected_type = Rtc::Types::ProceduralType.new([], Rtc::Types::NominalType.of(Fixnum), [])
     assert_equal(expected_type,OverrideSig.rtc_instance_typeof("bar"))
     assert_equal(nil, OverrideSig.rtc_instance_typeof("bar", false))
     assert_equal(Rtc::Types::NominalType.of(Fixnum), OverrideSig.rtc_instance_typeof(:@baz_field))
     assert_equal(nil, OverrideSig.rtc_instance_typeof(:baz_field, false))
   end
end
