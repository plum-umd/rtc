require "test/unit"
require 'rtc'

class MyClass
  rtc_annotated

  typesig ("f5: (Array<Array<Array<Array<t>>>>, Array<Array<Array<t>>>) -> t")
  def f5(x, y)
    "hi"
  end

  typesig ("f5w: (Array<Array<Array<Array<t>>>>, Array<Array<Array<t>>>) -> u")
  def f5w(x, y)
    "hi"
  end

  typesig ("f52: (Array<Array<Array<Array<t>>>>, Array<Array<Array<t>>>) -> u")
  def f52(x, y)
    1
  end

  typesig ("f4: (Array<Array<Array<Array<t>>>>, Array<Array<Array<t>>>) -> Array<t>")
  def f4(x, y)
    ["hi"]
  end

  typesig ("f3: (Array<Array<Array<Array<t>>>>, Array<Array<Array<t>>>) -> Array<String>")
  def f3(x, y)
    ["hi"]
  end

  typesig ("f2: (Array<Array<Array<Array<t>>>>, Array<Array<Array<t>>>) -> Array<Fixnum>")
  def f2(x, y)
    ["hi"]
  end

  typesig ("f1: (t) -> t")
  def f1(x)
    x
  end

  typesig ("f0: (t) -> Array<t>")
  def f0(x)
    [x]
  end

  typesig ("f7: (t) -> Array<Array<t>>")
  def f7(x)
    [x]
  end

  typesig ("f8: (Array<Array<Array<t>>>) -> Array<Array<t>>")
  def f8(x)
    x[0]
  end

  typesig ("max : () -> t")
  def max()
    "doh"
  end

  typesig ("max2 : () -> t")
  def max2()
    [[[["doh"]]]]
  end
end

class TestTuple < Test::Unit::TestCase
  def test_simple
    assert_equal("hi", MyClass.new.f5([[[["1"]]]], [[["3"]]]))
    assert_equal(1, MyClass.new.f52([[[["1"]]]], [[["3"]]]))
    assert_equal(["hi"], MyClass.new.f4([[[["1"]]]], [[["3"]]]))
    assert_equal(["hi"], MyClass.new.f3([[[["1"]]]], [[["3"]]]))
    assert_equal(1, MyClass.new.f1(1))
    assert_equal("1", MyClass.new.f1("1"))
    assert_equal([0], MyClass.new.f0(0))
    assert_equal([[0]], MyClass.new.f8([[[0]]]))
    assert_equal("doh", MyClass.new.max())
    assert_equal([[[["doh"]]]], MyClass.new.max2())
  end

  def test_failure
    assert_raise Rtc::TypeMismatchException do
      MyClass.new.f5([[["1"]]], [[["3"]]])
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.f5w([[["1"]]], [[["3"]]])
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.f5([[[[[["1"]]]]]], [[["3"]]])
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.f5([[[[["1"]]]]], [[["3"]]])
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.f2([[[[["1"]]]]], [[["3"]]])
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.f7(3)
    end
  end
end
