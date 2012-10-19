require "test/unit"
require 'rtc'

class MyClass
  rtc_annotated
  typesig("@@foo: Fixnum")
  def self.foo=(a)
    @@foo = a
  end
  def self.foo(a)
    @@foo
  end
  typesig("self.bar: (Fixnum) -> Fixnum")
  def self.bar(x)
    x + 1
  end
end

class MySubClass < MyClass
  rtc_annotated
  typesig("self.bar: (String) -> String")
  def self.bar(x)
    super(Integer x).to_s
  end
end

class TestClassAnnot < Test::Unit::TestCase
  def test_typeof
    assert_equal(Rtc::Types::NominalType.of(Fixnum), MyClass.rtc_typeof(:@foo))
    meth_typesig = Rtc::Types::ProceduralType.new([], Rtc::Types::NominalType.of(Fixnum),[
    Rtc::Types::NominalType.of(Fixnum)])
    assert_equal(meth_typesig, MyClass.rtc_typeof(:bar))
    assert_equal(Rtc::Types::ProceduralType.new([],"".rtc_type, ["".rtc_type]), MySubClass.rtc_typeof(:bar))
  end
  
  def test_class_field_type_check
    assert_raise Rtc::TypeMismatchException do
      MyClass.foo = "bar"
    end
    assert_nothing_raised do
      MyClass.foo = 3
    end
  end
  
  def test_subclass_type_check
    assert_nothing_raised do
      MySubClass.bar("2")
    end
    
    assert_raise Rtc::TypeMismatchException do
      MySubClass.bar(2)
    end
  end
end
