require "test/unit"
require 'rtc'

class MyClass
  rtc_annotated
  
  typesig("f: (Fixnum) -> Fixnum or String")
  def f(a)
    if a < 10
      return 0
    else
      return "hello world!"
    end      
  end
end

class TestMyClass4 < Test::Unit::TestCase
 
  def test_simple
    assert_equal(0, MyClass.new.f(1))
  end

   def test_failure
     assert_raise Rtc::TypeMismatchException do
       MyClass.new.f("doh")
     end
   end
end

