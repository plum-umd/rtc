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

class TestMyClass < Test::Unit::TestCase
  def test_failure
    assert_raise Rtc::TypeMismatchException do
      MyClass.new.f("1")
    end
  end
end

