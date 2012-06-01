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

  typesig ("f11: (t) -> t")
  def f11(x)
    -1
  end

  typesig ("f12: (t) -> u")
  def f12(x)
    x
  end

  typesig ("f122: (t) -> u")
  def f122(x)
    x.to_s
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

  typesig ("t1: (t, v, Array<v>) -> Array<Array<Array<v>>>")
  def t1(x, y, z)
    [[z]]
  end

  typesig ("t2: (t, v, Array<v>) -> Array<u>")
  def t2(x, y, z)
    [[z]]
  end

  typesig ("uf: (t or v or u) -> t")
  def uf(x)
    true
  end

  typesig ("hf: (Hash<String, Fixnum>) -> Fixnum")
  def hf(x)
    0
  end

  typesig ("hf2: (Hash<t, t>) -> Fixnum")
  def hf2(x)
    0
  end

  typesig ("hf3: (Hash<t, Array<t>>) -> t")
  def hf3(h)
    h.keys[0]
  end
end

class TestTuple < Test::Unit::TestCase
  def test_simple
    assert_equal(MyClass.new.hf3({"a" => ["a"]}), "a")
    assert_equal(MyClass.new.hf({"a" => 0}), 0)
    assert_equal(MyClass.new.hf2({"a" => "b"}), 0)
    assert_equal(MyClass.new.uf(1), true)
    assert_equal("hi", MyClass.new.f5([[[["1"]]]], [[["3"]]]))
    assert_equal(1, MyClass.new.f52([[[["1"]]]], [[["3"]]]))
    assert_equal(1, MyClass.new.f52([[[[1]]]], [[[3]]]))
    assert_equal(["hi"], MyClass.new.f4([[[["1"]]]], [[["3"]]]))
    assert_equal(["hi"], MyClass.new.f3([[[["1"]]]], [[["3"]]]))
    assert_equal(1, MyClass.new.f1(1))
    assert_equal("1", MyClass.new.f1("1"))
    assert_equal(0, MyClass.new.f1(0))
    assert_equal([[[[[1]]]]], MyClass.new.f1([[[[[1]]]]]))
    assert_equal(1, MyClass.new.f12(1))
    assert_equal("1", MyClass.new.f122("1"))
    assert_equal("true", MyClass.new.f122(true))
    assert_equal([0], MyClass.new.f0(0))
    assert_equal([[0]], MyClass.new.f8([[[0]]]))
    assert_equal("doh", MyClass.new.max())
    assert_equal([[[["doh"]]]], MyClass.new.max2())
    assert_equal([[[3]]], MyClass.new.t1(1, 2, [3]))
    assert_equal([[[3]]], MyClass.new.t1("1", 2, [3]))
    assert_equal([[[3]]], MyClass.new.t2("1", 2, [3]))
  end

  def test_failure
    assert_raise Rtc::TypeMismatchException do
      MyClass.new.hf3({"a" => "a"})
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.hf({"a" => "a"})
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.hf2({"a" => 1})
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.t1(1,2,3)
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.t1(1,[2],[3])
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.t1(1,[2],[[3]])
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.f5([[["1"]]], [[["3"]]])
    end

    assert_raise Rtc::TypeMismatchException do
      MyClass.new.f11([0])
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
