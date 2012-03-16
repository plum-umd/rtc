require "test/unit"
require 'rtc'

class MyClass
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
  
  typesig("multi_candidate: (Fixnum,Fixnum) -> String")
  typesig("multi_candidate: (Fixnum,Fixnum) -> Fixnum")
  def multi_candidate(a,b)
    if a + b > 5
      "Foo"
    elsif a + b > 0
      4
    else
      :foo
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

class Array
  typesig("my_push: (t) -> Array<t>")
  def my_push(obj)
    self.push(obj)
  end
end

class TestTypeChecking < Test::Unit::TestCase
 
  attr_reader :test_instance 
 
  def initialize(*)
    @test_instance = MyClass.new
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
    
    check_failure(test_instance.method(:different_formals),[
      [1,2,5],
      [1,"foo","bar",5],
      [1,"foo",4,"bar",5]
    ])
  end
   
   def test_parameterized_arg
     assert_nothing_raised do
       test_instance.parameterized_arg([:subscribers, :talks])
       test_instance.parameterized_arg([:subscribers])
       test_instance.parameterized_arg([:talks])
       test_instance.parameterized_arg([:subscribed_talks])
     end
     
     check_failure(test_instance.method(:parameterized_arg),[
       [:tals],
       [:talks,:foorbar]
     ])
   end
   
   def test_intersection_type
     assert_nothing_raised do
       test_instance.intersection_type(4,4)
       test_instance.intersection_type("foo")
     end
     
     check_failure(test_instance.method(:intersection_type),[
       [4],
       ["foo","bar"],
       [4,"boo"],
     ])
   end
   
   def test_multi_candidate
     assert_nothing_raised do
       test_instance.multi_candidate(1,0)
       test_instance.multi_candidate(3,3)
     end
     
     assert_raise Rtc::TypeMismatchException do
       test_instance.multi_candidate(-1,-1)
     end
     
   end
   
   def test_field_checking
     field_instance = FieldClass.new
     assert_nothing_raised do
       field_instance.foo = 4
     end
     check_failure(field_instance.method(:foo=),[
       [:foo],
       ["4"]
     ])
   end
   
   def test_intersection_field
     field_instance = FieldClass.new
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
     expected_method_type = Rtc::Types::ProceduralType.new(Rtc::Types::UnionType.of([
       Rtc::Types::NominalType.of(TrueClass), Rtc::Types::NominalType.of(FalseClass)
     ]),[ Rtc::Types::TypeParameter.new(:t) ])
     assert_equal(Set.rtc_instance_typeof("includes?"),expected_method_type)
   end
   
   
   def test_instance_typeof
     expected_method_type = Rtc::Types::ProceduralType.new(Rtc::Types::NominalType.of(Fixnum),[
       Rtc::Types::NominalType.of(Fixnum)
     ])
     test_instance = MyClass.new
     assert_equal(test_instance.rtc_typeof("simple_method"),expected_method_type)
     assert_equal(test_instance.rtc_typeof("simple_method"),MyClass.rtc_instance_typeof("simple_method"))
     assert_equal(FieldClass.rtc_instance_typeof("@foo"),(fixnum_type = Rtc::Types::NominalType.of(Fixnum)))
     assert_equal(FieldClass.rtc_instance_typeof(:@foo),fixnum_type)
     assert_equal(MyClass.rtc_instance_typeof(:simple_method),expected_method_type)
     assert_equal(MyClass.rtc_instance_typeof("simple_method"),expected_method_type)
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
     foo_type = proc_type.new(rtc_of[String], [
       rtc_of[Fixnum]
     ])
     child_instance = ChildClass.new
     assert_equal(child_instance.rtc_typeof("foo"), foo_type)
     assert_equal(ChildClass.rtc_instance_typeof("foo"), foo_type)
     
     bar_type = proc_type.new(rtc_of[String],[
       rtc_of[String]
     ])
     assert_equal(ChildClass.rtc_instance_typeof("bar"), bar_type)
     assert_equal(child_instance.rtc_typeof("bar"), bar_type)
     assert_equal("adsf".rtc_typeof("adfadfadfsasdf"), nil)
     assert_equal(String.rtc_instance_typeof("adfadfadfadf"), nil)
     
     assert_equal(NoSubtypeChildClass.rtc_instance_typeof("foo"), nil)
   end
   
   def test_constrained()
     my_arr = [1]
     assert_nothing_raised do
       my_arr.push("foo")
     end
     assert_raise Rtc::TypeNarrowingError do
       my_arr.rtc_annotate("Array<Fixnum>")
     end
     assert_nothing_raised do
       my_arr.rtc_annotate("Array<String or Fixnum>")
     end
     assert_raise Rtc::TypeMismatchException do
       my_arr.my_push(4.0)
     end
   end
   
end
