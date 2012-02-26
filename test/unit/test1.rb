require "test/unit"
require 'rtc'

class MyClass
  rtc_annotated
  
  typesig("f: (Fixnum,?String,*Fixnum,Fixnum) -> Fixnum")
  def f(*a)
    a[0] + a[-1]
  end

  typesig("my_method: (:foo or :bar) -> Fixnum")
  def my_method(b)
    5
  end
  typesig("my_other_method: (Array<:subscribers or :talks or :subscribed_talks>) -> Fixnum")
  def my_other_method(b)
    6
  end
end


class TestMyClass < Test::Unit::TestCase
 
  def test_simple
    ts = "[ (NominalType<Fixnum>, ?(NominalType<String>), *(NominalType<Fixnum>), NominalType<Fixnum>) -> NominalType<Fixnum> ]"
    assert_equal(ts, MyClass.new.rtc_typeof("f").to_s)
    assert_equal(3, MyClass.new.f(1,2))
  end

   def test_failure
     assert_raise Rtc::TypeMismatchException do
       MyClass.new.f(4, "doh")
     end
   end
end
